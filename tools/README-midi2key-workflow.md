# S.A.M. recording pipeline — MIDI → VICE → keystrokes → audio

How the 54 files in `recordings/` (and the base64 samples embedded in
`global-random.html`) were made. S.A.M. (Software Automatic Mouth, C64, 1982)
has no line-in/scriptable interface — the only way to drive it is to actually
type `SAY "..."` into a running emulator. This pipeline automates that typing
via a virtual MIDI keyboard, so a whole catalog of phrases can be recorded
unattended instead of by hand, one keystroke at a time.

## Signal chain

```
global-random-jingle-batch.sh
  → sendmidi (CLI)
  → loopMIDI Port #2 (virtual MIDI cable)
  → MidiKey2Key (midi2key.ini — MIDI note → keystroke mapping)
  → VICE (x64sc), focused, S.A.M. running in ]SAM (phoneme) mode
  → C64's own audio out
  → Voicemeeter "Out B2" (virtual audio cable)
  → ffmpeg (records, trims, normalizes)
  → LAME (encodes to MP3)
```

## One-time setup

1. **VICE**: `x64sc` (cycle-exact — plain `x64` reads timing wrong for S.A.M.).
   SID engine must be **ReSID** or **ReSID-FP**, not Fast SID (wrong pitch/speed
   otherwise). Load S.A.M., pick low or high memory (doesn't matter for
   `SAY "..."` testing), then `]SAM` to switch out of `]RECITER` (plain-English)
   mode — `SAY` in `]RECITER` mode just produces error beeps for phoneme input.
2. **loopMIDI**: create a virtual port named exactly `loopMIDI Port #2` (the
   script hardcodes this name).
3. **MidiKey2Key**: load `midi2key.ini` (this folder). Set MIDI-In to
   `loopMIDI Port #2`, press **Start**. The ini maps A–Z, 0–9, space, and the
   punctuation S.A.M. actually understands (`"`, `.`, `,`, `-`, `?`, `!`) plus
   `]` (BRACKETCLOSE, for the `]SAM`/`]SPEED`/etc. wedge commands) to MIDI notes
   — see `char_to_note()` in the script for the exact note numbers if this
   ever needs re-mapping. **Hex digits in `Data` must be uppercase, `Keyboard`
   values are case-sensitive .NET `Keys` enum names** — both silently produce
   "invalid key" errors otherwise.
4. **Voicemeeter**: route VICE's audio output to a "B2" bus so it's capturable
   as its own input device, separate from whatever else is making sound on
   the machine. The script records from `Voicemeeter Out B2 (VB-Audio
   Voicemeeter VAIO)` specifically (`REC_DEVICE` in the script).
5. **`sendmidi`** CLI and **LAME** (`lame3.100.1-x64`) need to be on `PATH` /
   at the path the script expects (`LAME_BIN`).

## Running it

```bash
./global-random-jingle-batch.sh list          # list the catalog, sends nothing
./global-random-jingle-batch.sh 5             # record only entry #5
./global-random-jingle-batch.sh all           # record the whole catalog, back to back
./global-random-jingle-batch.sh all 8         # same, 8s pause between entries
./global-random-jingle-batch.sh noparams 5    # entry #5 without re-sending SPEED/PITCH/KNOBS first
```

The script checks VICE and MidiKey2Key are actually running (with a visible
window) before doing anything, and re-focuses VICE before every single line it
types — Windows will happily steal focus away mid-run otherwise, and a
keystroke sent to the wrong window is a silently lost line, not an error.

