#!/usr/bin/env python3
"""Generate mechanical keyboard WAV sounds using additive synthesis."""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
BITS_PER_SAMPLE = 16
MAX_AMP = 32767


def generate_samples(duration_s, components):
    """Generate audio samples from a list of component functions.

    Each component is a callable(t, duration) -> amplitude [-1.0, 1.0]
    """
    num_samples = int(SAMPLE_RATE * duration_s)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        value = sum(comp(t, duration_s) for comp in components)
        value = max(-1.0, min(1.0, value))
        samples.append(int(value * MAX_AMP))
    return samples


def noise_burst(attack_s, decay_s, amplitude):
    """White noise transient with fast attack and decay."""
    random.seed(42)  # Reproducible
    # Pre-generate noise
    noise_cache = [random.uniform(-1.0, 1.0) for _ in range(int(SAMPLE_RATE * (attack_s + decay_s + 0.01)))]

    def component(t, duration):
        if t > attack_s + decay_s:
            return 0.0
        idx = int(t * SAMPLE_RATE) % len(noise_cache)
        noise = noise_cache[idx]
        if t < attack_s:
            env = t / attack_s
        else:
            env = math.exp(-(t - attack_s) / (decay_s / 4))
        return noise * env * amplitude
    return component


def damped_sine(freq, attack_s, decay_s, amplitude):
    """Damped sine wave for click/thud components."""
    def component(t, duration):
        if t > attack_s + decay_s:
            return 0.0
        if t < attack_s:
            env = t / attack_s
        else:
            env = math.exp(-(t - attack_s) / (decay_s / 3))
        return math.sin(2 * math.pi * freq * t) * env * amplitude
    return component


def write_wav(filename, samples):
    """Write 16-bit mono WAV file."""
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        data = struct.pack(f'<{len(samples)}h', *samples)
        w.writeframes(data)


def generate_keydown():
    """Mechanical key press: noise transient + high click + low thud."""
    components = [
        noise_burst(attack_s=0.0005, decay_s=0.008, amplitude=0.5),
        damped_sine(freq=4000, attack_s=0.0003, decay_s=0.006, amplitude=0.4),
        damped_sine(freq=300, attack_s=0.001, decay_s=0.015, amplitude=0.3),
        damped_sine(freq=1200, attack_s=0.0005, decay_s=0.004, amplitude=0.15),
    ]
    return generate_samples(0.030, components)


def generate_keyup():
    """Key release: softer, higher pitched click."""
    components = [
        noise_burst(attack_s=0.0003, decay_s=0.005, amplitude=0.3),
        damped_sine(freq=5000, attack_s=0.0002, decay_s=0.004, amplitude=0.25),
        damped_sine(freq=1800, attack_s=0.0004, decay_s=0.003, amplitude=0.1),
    ]
    return generate_samples(0.020, components)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    resources_dir = os.path.join(script_dir, '..', 'Resources')
    os.makedirs(resources_dir, exist_ok=True)

    keydown_path = os.path.join(resources_dir, 'keydown.wav')
    keyup_path = os.path.join(resources_dir, 'keyup.wav')

    print("Generating keydown.wav...")
    keydown_samples = generate_keydown()
    write_wav(keydown_path, keydown_samples)
    print(f"  -> {keydown_path} ({len(keydown_samples)} samples, {len(keydown_samples)/SAMPLE_RATE*1000:.0f}ms)")

    print("Generating keyup.wav...")
    keyup_samples = generate_keyup()
    write_wav(keyup_path, keyup_samples)
    print(f"  -> {keyup_path} ({len(keyup_samples)} samples, {len(keyup_samples)/SAMPLE_RATE*1000:.0f}ms)")

    print("Done!")


if __name__ == '__main__':
    main()
