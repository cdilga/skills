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

Generate short sound effects (one-shots, foley, SFX), voice-overs, and music tracks via the Suno API or the Suno web UI at suno.com/create.

## Decide What to Read

Use this decision tree, then read **only the files you need**:

```
What are you generating?
│
├── Short SFX / foley (impacts, clicks, whistles, UI sounds, ambient)
│   │   → Read sfx.md (prompt tips, trimming, definitions)
│   │
│   ├── Automated / batch?  → Also read api.md (endpoints, generate.py)
│   └── Manual / interactive? → Also read webui.md (Sounds mode, CDN download)
│
├── Voice-over / announcer / spoken words
│   │   → Read songwriter.md (lyrics field is CRITICAL for vocal content)
│   │
│   ├── Via API?  → Also read api.md
│   └── Via web UI? → Also read webui.md (Simple/Custom mode)
│
├── Song with lyrics (full musical composition)
│   │   → Read songwriter.md (metatags, structure, style prompts)
│   │
│   ├── Via API?  → Also read api.md
│   └── Via web UI? → Also read webui.md (Custom mode)
│
└── Instrumental music loop (background, menu)
    │   → Read sfx.md (for definitions and prompt tips)
    │
    ├── Via API?  → Also read api.md
    └── Via web UI? → Also read webui.md (Sounds mode > Loop)
```

**Rule of thumb:** If the output has **words that must be spoken/sung**, you need `songwriter.md`. If it's purely instrumental, you need `sfx.md`. Then pick `api.md` or `webui.md` based on the delivery method.

## Reference Files

| File | When to Read | Contents |
|------|-------------|----------|
| [sfx.md](sfx.md) | SFX, foley, instrumental music | Prompt engineering, trimming with ffmpeg, sound definitions JSON format, artifact conventions |
| [songwriter.md](songwriter.md) | Voice-overs, announcer calls, songs with lyrics | Lyrics metatag system, structural tags, style prompts, vocal formatting, full song examples |
| [api.md](api.md) | Using the Suno API programmatically | Auth, endpoints, request/response, quirks, `generate.py` CLI, polling workflow |
| [webui.md](webui.md) | Using suno.com/create in browser | Sounds/Simple/Custom modes, CDN download pattern, UUID extraction, browser automation |

## Quick Start

**API path:**
```bash
echo "SUNO_API_KEY=your_key_here" > .env
python3 generate.py --prompt "Short referee whistle blast, sports game SFX"
python3 generate.py --check-status  # after ~2 min
```

**Web UI path:**
1. Open `suno.com/create`
2. Choose mode: Sounds (SFX), Simple (voice), or Custom (songs)
3. Enter prompt + lyrics (for vocal content)
4. Download via `https://cdn1.suno.ai/{uuid}.mp3`

## Each Request Generates 2 Variations

Both API and web UI produce **2 audio variations** per request. Listen to both and pick the best one.
