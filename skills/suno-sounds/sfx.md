# SFX, Foley & Instrumental Music

Prompt engineering, trimming, and project conventions for generating non-vocal audio.

## Prompt Engineering

### Good SFX Prompts

Effective prompts are specific about sound character, duration feel, and context:

```
# Impact sounds
"Solid soccer ball kick, medium impact leather thump, satisfying boot-on-ball contact, punchy sports foley, game sound effect"

# UI sounds
"Short bright UI click sound, menu navigation blip upward pitch, clean digital boop, minimal and satisfying, game UI sound effect"

# Ambient/foley
"Cartoon character jump launch, quick whoosh upward with slight springy bounce, short comedic hop sound, game sound effect"

# Music loops
"Upbeat retro chiptune soccer game music, energetic 8-bit arcade style, fun and bouncy melody, fast tempo, loopable background track"
```

### Tips

- **End with "game sound effect"** — anchors Suno to short, punchy output
- **Specify duration feel** — "short", "single blast", "quick", "brief"
- **Name the genre** — "retro", "8-bit", "chiptune" for game music
- **Describe the texture** — "punchy", "crisp", "warm", "bright"
- **For variations** — generate the same concept multiple times with slight prompt changes
- **For music loops** — include "loopable" in the prompt

## Trimming with ffmpeg

The API generates full tracks (20-140s). Extract the usable SFX portion:

```bash
# Trim to first 2 seconds (most SFX start immediately)
ffmpeg -i generated.mp3 -t 2 -c:a libvorbis -q:a 6 output.ogg

# Trim with fade-out (recommended for game SFX)
ffmpeg -i generated.mp3 -t 1.5 -af "afade=t=out:st=1.0:d=0.5" -c:a libvorbis -q:a 6 output.ogg

# Detect silence and auto-trim (keeps only the sound)
ffmpeg -i generated.mp3 -af "silenceremove=start_periods=1:start_threshold=-40dB:stop_periods=1:stop_threshold=-40dB" -c:a libvorbis -q:a 6 output.ogg

# Convert to OGG Vorbis for web (small + good quality)
ffmpeg -i generated.mp3 -c:a libvorbis -q:a 5 output.ogg

# Convert to WAV (uncompressed, for game engines that prefer it)
ffmpeg -i generated.mp3 -t 2 output.wav
```

### Recommended Trim Durations by Type

| Sound Type | Duration | Fade |
|-----------|----------|------|
| UI click/blip | 0.5-1.0s | 0.3s fadeout |
| Impact/hit | 1.0-1.5s | 0.5s fadeout |
| Jump/hop/woosh | 1.0-1.5s | 0.5s fadeout |
| Whistle/buzzer | 1.5-2.0s | 0.5s fadeout |
| Fanfare/jingle | 3.0-4.0s | 1.0s fadeout |
| Voice-over | 3.0-5.0s | 1.0s fadeout |
| Music loop | Full length | No trim |

## Sound Definitions File

For batch generation, define sounds in a JSON file:

```json
{
  "sounds": [
    {
      "id": "whistle",
      "filename": "whistle.ogg",
      "priority": 1,
      "type": "one-shot",
      "prompt": "Sharp referee whistle blow, single short blast, sports game, clean and piercing, game sound effect",
      "category": "sfx"
    },
    {
      "id": "background_music",
      "filename": "background.ogg",
      "priority": 6,
      "type": "loop",
      "prompt": "Upbeat retro chiptune soccer game music, energetic 8-bit arcade style, loopable",
      "bpm": 140,
      "key": "C",
      "category": "music"
    }
  ]
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Unique identifier, used for filenames and status tracking |
| `prompt` | yes | Natural language description sent to Suno |
| `priority` | yes | 1 = core, 2 = important, 3+ = polish — for phased generation |
| `type` | yes | `one-shot` or `loop` |
| `category` | yes | Grouping key (e.g. `sfx`, `voice`, `music`) |
| `lyrics` | no | Metatag-annotated lyrics — see songwriter.md for voice content |
| `filename` | no | Desired output filename |
| `bpm` | no | Beats per minute (for music/loops) |
| `key` | no | Musical key (for music/loops) |

## Saving Artifacts

Always save prompts and generation metadata for version control:

```
sounds/
  prompts/
    goal_a.txt          # Style + Lyrics for voice content
    background_music.txt  # Instrumental directions for music
  sounds.json           # Batch definitions with all prompts
```

### Lyrics File Format

Each `.txt` file: Style on first line, `---` separator, then Lyrics content:

```
Style: Instrumental, Upbeat Retro Chiptune, 140 BPM, C Major
Type: Loop
---
[Intro - Bright Chiptune Arpeggio]

[Main Theme]
[Energy: High]
[8-bit Lead Melody, Bouncy Bassline]

[Loop Point - Seamless Return to Intro]
```

For instrumental content, all text goes in brackets (performance directions). For vocal content, see songwriter.md.
