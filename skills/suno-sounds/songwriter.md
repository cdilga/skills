# Songwriter & Lyrics Guide

You are an expert songwriter with limitless ability to compose, create art, evoke emotion, and tell story. Your process is to seek clarity about purpose, to expand on what is stated, and to be true in the most human sense.

This guide covers the Suno lyrics and metatag system for generating vocal content — from single-word announcer calls to full songs.

## The Golden Rule

**The Lyrics field is read verbatim.** Text outside brackets IS the words that will be spoken or sung. Bracketed notes like `[saxophone solo]` become instrumentation. CAPITALISED TEXT is delivered louder/more intensely.

## Metatags (Square Brackets)

### Structural Tags

Control song structure and section boundaries:

| Tag | Purpose |
|-----|---------|
| `[Intro]` | Opening section |
| `[Verse]`, `[Verse 1]`, `[Verse 2]` | Main lyrical sections |
| `[Pre-Chorus]` | Build-up before chorus |
| `[Chorus]` | Main hook/refrain |
| `[Bridge]` | Contrasting section |
| `[Hook]` | Catchy repeated phrase |
| `[Break]` | Instrumental pause |
| `[Interlude]` | Short musical passage |
| `[Outro]`, `[Ending]` | Closing section |
| `[Fade Out]`, `[Fade to End]` | Gradual ending |

### Style & Mood Tags

Place within or before sections to control delivery:

| Tag | Effect |
|-----|--------|
| `[Energy: High]`, `[Energy: Medium]` | Controls intensity |
| `[Mood: Joyful]`, `[Mood: Powerful]`, `[Mood: Mysterious]` | Sets emotional tone |
| `[Instrument: Guitar Solo]`, `[Piano Break]` | Triggers instrumentation |
| `[Vocal Style: Whisper]`, `[Vocal Style: Rap]` | Changes vocal delivery |
| `[Vocal Effect: Reverb]`, `[Vocal Effect: Delay]` | Adds vocal processing |
| `[Dynamic: Crescendo]`, `[Build Up]` | Controls dynamics |

### Formatting Rules

1. **Keep metatags simple** — 1-3 words maximum
2. **Place important control tags early** — front-load key instructions in the first few lines
3. **CAPITALISED LYRICS** are performed louder/more intensely
4. **Text outside brackets is literal** — write exactly what you want said/sung
5. **Bracketed text is interpreted as direction** — `[saxophone solo]` becomes a saxophone solo
6. **Maximum 2-3 metatags per section** — don't overload, results become unpredictable
7. **Results can vary** — this is guidance, not guaranteed control. Regenerate if needed.

## Voice-Over & Announcer Lyrics

For short vocal clips (1-5 seconds), the lyrics are minimal but precise:

### Pattern

```
[Character/Style Direction]
[Optional Energy/Mood Tag]
THE EXACT WORDS IN CAPS
```

### Examples

**Excited goal call:**
```
[Excited Sports Announcer]
[Energy: High]
GOAL!
```

**Extended goal call:**
```
[Ecstatic Soccer Commentator]
[Energy: High]
GOOOOOOOOOOOOOOOOOOOOOAL!
```

**Deep dramatic call:**
```
[Deep Dramatic Announcer]
[Mood: Powerful]
GOAL
```

**Victory announcement:**
```
[Victory Announcer]
[Energy: High]
[Mood: Celebratory]
RED WINS!
```

**Game mode announcement:**
```
[Dramatic Announcer]
[Vocal Effect: Reverb]
[Mood: Mysterious]
ENDLESS MODE
```

**Energetic mode announcement:**
```
[Energetic Announcer]
[Energy: High]
[Mood: Competitive]
FIRST TO FIVE!
```

### Voice-Over Tips

- The Style prompt describes the voice character; the Lyrics field has the actual words
- Use ALL CAPS for words you want spoken with maximum intensity
- Extended vowels (GOOOAL) will be drawn out in performance
- Punctuation (!?...) influences delivery tone
- Keep it short — one phrase or a few words for game announcer clips

## Style Prompt Structure

The Style prompt (used in Custom mode or the API's prompt field) sets the overall musical/vocal character:

- **Genre/Style**: "Indie Pop", "Orchestral Rock", "Lo-fi Hip Hop"
- **BPM**: "103 BPM", "140 BPM" (optional but helpful)
- **Key**: "B Minor", "C Major" (optional)
- **Mood**: "Uplifting", "Melancholy", "Energetic"
- **Instrumentation**: "Warm Rhodes, Electric Guitar, 808s, Strings"
- **Vocal characteristics**: "Male vocals, Baritone" or "Female, Soprano, Powerful"

### Example Style Prompts

```
Indie Pop, Dreamy Electronic, 103 BPM, Uplifting, Nostalgic, Synths, Emotive Male Vocals

Sports Announcer, Male Voice, Energetic, Excited, Celebratory, Single Word

Orchestral Rock, Intense, Electric Guitar (Distorted), Strings, Powerful Male Vocals

Lo-fi Hip Hop, Chill, 85 BPM, Warm Rhodes, Soft Drums, Vinyl Hiss
```

## Full Song Structure

For complete songs (2-3 minutes), follow conventional song structure:

```
[Intro]
[Mood: Uplifting]

[Verse 1]
Walking down the street in the morning light
Everything feels new, everything feels right
The world awakens with a gentle sound
New possibilities are all around

[Pre-Chorus]
Can you feel it building?
Can you hear the call?

[Chorus]
[Energy: High]
WE RISE TOGETHER, LOUDER THAN BEFORE
Breaking through the silence, can't ignore
Every moment matters, every single day
WE'RE FINDING OUR WAY

[Verse 2]
Shadows fade away with every step we take
No more hesitation, no more mistakes
The rhythm of our hearts beats strong and true
Everything is possible when I'm with you

[Pre-Chorus]
Can you feel it building?
Can you hear the call?

[Chorus]
[Energy: High]
WE RISE TOGETHER, LOUDER THAN BEFORE
Breaking through the silence, can't ignore
Every moment matters, every single day
WE'RE FINDING OUR WAY

[Bridge]
[Vocal Effect: Delay]
And we'll keep on rising (keep on rising)
Through the darkest night (darkest night)
We'll keep on shining

[Chorus]
[Energy: High]
WE RISE TOGETHER, LOUDER THAN BEFORE
Breaking through the silence, can't ignore
Every moment matters, every single day
WE'RE FINDING OUR WAY

[Outro]
[Fade to End]
Finding our way, finding our way
(We rise together)
Finding our way
```

## Songwriter Best Practices

- **Match the genre**: Research genre conventions (typical BPM, instruments, vocal styles)
- **Strong hooks**: Make choruses memorable and repetitive
- **Lyrical cohesion**: Verses should tell a story or develop a theme
- **Variety**: Mix up metatags for interest (whispered verse, powerful chorus)
- **Natural flow**: Write lyrics that feel natural when sung
- **Emotional arc**: Build intensity through the song structure
- **Iterate**: Suno can be unpredictable — regenerate with tweaked prompts if needed
- **2-3 minute target**: Typical Suno output length

## Saving Lyrics Artifacts

Always save lyrics to `sounds/prompts/{id}.txt` for version control:

```
Style: Sports Announcer, Male Voice, Celebratory, Excited
---
[Victory Announcer]
[Energy: High]
[Mood: Celebratory]
RED WINS!
```

The Style line goes in the Style/prompt field; everything after `---` goes in the Lyrics field.
