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
DEFAULT_SPEED=82
DEFAULT_PITCH=72
DEFAULT_KNOBS="105,110"
PAUSE_BETWEEN=${2:-6}   # seconds between entries in "all" mode
FOCUS_SCRIPT="C:/Users/andre/Scripts/focus-window.ps1"
VICE_PROC="x64sc"
MIDIKEY_PROC="MidiKey2Key"

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
  sleep 0.2
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
    *)
      echo "WARN: unmapped char '$c', skipping" >&2
      echo ""
      ;;
  esac
}

# type_text "TEXT" -- sends TEXT as a single chained sendmidi invocation (port stays open)
type_text() {
  local text="$1"
  local cmd=(sendmidi dev "$MIDI_PORT" ch 1)
  local i c n
  for (( i=0; i<${#text}; i++ )); do
    c="${text:$i:1}"
    n=$(char_to_note "$c")
    [ -z "$n" ] && continue
    cmd+=(on "$n" 100 +0.220 off "$n" 0 +0.180)
  done
  "${cmd[@]}"
}

send_return() {
  sendmidi dev "$MIDI_PORT" ch 1 on 93 100 +0.220 off 93 0
  sleep 0.5
}

send_default_params() {
  echo ">> setting SPEED=$DEFAULT_SPEED PITCH=$DEFAULT_PITCH KNOBS=$DEFAULT_KNOBS"
  type_text "]SPEED $DEFAULT_SPEED"; send_return
  type_text "]PITCH $DEFAULT_PITCH"; send_return
  type_text "]KNOBS $DEFAULT_KNOBS"; send_return
}

# --- catalog: "PLAIN TEXT COMMENT|||PHONEME SAY STRING" ---
# NOTE: the "Radio Global Random." prefix is a separate, already-existing audio clip that gets
# prepended in the HTML player - so the phoneme strings below only contain the punchline itself
# (keeps every line comfortably under the ~80-char C64 direct-mode input limit, see SAM10.TXT).
# Entry #1: >80 chars, split into two SAY commands at the comma (marker "~~"); play_entry sends
# each half back to back with only a short 1s gap, not the big inter-entry PAUSE_BETWEEN.
CATALOG=(
"[OPENER 1] You are listening Radio Global Random - give your faith a chance!|||YUW4 AXR LIH4SAXNIHNX REY4DIYOH GLOH4BAXL RAE4NDAXM,~~GIH4V YAXR FEY4TH AX CHAE4NS."
"[OPENER 2] Radio Global Random|||REY4DIYOH GLOH4BAXL RAE4NDAXM."
"Your very own experience... No one ever hears the same.|||YOHR6 VEH5RIY OW2N EHKSPIH3RIYAXNS. NOW4 WAH4N EH4VER /HIY2AXRZ DHAX SEY4M."
"Become a citizen of global sound.|||BIHKAH4M AX5 SIH4TIHZEHN AHV GLOH4BAXL SAW7ND."
"We are one nation... of sound.|||WIY4 AXR WAH4N NEY4SHAXN, AHV SAW7ND."
"What can random do for you, today.|||WAH4T KAEN RAE4NDAXM DUW4 FOHR YUW4, TAXDEY4."
"Think Global, Play Random|||THIH4NXK GLOH4BAXL, PLEY4 RAE4NDAXM."
"The fight against the algorithm has begun. (v1, superseded by #7)|||DHAX FAY4T, AXGEH4NST DHIY4~~AE4LGAX6RIH6DHAH6M /HAXZ BIHGAH4N."
"The fight against the algorithm has begun. (v2: 'the' fixed)|||DHAX FAY4T, AXGEH4NST DHIY4~~AE4LGAX6RIH6DHAH6M /HAXZ BIHGAH4N."
"We have no idea what we're playing.|||WIY4 /HAE4V NOW4 AY4DIYAX WAH4T WIY4R PLEY4IHNX."
"For everyone who can't decide.|||FOHR EH4VRIYWAHN /HUW4 KAE4NT, DIHSAY4D."
"The ultimate random machine.|||DHIY AE4LTIH6MAXT, RAE4NDAXM MAXSHIY4N."
"Only randomness decides where you really go today.|||OW4NLIY RAE4NDAXMNAXS DIHSAY4DZ WEHR YUW4 RIY4LIY6 GOW4 TAXDEY4."
"Only true randomness can channel the energy...|||OW4NLIY TRUW4 RAE4NDAXMNAXS KAEN CHAE4NAXL DHIY EH4NERJIY..."
"Random for the masses, not the classes. (Jack Tramiel/Commodore homage)|||RAE4NDAXM FOHR DHAX MAE4SIHZ, NAA4T DHAX KLAE4SIHZ."
"My friends are knocking on my door to hear it. (C64 TV spot homage)|||MAY4 FREHNDZ AXR NAA4KIHNX AAN MAY4 DOHR TUW /HIHR IHT."
"Let go. Control is an illusion.|||LEHT GOW4. KAXNTROW4L IHZ AEN IHLUW4ZHAXN."
"Don't look for connections. There are none.|||DOWN4T LUH4K FOHR KAXNEHK4SHAXNZ. DHEHR AXR NAH4N."
"[Easter Egg] Not only shit happens.|||NAA4T OW2NLIY SHIH4T /HAE4PAXNZ."
"[Easter Egg] There's no such thing as coincidence.|||DHEH4RZ NOW4 SAH4CH THIH4NX AEZ KOWIH4NSIHDAXNS."
"[Easter Egg] You want to win the lottery? Buy a ticket!|||YUW4 WAH4NT TUW WIH4N DHAX LAA4TAXRIY. BAY4 AX TIH4KEHT."
)

list_catalog() {
  local i=1
  for entry in "${CATALOG[@]}"; do
    local comment="${entry%%|||*}"
    printf "%2d) %s\n" "$i" "$comment"
    i=$((i+1))
  done
}

check_lengths() {
  local i=1 bad=0
  for entry in "${CATALOG[@]}"; do
    local comment="${entry%%|||*}"
    local phoneme="${entry##*|||}"
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
  local comment="${entry%%|||*}"
  local phoneme="${entry##*|||}"
  echo ">> #$idx: $comment"
  [ "$skip_focus" != "nofocus" ] && focus_vice
  if [[ "$phoneme" == *"~~"* ]]; then
    local part parts
    IFS=$'\x1f' read -ra parts <<< "${phoneme//~~/$'\x1f'}"
    for part in "${parts[@]}"; do
      type_text "SAY \"${part}\""
      send_return
      sleep 4
    done
  else
    type_text "SAY \"${phoneme}\""
    send_return
  fi
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
    send_default_params
    i=1
    for entry in "${CATALOG[@]}"; do
      play_entry "$i" nofocus
      i=$((i+1))
      sleep "$PAUSE_BETWEEN"
    done
    ;;
  *)
    focus_vice
    send_default_params
    play_entry "$MODE"
    ;;
esac
