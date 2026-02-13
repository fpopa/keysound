#!/usr/bin/env python3
"""Generate a sharp debug click WAV — ~20ms impulse with fast exponential decay."""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
DURATION_MS = 20
NUM_SAMPLES = int(SAMPLE_RATE * DURATION_MS / 1000)

output_dir = os.path.join(os.path.dirname(__file__), "..", "Resources", "sounds", "debug")
os.makedirs(output_dir, exist_ok=True)

samples = []
for i in range(NUM_SAMPLES):
    t = i / SAMPLE_RATE
    # Single-cycle impulse at ~4kHz + fast exponential decay
    decay = math.exp(-t * 300)
    sample = math.sin(2 * math.pi * 4000 * t) * decay
    samples.append(int(sample * 32767))

output_path = os.path.join(output_dir, "keydown_1.wav")
with wave.open(output_path, "w") as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(struct.pack(f"<{len(samples)}h", *samples))

print(f"debug: wrote {output_path} ({NUM_SAMPLES} samples, {DURATION_MS}ms)")
