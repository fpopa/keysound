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

# --- Debug Click (synthetic sharp impulse) ---
python3 "$SCRIPT_DIR/generate-debug-click.py"

# --- Trim leading silence from all WAV files ---
echo "Trimming leading silence..."
python3 -c "
import os, struct, wave

def trim_silence(path, threshold_pct=5, runway=10):
    with wave.open(path, 'r') as wf:
        n = wf.getnframes()
        if n == 0: return
        raw = wf.readframes(n)
        params = wf.getparams()
    samples = struct.unpack(f'<{n}h', raw)
    peak = max(abs(s) for s in samples) if samples else 0
    if peak == 0: return
    threshold = peak * threshold_pct / 100
    first = 0
    for i, s in enumerate(samples):
        if abs(s) > threshold:
            first = max(0, i - runway)
            break
    if first == 0: return
    trimmed = samples[first:]
    with wave.open(path, 'w') as wf:
        wf.setparams(params)
        wf.writeframes(struct.pack(f'<{len(trimmed)}h', *trimmed))
    print(f'  trimmed {first} samples from {os.path.basename(path)}')

for root, dirs, files in os.walk('$OUTPUT'):
    for f in sorted(files):
        if f.endswith('.wav'):
            trim_silence(os.path.join(root, f))
"

echo "Done. Output in $OUTPUT"
