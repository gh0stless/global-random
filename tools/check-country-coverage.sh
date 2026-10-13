#!/usr/bin/env bash
# Compares a fresh export of gr_tracks' distinct countries against the
# saved baseline (gr-tracks-country-baseline.txt, taken 13.10.2026 when
# the COUNTRIES whitelist in global-random.html was pruned from 247 to
# 190 — see that array's own "Pruned 13.10.2026" comment for the reasoning).
#
# Run this after every future gr_tracks refresh, BEFORE deciding whether
# to touch the COUNTRIES array again:
#
#   mysql -h 10.35.232.248 -u k34837_k34837b -p... k34837_joomla_3 -N \
#     -e "SELECT DISTINCT country FROM gr_tracks ORDER BY country;" \
#     > fresh_countries.txt
#   tools/check-country-coverage.sh fresh_countries.txt
#
# "Gained" = countries with data now that had none in the baseline — real
#   candidates to ADD to COUNTRIES (check they're in ISO-3166-1 first).
# "Lost" = countries that had data in the baseline but don't anymore —
#   if any of these are currently IN COUNTRIES, that's a regression, not
#   just noise: that flag can no longer ever fill, same problem the
#   13.10.2026 prune fixed. Worth a deliberate decision, not a silent
#   re-prune — same spirit as that comment in global-random.html.
#
# This only diffs the raw gr_tracks country set against itself over time.
# It does NOT know what's currently in COUNTRIES — cross-check "Lost"
# entries against that array by hand (grep is enough, it's a short list).

set -euo pipefail
cd "$(dirname "$0")"

FRESH="${1:?Usage: $0 <fresh-countries-file>  (one ISO code per line, from a new gr_tracks export)}"
BASELINE="gr-tracks-country-baseline.txt"

if [[ ! -f "$BASELINE" ]]; then
  echo "No baseline found at $BASELINE — nothing to compare against." >&2
  exit 1
fi

sort -u "$BASELINE" -o "$BASELINE.sorted"
sort -u "$FRESH" -o "$FRESH.sorted"

echo "Baseline: $(wc -l < "$BASELINE.sorted") countries (as of last save)"
echo "Fresh:    $(wc -l < "$FRESH.sorted") countries"
echo

GAINED=$(comm -13 "$BASELINE.sorted" "$FRESH.sorted")
LOST=$(comm -23 "$BASELINE.sorted" "$FRESH.sorted")

echo "=== Gained (had none before, have data now) ==="
if [[ -n "$GAINED" ]]; then echo "$GAINED"; else echo "(none)"; fi
echo
echo "=== Lost (had data before, none now — check against COUNTRIES!) ==="
if [[ -n "$LOST" ]]; then echo "$LOST"; else echo "(none)"; fi
echo

rm -f "$BASELINE.sorted" "$FRESH.sorted"

echo "If this looks right, update the baseline for next time with:"
echo "  sort -u '$FRESH' -o '$BASELINE'"
