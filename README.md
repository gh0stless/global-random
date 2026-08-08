# GLOBAL RANDOM — Democracy of Sound

Live: **[crazy-midi.de/global-random](https://crazy-midi.de/global-random/)** — also hosted on **[global-random.radio](https://global-random.radio/)**

A single, self-contained HTML page (~3.4MB, no build step, no backend) that plays music from **247 countries and territories** via real, fairness-weighted randomness — not algorithmic curation. Track titles are translated live into up to 87 languages. Music comes from MusicBrainz (discovery) and Spotify (playback via the official embed); country resolution falls back to Wikipedia artist bios when MusicBrainz's own metadata is empty.

Deliberately positioned as a counter-argument to algorithmic music curation: every track is a genuine random draw across a fairness-weighted pool of countries, not a recommendation.

## How it works

- **Discovery**: random MusicBrainz offsets are searched for Spotify-linked tracks; each candidate is resolved to an artist and a country.
- **Pool**: a capped, FIFO-refreshed pool per country (`countryStacks`) keeps the freshest finds; a session-wide cap stops any one country from dominating.
- **Selection**: two independent `Math.random()` draws — first the country, then the track within that country's pool — feed a small playback queue.
- **Playback**: the official Spotify IFrame API, one active player plus three dimmed preview slots that mirror the upcoming queue.
- **Translation**: live, per-track translation into up to 87 languages via the MyMemory API.
- **Voice**: periodic station-ID jingles and system announcements, spoken by an actual **S.A.M. (Software Automatic Mouth, C64, 1982)** running in a VICE emulator — not a modern TTS voice. See `tools/` below for how those were recorded.

## Files

| File | Purpose |
|---|---|
| `global-random.html` | The app itself. Deployed as-is to the server as `index.html`. |
| `beschreibung.html` / `description.html` | Artist statement / project description, German and English. |
| `tools/` | Development tooling, not part of the running app — see below. |

### `tools/`

| File | Purpose |
|---|---|
| `README-midi2key-workflow.md` | How the S.A.M. voice samples were actually recorded: a MIDI-driven automation chain (`sendmidi` → a virtual MIDI cable → MidiKey2Key → keystrokes into VICE) that types `SAY "..."` phoneme commands into the emulator and records the result, plus an S.A.M. phoneme-syntax cheat sheet. |
| `global-random-jingle-batch.sh` | The recording automation script the README above documents — the actual catalog of every spoken line lives in this script. |
| `global-random-jingles.bas` | The same phoneme catalog as a native Commodore 64 BASIC V2.0 program, for anyone who wants to run it on real hardware instead of an emulator. |
| `midi2key.ini` | The MidiKey2Key keyboard-mapping config the recording chain depends on. |
| `recordings/` | The raw and final takes (WAV + MP3) that the base64 samples embedded in `global-random.html` came from. |
| `Country Name Batch Translator (Test Tool).html`, `W-E Snow-Phrase Comparison (Test Tool).html` | Standalone batch-translation utilities (MyMemory API), reusable for adding more languages to the app's country-name/snow-effect dictionaries. |
| `mb-*.html`, `wiki-bio-country-test.html` | One-off research tools from early development (MusicBrainz country/offset coverage, Wikipedia-bio country resolution) — findings are already baked into the app, kept for reference. |
| `fm-radio-tuning-sweeps.flac`/`.mp3` | Raw source audio for the ambient radio-tuning sound played during the search phase. |

## Related projects

This is the canonical source. Two wrapper projects embed this same file unmodified in other platforms, kept in sync manually:

- [globalrandom-joomla](https://github.com/gh0stless/globalrandom-joomla) — Joomla component
- [next-global-random](https://github.com/gh0stless/next-global-random) — Nextcloud app

## License

The artwork (`global-random.html` and its content) is licensed under **[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)** — attribution required, non-commercial use only, **no derivatives/modifications** permitted.

© 2026 Andreas S.
