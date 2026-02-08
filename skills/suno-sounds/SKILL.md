---
name: suno-sounds
description: Generate sound effects, foley, and music using the Suno API — batch or interactive
triggers:
  - suno
  - sound effects
  - generate sounds
  - generate music
  - sfx generation
  - foley
  - game audio
  - suno api
---

# Suno Sound & Music Generation

Generate short sound effects (one-shots, foley, SFX) and music tracks via the Suno API. Supports batch generation from a definitions file, individual prompts, and polling for async results.

## When to Use This Skill

- Generating game sound effects (kicks, whistles, impacts, UI sounds)
- Creating announcer voice-overs or short vocal clips
- Producing background music loops for games or video
- Batch-generating an entire audio asset library from definitions
- Any task requiring AI-generated audio via Suno

## Quick Start

```bash
# 1. Set up auth (one-time)
echo "SUNO_API_KEY=your_key_here" > .env

# 2. Generate a single sound
python3 generate.py --prompt "Short referee whistle blast, sports game SFX"

# 3. Batch generate from definitions file
python3 generate.py --definitions sounds.json --priority 1

# 4. Check status and download results
python3 generate.py --check-status
```

## Authentication

### Getting an API Key

1. Go to [sunoapi.org/api-key](https://sunoapi.org/api-key)
2. Create or log into your account
3. Generate an API key

### Secure Storage

Create a `.env` file in your working directory (never commit this):

```bash
# .env
SUNO_API_KEY=your_api_key_here
```

The script reads from `.env` automatically. Alternatively pass `--api-key` directly or export the environment variable.

**Ensure `.env` is in your `.gitignore`.** The `generate.py` script will warn if it detects `.env` is not gitignored.

## API Reference

### Base URL

```
https://api.sunoapi.org/api/v1
```

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/generate` | POST | Submit generation request |
| `/generate/record-info?taskId=ID` | GET | Check task status |

### Authentication Header

```
Authorization: Bearer YOUR_API_KEY
```

### Generate Request

```json
{
  "prompt": "Description of the sound or music you want",
  "customMode": false,
  "instrumental": true,
  "model": "V5",
  "callBackUrl": "https://example.com/callback"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `prompt` | string | Natural language description (max 3000 chars) |
| `customMode` | bool | `false` for prompt-only, `true` adds `style` + `title` |
| `instrumental` | bool | `true` for SFX/instrumental, `false` for vocals |
| `model` | string | `V5` recommended (fastest, best quality) |
| `callBackUrl` | string | **Required.** Any valid URL — used for webhook (can be dummy if polling) |

### Task Status Progression

```
PENDING → GENERATING → TEXT_SUCCESS → SUCCESS
```

- **TEXT_SUCCESS**: Metadata ready, audio still rendering (~30s in)
- **SUCCESS**: Audio URLs populated and downloadable (~2-3 min)
- **FAILED**: Generation unsuccessful — re-submit

### Response Structure (SUCCESS)

```json
{
  "data": {
    "taskId": "abc123",
    "status": "SUCCESS",
    "response": {
      "sunoData": [
        {
          "id": "uuid",
          "sourceAudioUrl": "https://cdn1.suno.ai/uuid.mp3",
          "audioUrl": "https://tempfile.../uuid.mp3",
          "title": "Generated Title",
          "duration": 20.92
        }
      ]
    }
  }
}
```

Each request generates **2 variations**. Pick the best one.

## Known API Quirks

These were discovered through testing and are critical to know:

1. **`callBackUrl` is required** — omitting it returns 400. Use any valid URL if not using webhooks.
2. **Python `urllib` gets 403** — Cloudflare blocks the default User-Agent. Set `User-Agent: PPaaS-SoundGen/1.0` or similar.
3. **`/get-credits` returns 404** — The credits endpoint doesn't work despite being documented. Skip it.
4. **Full tracks, not short SFX** — The `/generate` endpoint produces full-length music (20-140s). For true short one-shots, use Suno's web UI "Sounds (Beta)" mode at `suno.com/create`, or trim API results with ffmpeg.
5. **File retention is 15 days** — Download generated audio promptly. CDN URLs expire.

## Sound Definitions File

For batch generation, define sounds in a JSON file:

```json
{
  "sounds": [
    {
      "id": "whistle",
      "filename": "whistle.wav",
      "priority": 1,
      "type": "one-shot",
      "prompt": "Sharp referee whistle blow, single short blast, sports game, clean and piercing, game sound effect",
      "category": "game_events"
    },
    {
      "id": "background_music",
      "filename": "background_music.ogg",
      "priority": 3,
      "type": "loop",
      "prompt": "Upbeat retro chiptune soccer game music, energetic 8-bit arcade style, loopable",
      "bpm": 130,
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
| `priority` | yes | 1 = core, 2 = polish, 3 = extras — for phased generation |
| `type` | yes | `one-shot` or `loop` |
| `category` | yes | Grouping key (e.g. `player_actions`, `music`, `menu_ui`) |
| `filename` | no | Desired output filename |
| `bpm` | no | Beats per minute (for music/loops) |
| `key` | no | Musical key (for music/loops) |

## Prompt Engineering for Sound Effects

### Good SFX Prompts

Effective prompts are specific about the sound character, duration feel, and context:

```
# Impact sounds
"Solid soccer ball kick, medium impact leather thump, satisfying boot-on-ball contact, punchy sports foley, game sound effect"

# UI sounds
"Short bright UI click sound, menu navigation blip upward pitch, clean digital boop, minimal and satisfying, game UI sound effect"

# Voice-overs
"Excited male announcer shouting GOAL with enthusiasm, sports commentator celebration voice, energetic and dramatic, single word, game sound effect"

# Ambient/foley
"Cartoon character jump launch, quick whoosh upward with slight springy bounce, short comedic hop sound, game sound effect"
```

### Tips

- **End with "game sound effect"** — anchors Suno to short, punchy output
- **Specify duration feel** — "short", "single blast", "quick", "brief"
- **Name the genre** — "retro", "8-bit", "chiptune" for game music
- **Describe the texture** — "punchy", "crisp", "warm", "bright"
- **For voice-overs** — specify tone, emotion, and the exact words to say
- **For variations** — generate the same concept multiple times with slight prompt changes

## Trimming API Output to SFX Length

The API generates full tracks. Extract the usable SFX portion:

```bash
# Trim to first 2 seconds (most SFX start immediately)
ffmpeg -i generated.mp3 -t 2 -c:a libvorbis -q:a 6 output.ogg

# Trim with fade-out
ffmpeg -i generated.mp3 -t 1.5 -af "afade=t=out:st=1.0:d=0.5" -c:a libvorbis -q:a 6 output.ogg

# Detect silence and auto-trim (keeps only the sound)
ffmpeg -i generated.mp3 -af "silenceremove=start_periods=1:start_threshold=-40dB:stop_periods=1:stop_threshold=-40dB" -c:a libvorbis -q:a 6 output.ogg

# Convert to OGG Vorbis for web (small + good quality)
ffmpeg -i generated.mp3 -c:a libvorbis -q:a 5 output.ogg

# Convert to WAV (uncompressed, for game engines that prefer it)
ffmpeg -i generated.mp3 -t 2 output.wav
```

## CLI Usage

### Single Sound

```bash
# Simple prompt
python3 generate.py --prompt "Referee whistle blast, short and sharp"

# With custom mode
python3 generate.py --prompt "Whistle" --style "sports foley, one-shot SFX" --title "ref_whistle"
```

### Batch from Definitions

```bash
# Generate everything
python3 generate.py --definitions sounds.json

# Only priority 1 (core sounds)
python3 generate.py --definitions sounds.json --priority 1

# Only a specific category
python3 generate.py --definitions sounds.json --category game_events

# Only a specific sound
python3 generate.py --definitions sounds.json --sound whistle

# Dry run (preview without API calls)
python3 generate.py --definitions sounds.json --dry-run
```

### Check Status & Download

```bash
# Poll all pending tasks
python3 generate.py --check-status

# Status is tracked in generation_status.json
# Re-run --check-status until all tasks show SUCCESS
```

### List Definitions

```bash
python3 generate.py --definitions sounds.json --list
```

## Workflow

```
1. Define sounds       →  sounds.json (prompts, priorities, categories)
2. Generate batch      →  python3 generate.py --definitions sounds.json --priority 1
3. Wait ~2-3 min       →  Audio rendering on Suno's servers
4. Download results    →  python3 generate.py --check-status
5. Trim to length      →  ffmpeg -i generated.mp3 -t 2 output.ogg
6. Listen & iterate    →  Re-generate with refined prompts if needed
7. Next priority       →  python3 generate.py --definitions sounds.json --priority 2
```

## Decision Tree

```
What do you need?
├── Short SFX (< 3s): impact, click, whistle, beep
│   ├── Use API + trim with ffmpeg (automated, batch-friendly)
│   └── Or use Suno web UI "Sounds (Beta)" mode (manual, purpose-built)
├── Voice-over (1-5s): announcer calls, mode names
│   └── Use API with instrumental=false, trim result
├── Music loop (30-120s): background, menu, gameplay
│   └── Use API with type=loop prompt, no trimming needed
└── Long music (2-4 min): trailer, credits
    └── Use API, model=V5, full track output
```
