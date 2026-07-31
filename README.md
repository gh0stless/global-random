# GLOBAL RANDOM — Democracy of Sound

Live: **[crazy-midi.de/global-random](https://crazy-midi.de/global-random/)**

A single, self-contained HTML page (~1.9MB, no build step, no backend) that plays music from **247 countries and territories** via real, fairness-weighted randomness — not algorithmic curation. Track titles are translated live into up to 87 languages. Music comes from MusicBrainz (discovery) and Spotify (playback via the official embed); country resolution falls back to Wikipedia artist bios when MusicBrainz's own metadata is empty.

Deliberately positioned as a counter-argument to algorithmic music curation: every track is a genuine random draw across a fairness-weighted pool of countries, not a recommendation.

## How it works

- **Discovery**: random MusicBrainz offsets are searched for Spotify-linked tracks; each candidate is resolved to an artist and a country.
- **Pool**: a capped, FIFO-refreshed pool per country (`countryStacks`) keeps the freshest finds; a session-wide cap stops any one country from dominating.
- **Selection**: two independent `Math.random()` draws — first the country, then the track within that country's pool — feed a small playback queue.
- **Playback**: the official Spotify IFrame API, one active player plus three dimmed preview slots that mirror the upcoming queue.
- **Translation**: live, per-track translation into up to 87 languages via the MyMemory API.

## Files

| File | Purpose |
|---|---|
| `global-random.html` | The app itself. Deployed as-is to the server as `index.html`. |
| `beschreibung.html` / `description.html` | Artist statement / project description, German and English. |
| `mb-*.html`, `wiki-bio-country-test.html`, `redirection.html` | Standalone test tools used during development; not part of the running app. |

## Related projects

This is the canonical source. Two wrapper projects embed this same file unmodified in other platforms, kept in sync manually:

- [globalrandom-joomla](https://github.com/gh0stless/globalrandom-joomla) — Joomla component
- [next-global-random](https://github.com/gh0stless/next-global-random) — Nextcloud app

## License

The artwork (`global-random.html` and its content) is licensed under **[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/)** — attribution required, non-commercial use only, **no derivatives/modifications** permitted.

© 2026 Andreas S.
