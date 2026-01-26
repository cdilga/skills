---
name: looping-video
description: Create seamlessly looping, stabilized video using ffmpeg and the doubled video technique
triggers:
  - looping video
  - stabilize video
  - seamless loop
  - vidstab
  - video stabilization
  - tripod stable
---

# Looping Video Stabilization

Create seamlessly looping, tripod-stable video from handheld footage using ffmpeg and vidstab.

## When to Use This Skill

Use this skill when:
- Creating background videos that need seamless loops
- Stabilizing handheld footage for web use
- Making hero section videos for websites
- Processing footage with visible camera shake
- Creating cinemagraphs or looping content

## Quick Start

For a 5-second looping video:

```bash
# 1. Trim source
ffmpeg -y -i source.mp4 -ss 0 -t 5 -c:v libx264 -crf 16 /tmp/trimmed.mp4

# 2. Double the video
cat > /tmp/list.txt << 'EOF'
file '/tmp/trimmed.mp4'
file '/tmp/trimmed.mp4'
EOF
ffmpeg -y -f concat -safe 0 -i /tmp/list.txt -c:v libx264 -crf 16 /tmp/doubled.mp4

# 3. Stabilize (two-pass)
ffmpeg -y -i /tmp/doubled.mp4 -vf "vidstabdetect=shakiness=8:accuracy=15:result=/tmp/transforms.trf" -f null -
ffmpeg -y -i /tmp/doubled.mp4 -vf "vidstabtransform=input=/tmp/transforms.trf:smoothing=0:optzoom=0:zoom=0:interpol=bicubic:crop=keep" -c:v libx264 -crf 16 /tmp/stabilized.mp4

# 4. Extract middle (seamless loop)
ffmpeg -y -i /tmp/stabilized.mp4 -ss 2.5 -t 5 -c:v libx264 -crf 18 output.mp4
```

## The Core Technique: Doubled Video

### Why Standard Stabilization Fails for Loops

Standard stabilization fails at loop boundaries because algorithms have no context at video edges, causing visible jumps.

### The Solution

**Duplicate the video before stabilization, then extract the middle:**

```
Original:     [====A====]
Doubled:      [====A====][====A====]
After stab:   [====A'===][====A'===]
Extract:          [====MIDDLE====]
```

The original loop point is now in the **middle** where stabilization has full context on both sides.

## Prerequisites

Install ffmpeg with vidstab:

```bash
# macOS (Homebrew)
brew tap homebrew-ffmpeg/ffmpeg
brew install homebrew-ffmpeg/ffmpeg/ffmpeg --with-libvidstab

# Verify
ffmpeg -filters 2>&1 | grep vidstab
# Should show: vidstabdetect, vidstabtransform
```

## Complete Pipeline

### Step 1: Find Stable Segment (Optional)

If source has varying stability, find the most stable segment:

```python
import cv2
import numpy as np

cap = cv2.VideoCapture('source.mp4')
fps = cap.get(cv2.CAP_PROP_FPS)
scores = []
prev_frame = None

while True:
    ret, frame = cap.read()
    if not ret:
        break
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    gray_small = cv2.resize(gray, (320, 180))

    if prev_frame is not None:
        diff = np.mean(np.abs(gray_small.astype(float) - prev_frame.astype(float)))
        scores.append(diff)
    prev_frame = gray_small

cap.release()

# Find most stable 5-second window
window = int(5 * fps)
best_start = min(range(len(scores) - window),
                 key=lambda i: sum(scores[i:i+window]))
print(f"Most stable segment: {best_start/fps:.1f}s - {(best_start+window)/fps:.1f}s")
```

### Step 2: Trim Source

```bash
ffmpeg -y -i source.mp4 -ss 4.4 -t 5 \
  -c:v libx264 -crf 16 -preset slow \
  /tmp/trimmed.mp4
```

### Step 3: Create Doubled Video

```bash
cat > /tmp/double_list.txt << 'EOF'
file '/tmp/trimmed.mp4'
file '/tmp/trimmed.mp4'
EOF

ffmpeg -y -f concat -safe 0 -i /tmp/double_list.txt \
  -c:v libx264 -crf 16 -preset slow \
  /tmp/doubled.mp4
```

### Step 4: Vidstab Pass 1 - Detect Motion

```bash
ffmpeg -y -i /tmp/doubled.mp4 \
  -vf "vidstabdetect=shakiness=8:accuracy=15:result=/tmp/transforms.trf" \
  -f null -
```

**Parameters:**
- `shakiness=8`: Expected shake level (1-10, higher = more aggressive)
- `accuracy=15`: Analysis accuracy (1-15, higher = better but slower)

### Step 5: Vidstab Pass 2 - Apply Stabilization

```bash
ffmpeg -y -i /tmp/doubled.mp4 \
  -vf "vidstabtransform=input=/tmp/transforms.trf:smoothing=0:optzoom=0:zoom=0:interpol=bicubic:crop=keep" \
  -c:v libx264 -crf 16 -preset slow \
  /tmp/stabilized.mp4
```

