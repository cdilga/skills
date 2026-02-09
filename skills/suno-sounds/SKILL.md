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
  - suno lyrics
  - songwriter
---

# Suno Sound & Music Generation

Generate short sound effects (one-shots, foley, SFX), voice-overs, and music tracks via the Suno API or the Suno web UI at suno.com/create. Supports batch generation from a definitions file, individual prompts, and polling for async results.

## When to Use This Skill

- Generating game sound effects (kicks, whistles, impacts, UI sounds)
- Creating announcer voice-overs or short vocal clips
- Producing background music loops for games or video
- Batch-generating an entire audio asset library from definitions
- Writing song lyrics with proper Suno metatag formatting
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

---

## Suno Web UI (suno.com/create)

The web UI at `suno.com/create` is often preferable to the API for:
- **Short one-shot SFX** via the "Sounds (Beta)" mode — generates purpose-built short audio
- **Vocal content** where you need precise control over what is spoken/sung via the Lyrics field
- **Interactive iteration** — listen to results immediately, regenerate quickly
- **When API credits are exhausted** — web UI uses separate account credits

### Web UI Modes

#### Sounds Mode (Beta)

Best for: short instrumental SFX, foley, UI sounds.

1. Navigate to `suno.com/create`
2. Select **Sounds** mode (tab at top)
3. Choose **One-Shot** (default) or **Loop** type
4. Enter a descriptive prompt (same prompt engineering as API)
5. Click **Create** — generates 2 variations

#### Simple Mode

Best for: vocal content, announcer calls, voice-overs with specific words.

1. Navigate to `suno.com/create`
2. Select **Simple** mode
3. Enter your prompt describing the style and content
4. The **Lyrics** field is where you write what will be vocalized — this is critical for voice content
5. Click **Create**

#### Custom Mode

Best for: full songs with precise style and lyrics control.

1. Select **Custom** mode
2. Fill in **Style** prompt (genre, BPM, mood, instrumentation)
3. Fill in **Lyrics** field with metatag-annotated lyrics
4. Click **Create**

### CDN Download Pattern

All Suno-generated audio is available at:
```
https://cdn1.suno.ai/{song-uuid}.mp3
```

Song UUIDs can be extracted from the page DOM via `a[href*="/song/"]` links. For browser automation, scroll through the virtualized list to capture all UUIDs.

---

## Lyrics & Metatag System

**This is the most important section for vocal content.** The Lyrics field in Suno's UI (and the `prompt` field in Simple/Custom modes) is read verbatim. Any bracketed notes like `[saxophone solo]` are converted to appropriate instrumentation. CAPITALISED TEXT is sung louder/more intensely. The words you write ARE the words that will be performed.

### Structural Metatags

Use square brackets for song structure and performance direction:

| Metatag | Purpose |
|---------|---------|
| `[Intro]` | Opening section |
| `[Verse]`, `[Verse 1]` | Main lyrical sections |
| `[Pre-Chorus]` | Build-up before chorus |
| `[Chorus]` | Main hook/refrain |
| `[Bridge]` | Contrasting section |
| `[Hook]` | Catchy repeated phrase |
| `[Break]` | Instrumental pause |
| `[Interlude]` | Short musical passage |
| `[Outro]`, `[Ending]` | Closing |
| `[Fade Out]`, `[Fade to End]` | Gradual ending |

### Style/Mood Metatags

Place within or before sections to control delivery:

| Metatag | Effect |
|---------|--------|
| `[Energy: High]` | Increases intensity |
| `[Mood: Joyful]`, `[Mood: Powerful]` | Sets emotional tone |
| `[Instrument: Guitar Solo]` | Triggers specific instrumentation |
| `[Vocal Style: Whisper]`, `[Vocal Style: Rap]` | Changes vocal delivery |
| `[Vocal Effect: Reverb]`, `[Vocal Effect: Delay]` | Adds vocal processing |
| `[Dynamic: Crescendo]`, `[Build Up]` | Controls dynamics |

### Key Formatting Rules

1. **Keep metatags simple** — 1-3 words maximum
2. **Place important control tags early** — front-load key instructions
3. **CAPITALISED LYRICS** are sung louder/more intensely
4. **Text outside brackets is performed literally** — write exactly what you want said/sung
5. **Bracketed text is interpreted as direction** — `[saxophone solo]` becomes a saxophone solo
6. **Maximum 2-3 metatags per section** — don't overload
7. **Results can be unpredictable** — this is guidance, not guaranteed control

