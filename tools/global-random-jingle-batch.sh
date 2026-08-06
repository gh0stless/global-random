#!/usr/bin/env bash
# GLOBAL RANDOM - S.A.M. Jingle Batch Player
# Sends S.A.M. phoneme SAY-commands to VICE via SendMIDI -> loopMIDI Port #2 -> MidiKey2Key.
# Prerequisites: VICE + S.A.M. running in ]SAM (phoneme) mode, focused; loopMIDI Port #2 selected
# and "Start" active in MidiKey2Key; midi2key.ini has A-Z, 0-9, space, quote, period, comma,
# hyphen, question mark and "]" (BRACKETCLOSE) mapped.
#
# Usage:
#   ./global-random-jingle-batch.sh list          # list all catalog entries, don't send anything
#   ./global-random-jingle-batch.sh 5             # play only entry #5
#   ./global-random-jingle-batch.sh all            # play the whole catalog back to back (default)
#   ./global-random-jingle-batch.sh all 8          # play whole catalog, 8s pause between entries
#   ./global-random-jingle-batch.sh noparams 5     # play entry #5 without sending SPEED/PITCH/KNOBS first

MIDI_PORT="loopMIDI Port #2"
DEFAULT_SPEED="${SPEED:-93}"
DEFAULT_PITCH="${PITCH:-72}"
DEFAULT_KNOBS="${KNOBS:-105,110}"
PAUSE_BETWEEN=${2:-6}   # seconds between entries in "all" mode
FOCUS_SCRIPT="C:/Users/andre/Scripts/focus-window.ps1"
VICE_PROC="x64sc"
MIDIKEY_PROC="MidiKey2Key"
REC_DEVICE="Voicemeeter Out B2 (VB-Audio Voicemeeter VAIO)"
REC_DIR="C:/Users/andre/Work/Projekt Global-Random/tools/recordings"
REC_DURATION=20
LAME_BIN="C:/prg/Lame/lame3.100.1-x64/lame.exe"
MIN_VALID_DURATION=1.5
MAX_RETRIES=3

require_processes() {
  local ok=1
  for p in "$VICE_PROC" "$MIDIKEY_PROC"; do
    local out
    out=$(powershell -ExecutionPolicy Bypass -File "$FOCUS_SCRIPT" -ProcessName "$p" -CheckOnly 2>&1)
    if [[ "$out" == FOUND:* ]]; then
      echo "OK  $p running (${out#FOUND:})"
    else
      echo "FEHLT: $p läuft nicht (oder kein sichtbares Fenster)"
      ok=0
    fi
  done
  [ "$ok" -eq 1 ]
}

focus_vice() {
  local out
  out=$(powershell -ExecutionPolicy Bypass -File "$FOCUS_SCRIPT" -ProcessName "$VICE_PROC" 2>&1)
  if [[ "$out" != OK:* ]]; then
    echo "WARN: VICE-Fokus fehlgeschlagen ($out)" >&2
  fi
  sleep 1.5
}

# --- character -> MIDI note mapping (matches midi2key.ini) ---
char_to_note() {
  local c="$1" ascii
  case "$c" in
    [A-Z])
      printf -v ascii '%d' "'$c"
      echo $((60 + ascii - 65))
      ;;
    [0-9])
      printf -v ascii '%d' "'$c"
      echo $((95 + ascii - 48))
      ;;
    ' ') echo 92 ;;
    '"') echo 86 ;;
    '.') echo 87 ;;
    ',') echo 88 ;;
    '-') echo 89 ;;
    '?') echo 90 ;;
    '!') echo 91 ;;
    ']') echo 105 ;;
    '/') echo 106 ;;
    '[') echo 107 ;;
    '$') echo 108 ;;
    '=') echo 109 ;;
    ':') echo 110 ;;
    ';') echo 111 ;;
    *)
      echo "WARN: unmapped char '$c', skipping" >&2
      echo ""
      ;;
  esac
}

