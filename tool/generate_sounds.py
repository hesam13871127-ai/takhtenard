#!/usr/bin/env python3
"""Generates all sound effects for Takhteh Nard as offline WAV assets.

The script is fully deterministic (seeded RNG) and uses only the Python
standard library so it can be re-run anywhere:

    python3 tool/generate_sounds.py

Output: assets/sounds/*.wav (44.1 kHz, 16-bit, mono — small and lossless).
"""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sounds"

# Deterministic RNG so re-running the script produces identical files.
RNG = random.Random(20240828)


def seconds(n: float) -> int:
    return int(n * SAMPLE_RATE)


def silence(duration: float) -> list[float]:
    return [0.0] * seconds(duration)


def mix(base: list[float], overlay: list[float], at: float = 0.0,
        gain: float = 1.0) -> list[float]:
    offset = seconds(at)
    need = offset + len(overlay)
    if need > len(base):
        base.extend([0.0] * (need - len(base)))
    for i, sample in enumerate(overlay):
        base[offset + i] += sample * gain
    return base


def sine(freq: float, duration: float, amplitude: float = 1.0,
         attack: float = 0.004, decay: float = 0.08) -> list[float]:
    """A soft sine ping with exponential decay and tiny attack."""
    n = seconds(duration)
    out = [0.0] * n
    att = max(1, seconds(attack))
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0 - math.exp(-t / decay)
        env *= math.exp(-t / decay * 3.2)
        if i < att:
            env *= i / att
        out[i] = amplitude * env * math.sin(2 * math.pi * freq * t)
    return out


def bell(freq: float, duration: float, amplitude: float = 1.0) -> list[float]:
    """A warm bell-like tone with a couple of harmonics."""
    n = seconds(duration)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 3.0)
        attack = min(1.0, t / 0.003)
        value = (
            math.sin(2 * math.pi * freq * t)
            + 0.42 * math.sin(2 * math.pi * freq * 2.0 * t)
            * math.exp(-t * 4.5)
            + 0.18 * math.sin(2 * math.pi * freq * 3.0 * t)
            * math.exp(-t * 6.0)
        )
        out[i] = amplitude * env * attack * value * 0.6
    return out


def noise_burst(duration: float, amplitude: float = 1.0,
                decay: float = 0.02) -> list[float]:
    n = seconds(duration)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t / decay)
        out[i] = amplitude * env * (RNG.random() * 2.0 - 1.0)
    return out


def lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    """Simple one-pole low-pass filter."""
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    alpha = dt / (rc + dt)
    out = [0.0] * len(samples)
    y = 0.0
    for i, x in enumerate(samples):
        y += alpha * (x - y)
        out[i] = y
    return out


def highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    low = lowpass(samples, cutoff_hz)
    return [s - l for s, l in zip(samples, low)]


def wood_knock(freq_low: float, freq_high: float, duration: float,
               amplitude: float, noise_amount: float = 0.35) -> list[float]:
    """A wooden knock: two slightly detuned decaying sines + click noise."""
    body = [0.0] * seconds(duration)
    for f, amp in ((freq_low, 1.0), (freq_high, 0.55)):
        body = mix(body, sine(f, duration, amplitude=amp, decay=duration / 3),
                   0.0)
    click = lowpass(noise_burst(0.03, amplitude * noise_amount, 0.004), 3200)
    return mix(body, click)


def normalize(samples: list[float], peak: float = 0.86) -> list[float]:
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    return [s * k for s in samples]


def fade_edges(samples: list[float], fade_in: float = 0.004,
               fade_out: float = 0.03) -> list[float]:
    n_in, n_out = seconds(fade_in), seconds(fade_out)
    n = len(samples)
    out = list(samples)
    for i in range(min(n_in, n)):
        out[i] *= i / n_in
    for i in range(min(n_out, n)):
        out[n - 1 - i] *= i / n_out
    return out


