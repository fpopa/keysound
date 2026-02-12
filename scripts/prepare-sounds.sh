#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RECORDINGS="$PROJECT_DIR/recordings"
OUTPUT="$PROJECT_DIR/Resources/sounds"

rm -rf "$OUTPUT"

# --- Cherry MX Brown (Foxfire: separate press + release) ---
mkdir -p "$OUTPUT/cherry-mx-brown"
afconvert -f WAVE -d LEI16@44100 -c 1 \
    "$RECORDINGS/570754__foxfire__keyboard-press-down.wav" \
    "$OUTPUT/cherry-mx-brown/keydown_1.wav"
afconvert -f WAVE -d LEI16@44100 -c 1 \
    "$RECORDINGS/570755__foxfire__keyboard-key-release.wav" \
    "$OUTPUT/cherry-mx-brown/keyup_1.wav"
echo "cherry-mx-brown: 1 keydown, 1 keyup"

# --- Clicky (StavSounds: 19 clicky samples, full keystroke as keydown) ---
STAV="$RECORDINGS/42151__stavsounds__mechanical-keyboards"
mkdir -p "$OUTPUT/clicky"
i=1
for f in "$STAV"/*_clicky_*.ogg; do
    afconvert -f WAVE -d LEI16@44100 -c 1 "$f" "$OUTPUT/clicky/keydown_${i}.wav"
    i=$((i + 1))
done
echo "clicky: $((i - 1)) keydown"

# --- Tactile (StavSounds: 15 tactile samples, full keystroke as keydown) ---
mkdir -p "$OUTPUT/tactile"
i=1
for f in "$STAV"/*_tactile_*.ogg; do
    afconvert -f WAVE -d LEI16@44100 -c 1 "$f" "$OUTPUT/tactile/keydown_${i}.wav"
    i=$((i + 1))
done
echo "tactile: $((i - 1)) keydown"

echo "Done. Output in $OUTPUT"