### Voice-Over / Announcer Lyrics

For short vocal clips (announcer calls, game mode names, etc.), the lyrics field should contain:

1. A character/style direction in brackets
2. Optional mood/energy tags
3. The exact words to be spoken, in CAPS for emphasis

**Example: Sports announcer goal call**
```
[Excited Sports Announcer]
[Energy: High]
GOAL!
```

**Example: Victory announcement**
```
[Victory Announcer]
[Energy: High]
[Mood: Celebratory]
RED WINS!
```

**Example: Game mode announcement**
```
[Dramatic Announcer]
[Vocal Effect: Reverb]
[Mood: Mysterious]
ENDLESS MODE
```

### Instrumental Lyrics (Bracket-Only)

For instrumental tracks, use brackets throughout to describe what should happen musically:

```
[Intro - Bright Chiptune Arpeggio]

[Main Theme]
[Energy: High]
[8-bit Lead Melody, Bouncy Bassline, Fast Drums]

[B Section]
[Mood: Playful]
[Chiptune Countermelody, Energetic Percussion]

[Main Theme Reprise]
[Energy: High]
[Full 8-bit Ensemble, Maximum Energy]

[Loop Point - Seamless Return to Intro]
```

### Full Song Example

```
[Intro]
[Mood: Uplifting]

[Verse 1]
Walking down the street in the morning light
Everything feels new, everything feels right

[Pre-Chorus]
Can you feel it building?

[Chorus]
[Energy: High]
WE RISE TOGETHER, LOUDER THAN BEFORE
Every moment matters, every single day
WE'RE FINDING OUR WAY

[Bridge]
[Vocal Effect: Delay]
And we'll keep on rising (keep on rising)

[Outro]
[Fade to End]
Finding our way
```

### Style Prompt Structure (Custom Mode)

When using Custom mode, the Style field should include:

- **Genre/Style**: "Indie Pop", "Orchestral Rock", "Lo-fi Hip Hop"
- **BPM**: Tempo — "103 BPM", "140 BPM"
- **Key**: Musical key — "B Minor", "C Major"
- **Mood**: "Uplifting", "Melancholy", "Energetic"
- **Instrumentation**: "Warm Rhodes, Electric Guitar, 808s, Strings"
- **Vocal characteristics**: "Male vocals, Baritone" or "Female, Soprano, Powerful"

**Example style prompts:**
```
Indie Pop, Dreamy Electronic, 103 BPM, Uplifting, Nostalgic, Synths, Emotive Male Vocals

Sports Announcer, Male Voice, Energetic, Excited, Celebratory, Single Word

Instrumental, Cinematic Orchestral, 90 BPM, Epic, Dramatic, Full Orchestra
```

---

## Saving Lyrics Artifacts

When generating vocal sounds or music, **always save the lyrics/prompt artifacts locally** so they can be version-controlled and regenerated later.

### Recommended Directory Structure

```
sounds/
  prompts/
    goal_a.txt        # Lyrics for goal announcer call A
    winsred.txt       # Lyrics for "Red Wins" voice-over
    background_music.txt  # Instrumental directions for background music
  sounds.json         # Batch definitions with prompts
```

### Lyrics File Format

Each `.txt` file contains the Style prompt on the first line, a `---` separator, then the Lyrics content:

```
Style: Sports Announcer, Male Voice, Celebratory, Excited, Victory Announcement
---
[Victory Announcer]
[Energy: High]
[Mood: Celebratory]
RED WINS!
```

For instrumental content:

```
Style: Instrumental, Upbeat Retro Chiptune, 140 BPM, C Major, Energetic 8-bit Arcade
Type: Loop
---
[Intro - Bright Chiptune Arpeggio]

[Main Theme]
[Energy: High]
[8-bit Lead Melody, Bouncy Bassline]
```

