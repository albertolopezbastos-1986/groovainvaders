"""Genera tres efectos arcade originales, PCM mono de 16 bits, sin dependencias."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
DESTINATION = Path(__file__).parent


def write_effect(name, duration, start_hz, end_hz, explosion=False):
    rng = random.Random(1980)
    frames = round(duration * RATE)
    samples = []
    phase = 0.0
    noise = 0.0
    for i in range(frames):
        progress = i / (frames - 1)
        # Ataque y salida suaves para evitar clics al repetir los disparos.
        envelope = min(1.0, i / (RATE * 0.004)) * (1 - progress) ** 1.7
        frequency = start_hz * (end_hz / start_hz) ** progress
        phase += frequency / RATE
        pulse = 1.0 if phase % 1.0 < 0.25 else -1.0 / 3.0
        if explosion:
            if i % 5 == 0:
                noise = rng.uniform(-1, 1)
            signal = noise * 0.8 + pulse * 0.2
        else:
            signal = pulse * 0.65 + math.sin(phase * math.tau) * 0.35
        samples.append(round(signal * envelope * 0.55 * 32767))
    with wave.open(str(DESTINATION / name), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(struct.pack('<' + 'h' * len(samples), *samples))


if __name__ == '__main__':
    write_effect('player_shot.wav', 0.085, 1050, 380)
    write_effect('alien_shot.wav', 0.12, 440, 140)
    write_effect('alien_explosion.wav', 0.20, 180, 45, explosion=True)