def write_wav(name: str, samples: list[float]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    data = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767))
        for s in samples
    )
    with wave.open(str(OUTPUT_DIR / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(data)
    print(f"wrote {name} ({len(samples) / SAMPLE_RATE:.2f}s)")


# ----------------------------------------------------------------------
# Individual effects
# ----------------------------------------------------------------------

def make_click() -> list[float]:
    out = silence(0.09)
    out = mix(out, sine(1900, 0.07, 0.7, decay=0.016), 0.0)
    out = mix(out, lowpass(noise_burst(0.012, 0.5, 0.003), 5000), 0.0)
    return normalize(out, 0.5)


def make_dice_roll() -> list[float]:
    """A cup-free dice rattle: a burst of clacks that decelerates."""
    total = silence(1.0)
    t = 0.0
    step = 0.055
    amp = 1.0
    while t < 0.62:
        pitch = 1.0 + RNG.uniform(-0.16, 0.16)
        clack = wood_knock(980 * pitch, 1560 * pitch, 0.085, amp * 0.9)
        total = mix(total, clack, t, gain=RNG.uniform(0.75, 1.0))
        t += step
        step *= 1.13  # Clacks get sparser, like dice settling.
        amp *= 0.93
    # Final settle knock.
    total = mix(total, wood_knock(760, 1210, 0.16, 0.85), t + 0.05)
    return normalize(total, 0.8)


def make_piece_move() -> list[float]:
    """A single soft wooden checker being placed."""
    out = silence(0.24)
    out = mix(out, wood_knock(165, 255, 0.16, 0.9, noise_amount=0.22), 0.0)
    out = mix(out, lowpass(noise_burst(0.02, 0.16, 0.005), 2400), 0.0)
    return normalize(out, 0.62)


def make_piece_hit() -> list[float]:
    """A hit: two quick, sharper knocks."""
    out = silence(0.34)
    out = mix(out, wood_knock(230, 360, 0.13, 1.0, noise_amount=0.5), 0.0)
    out = mix(out, wood_knock(190, 300, 0.18, 0.85, noise_amount=0.4), 0.105)
    return normalize(out, 0.78)


def make_reenter() -> list[float]:
    """Re-entering from the bar: a short slide and a landing tap."""
    out = silence(0.28)
    slide_noise = highpass(lowpass(noise_burst(0.16, 0.5, 0.09), 2600), 500)
    out = mix(out, slide_noise, 0.0, gain=0.5)
    out = mix(out, wood_knock(200, 330, 0.14, 0.95), 0.13)
    return normalize(out, 0.66)


def make_bear_off() -> list[float]:
    """Sliding a checker into the tray: roll + soft thock."""
    out = silence(0.4)
    roll_noise = lowpass(noise_burst(0.24, 0.55, 0.13), 1700)
    out = mix(out, roll_noise, 0.0, gain=0.8)
    out = mix(out, wood_knock(140, 225, 0.2, 1.0, noise_amount=0.3), 0.2)
    return normalize(out, 0.7)


def make_turn_change() -> list[float]:
    """A gentle two-note cue for the turn passing."""
    out = silence(0.42)
    out = mix(out, bell(392.0, 0.30, 0.55), 0.0)
    out = mix(out, bell(523.25, 0.34, 0.6), 0.12)
    return normalize(out, 0.5)


def make_win() -> list[float]:
    """A warm ascending fanfare."""
    out = silence(1.9)
    notes = [
        (293.66, 0.0),   # D4
        (369.99, 0.16),  # F#4
        (440.0, 0.32),   # A4
        (587.33, 0.48),  # D5
    ]
    for freq, at in notes:
        out = mix(out, bell(freq, 0.85, 0.8), at)
    # Soft shimmering chord underneath.
    out = mix(out, bell(587.33, 1.2, 0.28), 0.62)
    out = mix(out, bell(739.99, 1.2, 0.2), 0.66)
    return normalize(out, 0.82)


def make_lose() -> list[float]:
    """A gentle descending motif for a lost game."""
    out = silence(1.7)
    notes = [
        (440.0, 0.0),    # A4
        (349.23, 0.22),  # F4
        (293.66, 0.44),  # D4
        (220.0, 0.66),   # A3
    ]
    for freq, at in notes:
        out = mix(out, bell(freq, 0.75, 0.6), at)
    return normalize(out, 0.6)


def main() -> None:
    write_wav("click.wav", fade_edges(make_click()))
    write_wav("dice_roll.wav", fade_edges(make_dice_roll()))
    write_wav("piece_move.wav", fade_edges(make_piece_move()))
    write_wav("piece_hit.wav", fade_edges(make_piece_hit()))
    write_wav("reenter.wav", fade_edges(make_reenter()))
    write_wav("bear_off.wav", fade_edges(make_bear_off()))
    write_wav("turn_change.wav", fade_edges(make_turn_change()))
    write_wav("win.wav", fade_edges(make_win(), fade_out=0.08))
    write_wav("lose.wav", fade_edges(make_lose(), fade_out=0.08))
    print("done.")


if __name__ == "__main__":
    main()