# type_text "TEXT" -- sends TEXT as a single chained sendmidi invocation (port stays open)
type_text() {
  local text="$1"
  local cmd=(sendmidi dev "$MIDI_PORT" ch 1 +0.3)
  local i c n
  for (( i=0; i<${#text}; i++ )); do
    c="${text:$i:1}"
    n=$(char_to_note "$c")
    [ -z "$n" ] && continue
    cmd+=(on "$n" 100 +0.350 off "$n" 0 +0.250)
  done
  "${cmd[@]}"
}

send_return() {
  sendmidi dev "$MIDI_PORT" ch 1 on 93 100 +0.350 off 93 0
  sleep 0.5
}

send_default_params() {
  echo ">> setting SPEED=$DEFAULT_SPEED PITCH=$DEFAULT_PITCH KNOBS=$DEFAULT_KNOBS"
  type_text "]"; sleep 0.4; type_text "SPEED $DEFAULT_SPEED"; send_return
  type_text "]"; sleep 0.4; type_text "PITCH $DEFAULT_PITCH"; send_return
  type_text "]"; sleep 0.4; type_text "KNOBS $DEFAULT_KNOBS"; send_return
}

# --- catalog: "CATEGORY|||PLAIN TEXT COMMENT|||PHONEME SAY STRING" ---
# Categories: OPENER, SYSTEM, PUNCHLINE, EASTEREGG
# NOTE: the "Radio Global Random." prefix is a separate, already-existing audio clip that gets
# prepended in the HTML player - so the PUNCHLINE/EASTEREGG phoneme strings below only contain
# the punchline itself (keeps every line comfortably under the ~80-char C64 direct-mode input
# limit, see SAM10.TXT). SYSTEM entries are standalone status announcements, no prefix involved.
# Entries with ">80 chars" are split into two SAY commands via the "~~" marker; play_entry sends
# each half back to back with a short 4s gap, not the big inter-entry PAUSE_BETWEEN.
CATALOG=(
"OPENER|||You are listening Radio Global Random|||YUW4 AXR LIH4SAXNIHNX REY4DIYOH GLOH4BAXL RAE4NDAXM."
"OPENER|||Radio Global Random|||REY4DIYOH GLOH4BAXL RAE4NDAXM."
"SYSTEM|||Welcome, listener.|||WEHL4KAXM, LIH4SAXNAXR."
"SYSTEM|||I'm searching, please stand by.|||AY4M SER4CHIHNX, PLIY4Z STAE4ND BAY4."
"SYSTEM|||We can start.|||WIY4 KAEN STAA4RT."
"SYSTEM|||Press play on screen.|||PREH4S PLEY4 AXN SKRIY4N."
"PUNCHLINE|||Give your faith a chance!|||GIH4V YAXR FEY4TH AX CHAE4NS."
"PUNCHLINE|||Your very own experience... No one ever hears the same.|||YOHR6 VEH5RIY OW2N EHKSPIH3RIYAXNS.~~NOW4 WAH4N EH4VER /HIY2AXRZ DHAX SEY4M."
"PUNCHLINE|||Become a citizen of global sound.|||BIHKAH4M AX5 SIH4TIHZEHN AHV GLOH4BAXL SAW7ND."
"PUNCHLINE|||We are one nation... of sound.|||WIY4 AXR WAH4N NEY4SHAXN, AHV SAW7ND."
"PUNCHLINE|||What can random do for you, today.|||WAH4T KAEN RAE4NDAXM DUW4 FOHR YUW4, TAXDEY4."
"PUNCHLINE|||Think Global, Play Random|||THIH4NXK GLOH4BAXL, PLEY4 RAE4NDAXM."
"PUNCHLINE|||The fight against the algorithm has begun.|||DHAX FAY4T, AXGEH4NST DHIY4 AE4LGAX6RIH6DHAH6M /HAXZ BIHGAH4N."
"PUNCHLINE|||We have no idea what we're playing.|||WIY4 /HAE4V NOW4 AY4DIYAX WAH4T WIY4R PLEY4IHNX."
"PUNCHLINE|||For everyone who can't decide.|||FOHR EH4VRIYWAHN /HUW4 KAE4NT, DIHSAY4D."
"PUNCHLINE|||The ultimate random machine.|||DHIY AE4LTIH6MAXT, RAE4NDAXM MAXSHIY4N."
"PUNCHLINE|||Only randomness decides where you really go today.|||OW4NLIY RAE4NDAXMNAXS DIHSAY4DZ WEHR YUW4 RIY4LIY6 GOW4 TAXDEY4."
"PUNCHLINE|||Only true randomness can channel the energy...|||OW4NLIY TRUW4 RAE4NDAXMNAXS KAEN CHAE4NAXL DHIY EH4NERJIY..."
"PUNCHLINE|||Random for the masses, not the classes. (Jack Tramiel/Commodore homage)|||RAE4NDAXM FOHR DHAX MAE4SIHZ, NAA4T DHAX KLAE4SIHZ."
"PUNCHLINE|||My friends are knocking on my door to hear it. (C64 TV spot homage)|||MAY4 FREHNDZ AXR NAA4KIHNX AAN MAY4 DOHR TUW /HIHR IHT."
"PUNCHLINE|||Let go. Control is an illusion.|||LEHT GOW4. KAXNTROW4L IHZ AEN IHLUW4ZHAXN."
"PUNCHLINE|||Don't look for connections. There are none.|||DOWN4T LUH4K FOHR KAXNEHK4SHAXNZ. DHEHR AXR NAH4N."
"PUNCHLINE|||...Your wellness coach hears it too.|||YOHR4 WEHL4NAXS KOW4CH /HIY2AXRZ IHT TUW4."
"PUNCHLINE|||Better than stocks. Ask your investment advisor.|||BEH4TAXR DHAE4N STAA4KS. AE4SK YAXR IHNVEH4STMAXNT AEDVAY4ZAXR."
"EASTEREGG|||Not only shit happens.|||NAA4T OW2NLIY SHIH4T /HAE4PAXNZ."
"EASTEREGG|||There's no such thing as coincidence.|||DHEH4RZ NOW4 SAH4CH THIH4NX AEZ KOWIH4NSIHDAXNS."
"EASTEREGG|||You want to win the lottery? Buy a ticket!|||YUW4 WAH4NT TUW WIH4N DHAX LAA4TAXRIY. BAY4 AX TIH4KEHT."
)

list_catalog() {
  local i=1
  for entry in "${CATALOG[@]}"; do
    local category="${entry%%|||*}"
    local rest="${entry#*|||}"
    local comment="${rest%%|||*}"
    printf "%2d) [%s] %s\n" "$i" "$category" "$comment"
    i=$((i+1))
  done
}

check_lengths() {
  local i=1 bad=0
  for entry in "${CATALOG[@]}"; do
    local category="${entry%%|||*}"
    local rest="${entry#*|||}"
    local comment="${rest%%|||*}"
    local phoneme="${rest##*|||}"
    if [[ "$phoneme" == *"~~"* ]]; then
      local part parts n=1
      IFS=$'\x1f' read -ra parts <<< "${phoneme//~~/$'\x1f'}"
      for part in "${parts[@]}"; do
        local len=$(( ${#part} + 6 ))  # + SAY "" wrapper
        local flag=""; [ "$len" -gt 80 ] && { flag=" <<< TOO LONG"; bad=1; }
        printf "%2d.%d) %3d chars%s  %s\n" "$i" "$n" "$len" "$flag" "$comment"
        n=$((n+1))
      done
    else
      local len=$(( ${#phoneme} + 6 ))
      local flag=""; [ "$len" -gt 80 ] && { flag=" <<< TOO LONG"; bad=1; }
      printf "%2d)   %3d chars%s  %s\n" "$i" "$len" "$flag" "$comment"
    fi
    i=$((i+1))
  done
  [ "$bad" -eq 0 ] && echo "-- all entries under 80 chars --"
}

play_entry() {
  local idx="$1"
  local skip_focus="$2"
  local entry="${CATALOG[$((idx-1))]}"
  [ -z "$entry" ] && { echo "No entry #$idx"; return 1; }
  local category="${entry%%|||*}"
  local rest="${entry#*|||}"
  local comment="${rest%%|||*}"
  local phoneme="${rest##*|||}"
  echo ">> #$idx [$category]: $comment"
  [ "$skip_focus" != "nofocus" ] && focus_vice
  if [[ "$phoneme" == *"~~"* ]]; then
    local part parts
    IFS=$'\x1f' read -ra parts <<< "${phoneme//~~/$'\x1f'}"
    for part in "${parts[@]}"; do
      focus_vice
      type_text "SAY \"${part}\""
      send_return
      sleep 8
    done
  else
    type_text "SAY \"${phoneme}\""
    send_return
  fi
}

estimate_duration() {
  local idx="$1"
  local entry="${CATALOG[$((idx-1))]}"
  local rest="${entry#*|||}"
  local phoneme="${rest##*|||}"
  local total=3   # pre-roll + safety margin
  if [[ "$phoneme" == *"~~"* ]]; then
    local part parts
    IFS=$'\x1f' read -ra parts <<< "${phoneme//~~/$'\x1f'}"
    for part in "${parts[@]}"; do
      total=$(awk "BEGIN{print $total + ${#part}*0.4 + 1 + 8}")
    done
  else
    total=$(awk "BEGIN{print $total + ${#phoneme}*0.4 + 1 + 6}")
  fi
  awk "BEGIN{printf \"%d\", $total}"
}

record_entry() {
  local idx="$1"
  local entry="${CATALOG[$((idx-1))]}"
  [ -z "$entry" ] && { echo "No entry #$idx"; return 1; }
  local rest="${entry#*|||}"
  local comment="${rest%%|||*}"
  mkdir -p "$REC_DIR"
  local raw="$REC_DIR/jingle-$(printf '%02d' "$idx")-raw.wav"
  local trimmed="$REC_DIR/jingle-$(printf '%02d' "$idx")-trimmed.wav"
  local dur; dur=$(estimate_duration "$idx")
  [ "$dur" -lt "$REC_DURATION" ] && dur="$REC_DURATION"
  echo ">> recording #$idx: $comment (${dur}s Fenster)"
  ffmpeg -y -f dshow -i audio="$REC_DEVICE" -t "$dur" "$raw" > /tmp/ffmpeg-rec-$idx.log 2>&1 &
  local ffpid=$!
  sleep 1.5
  play_entry "$idx"
  wait "$ffpid"
  ffmpeg -y -i "$raw" -af "silenceremove=start_periods=1:start_duration=0.1:start_threshold=-40dB:stop_periods=1:stop_duration=0.5:stop_threshold=-40dB" "$trimmed" > /tmp/ffmpeg-trim-$idx.log 2>&1
  echo ">> saved: $trimmed"
}

slugify() {
  local s="$1"
  s="${s,,}"
  s=$(echo "$s" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  echo "${s:0:50}"
}

get_duration() {
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null
}

process_entry() {
  local idx="$1"
  local entry="${CATALOG[$((idx-1))]}"
  [ -z "$entry" ] && { echo "No entry #$idx"; return 1; }
  local category="${entry%%|||*}"
  local rest="${entry#*|||}"
  local comment="${rest%%|||*}"
  local typeprefix; typeprefix=$(slugify "$category")
  local slug; slug=$(slugify "$comment")
  local attempt=1 dur=0
  local trimmed="$REC_DIR/jingle-$(printf '%02d' "$idx")-trimmed.wav"

  while (( attempt <= MAX_RETRIES )); do
    record_entry "$idx"
    sleep 0.5
    dur=$(get_duration "$trimmed")
    [ -z "$dur" ] && dur=0
    if awk "BEGIN{exit !($dur >= $MIN_VALID_DURATION)}"; then
      break
    fi
    echo "!! #$idx zu kurz (${dur}s) - vermutlich Piepton, Versuch $attempt/$MAX_RETRIES, wiederhole..."
    attempt=$((attempt+1))
  done

  if (( attempt > MAX_RETRIES )); then
    echo "!! #$idx nach $MAX_RETRIES Versuchen immer noch zu kurz - manuell prüfen: $trimmed"
    return 1
  fi

  local finalwav="$REC_DIR/sam-${typeprefix}-${slug}-final.wav"
  local finalmp3="$REC_DIR/sam-${typeprefix}-${slug}-final.mp3"

  # peak-normalize to -1dB (two-pass: measure, then apply exact gain)
  local maxvol; maxvol=$(ffmpeg -i "$trimmed" -af volumedetect -f null - 2>&1 | grep -oP 'max_volume:\s*\K[-0-9.]+')
  [ -z "$maxvol" ] && maxvol=0
  local gain; gain=$(awk "BEGIN{print -1 - ($maxvol)}")
  ffmpeg -y -i "$trimmed" -af "aformat=channel_layouts=mono,volume=${gain}dB" "$finalwav" > /tmp/ffmpeg-norm-$idx.log 2>&1
  "$LAME_BIN" --silent -m m -b 128 "$finalwav" "$finalmp3"
  echo ">> #$idx fertig: $finalwav / $finalmp3"
}

record_all() {
  local i
  for (( i=1; i<=${#CATALOG[@]}; i++ )); do
    process_entry "$i"
  done
  echo "== fertig, alle Dateien in $REC_DIR =="
}

MODE="${1:-all}"

if [ "$MODE" != "list" ] && [ "$MODE" != "lengths" ]; then
  require_processes || { echo "Abbruch: VICE und/oder MidiKey2Key nicht gefunden."; exit 1; }
fi

case "$MODE" in
  list)
    list_catalog
    ;;
  lengths)
    check_lengths
    ;;
  params)
    focus_vice
    send_default_params
    ;;
  record)
    idx="${2:?entry number required}"
    record_entry "$idx"
    ;;
  process)
    idx="${2:?entry number required}"
    process_entry "$idx"
    ;;
  recordall)
    record_all
    ;;
  noparams)
    idx="${2:?entry number required}"
    play_entry "$idx"
    ;;
  raw)
    text="${2:?phoneme text required}"
    focus_vice
    type_text "SAY \"${text}\""
    send_return
    ;;
  all)
    focus_vice
    i=1
    for entry in "${CATALOG[@]}"; do
      play_entry "$i" nofocus
      i=$((i+1))
      sleep "$PAUSE_BETWEEN"
    done
    ;;
  *)
    play_entry "$MODE"
    ;;
esac