**Critical settings:**

| Setting | Value | Why |
|---------|-------|-----|
| `smoothing=0` | 0 | Locks frame instantly; non-zero causes drift |
| `optzoom=0` | 0 | Disables dynamic zoom; prevents in/out movement |
| `zoom=0` | 0 | No fixed zoom (or 2-5 if edges need cropping) |
| `interpol=bicubic` | bicubic | Better quality than default bilinear |
| `crop=keep` | keep | Mirrors edges instead of black bars |

### Step 6: Extract Middle Portion

```bash
# For 5-second source (doubled = 10s), extract middle 5s
ffmpeg -y -i /tmp/stabilized.mp4 \
  -ss 2.5 -t 5 \
  -c:v libx264 -crf 18 -preset slow \
  output.mp4
```

### Step 7: Create WebM (Optional)

```bash
ffmpeg -y -i output.mp4 \
  -c:v libvpx-vp9 -crf 24 -b:v 0 \
  output.webm
```

## Troubleshooting

### Black Bars at Edges

**Cause:** Stabilization shifts frames, leaving borders.

**Fix:** Use `crop=keep` or add `zoom=5` (5% crop).

### Dynamic Zoom (In/Out Movement)

**Cause:** `optzoom=2` adjusts zoom per-frame.

**Fix:** Use `optzoom=0` with fixed or no zoom.

### Blocky Artifacts

**Cause:** Frame interpolation when shifting.

**Fix:** Use `interpol=bicubic` and `crop=keep`.

### Stabilization Drift

**Cause:** Non-zero smoothing allows gradual shift.

**Fix:** Use `smoothing=0` to lock each frame.

### Visible Loop Jump

**Cause:** No context at video boundaries.

**Fix:** Use the doubled video technique (this skill's core method).

### Dust/Particles Confusing Tracking

**Cause:** Small moving elements detected as camera motion.

**Fix:** Higher `shakiness` value may help. The doubled technique minimizes impact at loop point.

## Quality Reference

### CRF (Constant Rate Factor)

Lower = better quality, larger file:
- `crf 16-18`: High quality (source/intermediate)
- `crf 20-23`: Good quality, reasonable size
- `crf 24-28`: Acceptable, smaller files

### Presets

Slower = better compression:
- `preset slow`: Good balance for final output
- `preset medium`: Faster, slightly larger
- `preset veryslow`: Best compression, very slow

## Full Pipeline Script

```bash
#!/bin/bash
set -e

INPUT="$1"
OUTPUT="${2:-stabilized.mp4}"
DURATION="${3:-5}"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

echo "Step 1: Trimming to ${DURATION}s..."
ffmpeg -y -i "$INPUT" -t "$DURATION" \
  -c:v libx264 -crf 16 -preset slow \
  "$TMP/trimmed.mp4"

echo "Step 2: Creating doubled video..."
cat > "$TMP/list.txt" << EOF
file '$TMP/trimmed.mp4'
file '$TMP/trimmed.mp4'
EOF
ffmpeg -y -f concat -safe 0 -i "$TMP/list.txt" \
  -c:v libx264 -crf 16 "$TMP/doubled.mp4"

echo "Step 3: Vidstab pass 1 - detecting motion..."
ffmpeg -y -i "$TMP/doubled.mp4" \
  -vf "vidstabdetect=shakiness=8:accuracy=15:result=$TMP/transforms.trf" \
  -f null -

echo "Step 4: Vidstab pass 2 - applying stabilization..."
ffmpeg -y -i "$TMP/doubled.mp4" \
  -vf "vidstabtransform=input=$TMP/transforms.trf:smoothing=0:optzoom=0:zoom=0:interpol=bicubic:crop=keep" \
  -c:v libx264 -crf 16 -preset slow \
  "$TMP/stabilized.mp4"

echo "Step 5: Extracting middle portion..."
HALF=$(echo "$DURATION / 2" | bc -l)
ffmpeg -y -i "$TMP/stabilized.mp4" \
  -ss "$HALF" -t "$DURATION" \
  -c:v libx264 -crf 18 -preset slow \
  "$OUTPUT"

echo "Done: $OUTPUT"
```

**Usage:**
```bash
./stabilize-loop.sh input.mp4 output.mp4 5
```

## Alternative: Light Deshake

For minor shake, single-pass deshake may suffice:

```bash
ffmpeg -y -i input.mp4 \
  -vf "deshake=rx=32:ry=32:edge=1" \
  -c:v libx264 -crf 18 \
  output.mp4
```

- `rx/ry`: Max shift in pixels (32 is moderate)
- `edge=1`: Mirror edges (avoids black bars)

**Tradeoff:** Less powerful, but fewer artifacts.

## Decision Tree

```
Need seamless loop?
├── Yes → Use doubled video technique
│   └── Heavy shake? → shakiness=8-10, accuracy=15
│   └── Light shake? → shakiness=4-6, accuracy=10
└── No → Standard vidstab or deshake
    └── Minor shake → deshake filter
    └── Significant shake → vidstab two-pass
```