---

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
2. **Python `urllib` gets 403** — Cloudflare blocks the default User-Agent. Set `User-Agent: SunoSoundGen/1.0` or similar.
3. **`/get-credits` returns 404** — The credits endpoint doesn't work despite being documented. Skip it.
4. **Full tracks, not short SFX** — The `/generate` endpoint produces full-length music (20-140s). For true short one-shots, use Suno's web UI "Sounds (Beta)" mode at `suno.com/create`, or trim API results with ffmpeg.
5. **File retention is 15 days** — Download generated audio promptly. CDN URLs expire.
6. **API credits are separate from web UI credits** — If API credits run out, you can fall back to the web UI with a regular Suno account.
7. **`data` may be `null`** — When the API returns an error, `result["data"]` can be `null`. Use `(result.get("data") or {}).get("taskId")` defensively.

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
      "id": "goal_a",
      "filename": "goal_a.ogg",
      "priority": 2,
      "type": "one-shot",
      "prompt": "Excited male sports announcer shouting GOAL with great enthusiasm, energetic celebration voice, single word",
      "lyrics": "[Excited Sports Announcer]\n[Energy: High]\nGOAL!",
      "category": "voice"
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
| `prompt` | yes | Natural language description sent to Suno (used as Style in web UI) |
| `priority` | yes | 1 = core, 2 = polish, 3 = extras — for phased generation |
| `type` | yes | `one-shot` or `loop` |
| `category` | yes | Grouping key (e.g. `sfx`, `voice`, `music`) |
| `lyrics` | no | Metatag-annotated lyrics for vocal content (used in Lyrics field in web UI) |
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

# Voice-overs (prompt describes style; lyrics field has the words)
"Excited male announcer, sports commentator celebration voice, energetic and dramatic, single word"

# Ambient/foley
"Cartoon character jump launch, quick whoosh upward with slight springy bounce, short comedic hop sound, game sound effect"
```

### Tips

- **End with "game sound effect"** — anchors Suno to short, punchy output
- **Specify duration feel** — "short", "single blast", "quick", "brief"
- **Name the genre** — "retro", "8-bit", "chiptune" for game music
- **Describe the texture** — "punchy", "crisp", "warm", "bright"
- **For voice-overs** — the prompt describes the voice character; the **lyrics field** contains the actual words
- **For variations** — generate the same concept multiple times with slight prompt changes
- **CAPITALISE key words** in lyrics — they'll be delivered with more intensity

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
python3 generate.py --definitions sounds.json --category sfx

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

### API Workflow

```
1. Define sounds       →  sounds.json (prompts, priorities, categories, lyrics)
2. Save lyrics         →  sounds/prompts/*.txt (version-controllable artifacts)
3. Generate batch      →  python3 generate.py --definitions sounds.json --priority 1
4. Wait ~2-3 min       →  Audio rendering on Suno's servers
5. Download results    →  python3 generate.py --check-status
6. Trim to length      →  ffmpeg -i generated.mp3 -t 2 output.ogg
7. Listen & iterate    →  Re-generate with refined prompts if needed
8. Next priority       →  Repeat for --priority 2, 3, etc.
```

### Web UI Workflow

```
1. Define sounds       →  sounds.json + sounds/prompts/*.txt
2. Open suno.com/create
3. For SFX:            →  Sounds mode > One-Shot > paste prompt > Create
4. For voice-overs:    →  Simple/Custom mode > paste Style + Lyrics > Create
5. For music loops:    →  Sounds mode > Loop > paste prompt > Create
6. Extract UUIDs       →  From page DOM: a[href*="/song/"] links
7. Download            →  curl https://cdn1.suno.ai/{uuid}.mp3
8. Convert             →  ffmpeg to OGG with trim + fade
```

## Decision Tree

```
What do you need?
├── Short SFX (< 3s): impact, click, whistle, beep
│   ├── Use Suno web UI "Sounds" mode (best for short one-shots)
│   └── Or use API + trim with ffmpeg (automated, batch-friendly)
├── Voice-over (1-5s): announcer calls, mode names
│   ├── Use web UI Simple/Custom mode with Lyrics field (precise word control)
│   └── Or use API with instrumental=false (less control over exact words)
├── Music loop (30-120s): background, menu, gameplay
│   ├── Use web UI Sounds mode > Loop type
│   └── Or use API with type=loop prompt
└── Full song with lyrics (2-4 min): credits, trailer
    └── Use web UI Custom mode with full Style + Lyrics
```
