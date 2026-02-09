# Suno Web UI (suno.com/create)

Browser-based generation at `suno.com/create`. Often preferable to the API for:
- **Short one-shot SFX** via the "Sounds (Beta)" mode — purpose-built for short audio
- **Vocal content** where you need precise control over what is spoken/sung via the Lyrics field
- **Interactive iteration** — listen immediately, regenerate quickly
- **When API credits are exhausted** — web UI uses separate account credits

## Modes

### Sounds Mode (Beta)

**Best for:** short instrumental SFX, foley, UI sounds, music loops.

1. Navigate to `suno.com/create`
2. Select **Sounds** tab at the top
3. Choose type:
   - **One-Shot** (default) — single sound effect
   - **Loop** — repeating music/ambient loop
4. Enter a descriptive prompt in the text field
5. Click **Create** — generates 2 variations

Use the same prompt engineering tips from sfx.md. End with "game sound effect" for short, punchy output.

### Simple Mode

**Best for:** vocal content with specific words — announcer calls, voice-overs, spoken phrases.

1. Select **Simple** tab
2. Enter your prompt describing the overall style and content
3. **The Lyrics field** appears below — this is where you write the exact words to be vocalized
4. Click **Create**

**Critical:** The Lyrics field is read verbatim. Text outside brackets IS what gets spoken/sung. See songwriter.md for metatag formatting.

### Custom Mode

**Best for:** full songs with precise control over both style and lyrics.

1. Select **Custom** tab
2. Fill in **Style** prompt — genre, BPM, mood, instrumentation, vocal character
3. Fill in **Lyrics** field — metatag-annotated lyrics (see songwriter.md)
4. Toggle **Instrumental** if no vocals needed
5. Click **Create**

## Choosing the Right Mode

| Content Type | Mode | Lyrics Field? |
|-------------|------|---------------|
| Impact SFX, UI sounds | Sounds > One-Shot | No |
| Music loops | Sounds > Loop | No |
| Announcer calls, spoken words | Simple or Custom | **Yes — critical** |
| Full songs with lyrics | Custom | **Yes — critical** |
| Instrumental music (non-loop) | Simple or Custom + Instrumental | Optional (bracket directions) |

## Downloading Generated Audio

### CDN URL Pattern

All Suno-generated audio is accessible at:

```
https://cdn1.suno.ai/{song-uuid}.mp3
```

### Extracting UUIDs from the Page

The Suno create page uses a **virtualized list** — not all items are in the DOM at once. To extract all song UUIDs:

#### Manual (small batches)

Click the "..." menu on any song → share/link reveals the UUID.

#### Browser Automation (large batches)

```javascript
// Initialize collection
window._allSongs = {};

// Collect visible songs (run after scrolling)
document.querySelectorAll('a[href*="/song/"]').forEach(l => {
  const uuid = l.getAttribute('href').split('/song/')[1];
  const title = l.textContent.trim().substring(0, 50);
  if (title.length > 1) window._allSongs[uuid] = title;
});

// Must scroll the list to capture all items due to virtualization
const scroller = document.querySelector('.clip-browser-list-scroller');
// Scroll to different positions and re-run collection:
scroller.scrollTop = 0;      // top
scroller.scrollTop = 2000;   // middle
scroller.scrollTop = 4000;   // further
scroller.scrollTop = scroller.scrollHeight;  // bottom
```

#### Bulk Download Script

```bash
#!/bin/bash
BASE="static/assets/audio/raw"
mkdir -p "$BASE"

# Download each variation
curl -s -o "$BASE/hit_1a.mp3" "https://cdn1.suno.ai/{uuid-a}.mp3" &
curl -s -o "$BASE/hit_1b.mp3" "https://cdn1.suno.ai/{uuid-b}.mp3" &
wait

# Convert to OGG (see sfx.md for trim durations)
ffmpeg -i "$BASE/hit_1a.mp3" -t 1.5 -af "afade=t=out:st=1.0:d=0.5" -c:a libvorbis -q:a 6 output.ogg
```

### Verifying Downloads

```bash
# Check all files are valid MP3s (not error pages)
file static/assets/audio/raw/*.mp3 | grep -v "Audio file"  # shows non-audio files

# Check for suspiciously small files
wc -c static/assets/audio/raw/*.mp3 | sort -n | head -5
```

## Web UI Workflow

```
1. Define sounds       →  sounds.json + sounds/prompts/*.txt
2. Open suno.com/create
3. For SFX:            →  Sounds mode > One-Shot > paste prompt > Create
4. For voice-overs:    →  Simple/Custom mode > paste Style + Lyrics > Create
5. For music loops:    →  Sounds mode > Loop > paste prompt > Create
6. Wait for generation →  ~30s for Sounds mode, ~2 min for Simple/Custom
7. Extract UUIDs       →  From page DOM: a[href*="/song/"] links
8. Download            →  curl https://cdn1.suno.ai/{uuid}.mp3
9. Convert             →  ffmpeg to OGG with trim + fade (see sfx.md)
10. Pick best variation → Listen to both a/b, keep the better one
```

## Tips for Browser Automation

- The list virtualizes items — scroll to reveal items not currently in DOM
- Each generation produces 2 variations that appear as separate list items
- The page uses the class `.clip-browser-list-scroller` for the scrollable song list
- Song links follow the pattern `a[href*="/song/"]`
- Non-game songs (from the account's history) will also appear — filter by title
- After clicking Create, wait for the generation indicator to complete before scrolling