**Per entry:** starts an `ffmpeg` recording (window sized from the phoneme
string's own length, minimum `REC_DURATION=20s`), sends the `SAY "..."`
line(s), waits for the window to close, trims silence
(`silenceremove`), checks the trimmed result is at least `MIN_VALID_DURATION`
(1.5s) long — too short usually means S.A.M. only produced its two-beep syntax
error — and retries up to `MAX_RETRIES` times if so. On success: two-pass
peak-normalizes to **-1dB** (`volumedetect` then exact gain applied), converts
to mono, encodes to MP3 via LAME. Output name:
`sam-<category-slug>-<comment-slug>-final.{wav,mp3}`.

## Adding a new line

Add a row to the `CATALOG` array (near the top of the script):

```
"CATEGORY|||Human-readable comment|||PHONEME STRING"
```

`CATEGORY` becomes the filename prefix (`OPENER`, `SYSTEM`, `PUNCHLINE`,
`EASTEREGG` so far). A `~~` inside the phoneme string splits it into two
sequential `SAY` calls (VICE/MIDI focus is re-acquired between them) — use
this only if a line is too long to type in one go or reads better as two
separate deliveries; don't use it just because a line is long, since a single
unsplit `SAY` records more reliably (fewer places for a focus-steal to lose a
keystroke).

## S.A.M. phoneme syntax — quick reference

- **Stress markers are 1–8**, not just "4" for everything: 1=very emotional,
  2=very emphatic, 3=fairly strong, 4=normal, 5=slight, 6=neutral/no pitch
  change, 7=falling pitch, 8=extreme falling pitch. Put the lowest number on
  whichever word(s) should carry the sentence.
- **Common combo pitfalls** (almost always means something else was meant,
  unless genuinely splitting two syllables): `GS`→`GZ` (bags), `BS`→`BZ`
  (slobs), `DS`→`DZ` (suds), `PZ`→`PS` (slaps), `TZ`→`TS` (curtsy), `KZ`→`KS`
  (fix), `NG`→`NXG` (singing), `NK`→`NXK` (bank).
- "the" before a vowel sound = `DH IY` ("thee"), otherwise `DHAX`.
- Don't lengthen a diphthong by repeating it (`OYOYOY` reads literally, not
  "held") — decompose into components instead (`OY`→`OHOHIYIYIY`,
  `AY`→`AAAAIYIYIY`).
- A hyphen only creates a pause if there's a non-letter on **both** sides.
- S.A.M. speaks **~2.5s max per breath** without a manual break — insert a
  hyphen/comma/period before that point; a single word longer than 2.5s can't
  be broken at all and will just fail.
- Punctuation: `-` = short pause, `,` = ~2× that, `.` = pause + falling pitch,
  `?` = pause + rising pitch (only actually correct for yes/no questions).
- `/H` (not bare `H`) for unvoiced h.
- Wedge commands (`]SAM`, `]SPEED`, `]PITCH`, `]KNOBS`) need the `]` prefix;
  `SAY` itself does not.
- Syntax errors produce two beeps and nothing else — no error message, no
  crash. This is what the script's `MIN_VALID_DURATION` retry logic is
  actually detecting.

**Tuned voice** (calmer/more adult than S.A.M.'s defaults, which read as
hysterical): `SPEED 93`, `PITCH 72`, `KNOBS 105,110` (KNOBS order is
MOUTH,THROAT — reversed from how S.A.M.'s own docs usually list it). S.A.M.
factory defaults for reference: `SPEED 72`, `PITCH 64`, `THROAT 128`,
`MOUTH 128`. Override per-run via env vars: `SPEED=90 PITCH=70 ./global-random-jingle-batch.sh all`.

## Known gotchas

- **Focus theft mid-run**: fixed by re-focusing VICE (`focus_vice()`, via
  `focus-window.ps1`'s `SetForegroundWindow`/`AttachThreadInput` trick) before
  every single typed line, not just once at the start — this was the root
  cause of a `~~`-split entry silently losing its second half.
- **Double-letter/garbled keystrokes**: looked like a script bug at first
  glance, ruled out by an isolated test (two identical MIDI notes sent
  back-to-back landed correctly) — it's genuine MIDI/focus timing jitter, not
  deterministic logic. If it recurs, increase the per-character delay in
  `type_text()` before suspecting the script itself.
- **`sam-*-i-m-searching-please-stand-by-final.*` filename has a stray space**
  in one older recording (`"sam-welcome-listener-i-am-searching-please-
  stand-by-final"`) — harmless (matches the base64 embed either way), just
  don't be surprised by it when browsing `recordings/`.
