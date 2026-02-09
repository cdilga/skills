# Suno API Reference

Programmatic generation via the third-party Suno API at `api.sunoapi.org`.

## Authentication

### Getting an API Key

1. Go to [sunoapi.org/api-key](https://sunoapi.org/api-key)
2. Create or log into your account
3. Generate an API key

### Secure Storage

Create a `.env` file (never commit this):

```bash
# .env
SUNO_API_KEY=your_api_key_here
```

The `generate.py` script reads from `.env` automatically. Alternatively pass `--api-key` directly or export `SUNO_API_KEY` as an environment variable.

**Ensure `.env` is in your `.gitignore`.**

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/generate` | POST | Submit generation request |
| `/generate/record-info?taskId=ID` | GET | Check task status |

**Base URL:** `https://api.sunoapi.org/api/v1`

**Auth header:** `Authorization: Bearer YOUR_API_KEY`

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
| `customMode` | bool | `false` for prompt-only, `true` adds `style` + `title` fields |
| `instrumental` | bool | `true` for SFX/instrumental, `false` for vocals |
| `model` | string | `V5` recommended (fastest, best quality) |
| `callBackUrl` | string | **Required.** Any valid URL — dummy is fine if polling |

### Task Status Progression

```
PENDING → GENERATING → TEXT_SUCCESS → SUCCESS
```

- **TEXT_SUCCESS**: Metadata ready, audio still rendering (~30s in)
- **SUCCESS**: Audio URLs populated and downloadable (~2-3 min total)
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

These were discovered through testing and are critical:

1. **`callBackUrl` is required** — omitting it returns 400. Use any valid URL if not using webhooks.
2. **Python `urllib` gets 403** — Cloudflare blocks the default User-Agent. Set `User-Agent: SunoSoundGen/1.0` or similar.
3. **`/get-credits` returns 404** — The credits endpoint doesn't work despite being documented. Skip it.
4. **Full tracks, not short SFX** — The API produces full-length music (20-140s). For true short one-shots, use the web UI Sounds mode (see webui.md), or trim with ffmpeg (see sfx.md).
5. **File retention is 15 days** — Download generated audio promptly. CDN URLs expire.
6. **API credits are separate from web UI credits** — If API credits run out, fall back to the web UI with a regular Suno account.
7. **`data` may be `null`** — When the API returns an error, `result["data"]` can be `null`. Use `(result.get("data") or {}).get("taskId")` defensively.

## CLI Usage (generate.py)

### Single Sound

```bash
# Simple prompt (instrumental)
python3 generate.py --prompt "Referee whistle blast, short and sharp"

# With vocals
python3 generate.py --prompt "Excited male announcer shouting GOAL" --vocals

# With custom mode (adds style + title fields)
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

# List all defined sounds
python3 generate.py --definitions sounds.json --list
```

### Check Status & Download

```bash
# Poll all pending tasks (run ~2 min after submission)
python3 generate.py --check-status

# Status is tracked in generation_status.json
# Re-run until all tasks show SUCCESS
```

## API Workflow

```
1. Define sounds       →  sounds.json (prompts, priorities, categories, lyrics)
2. Save lyrics         →  sounds/prompts/*.txt (version-controllable artifacts)
3. Generate batch      →  python3 generate.py --definitions sounds.json --priority 1
4. Wait ~2-3 min       →  Audio rendering on Suno's servers
5. Download results    →  python3 generate.py --check-status
6. Trim to length      →  ffmpeg -i generated.mp3 -t 2 output.ogg (see sfx.md)
7. Listen & iterate    →  Re-generate with refined prompts if needed
8. Next priority       →  Repeat for --priority 2, 3, etc.
```
