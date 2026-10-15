"""Prepare licensed recordings. Requires ffmpeg; uses only the Python standard library."""
from array import array
from pathlib import Path
import json
import math
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/audio'
FFMPEG = shutil.which('ffmpeg')
RATE = 44100
report = {}


def prepare(name, source, start, duration, filters, crossfade=0.0, channels=1):
    data = subprocess.check_output([
        FFMPEG, '-v', 'error', '-ss', str(start), '-i', str(DEST / 'source' / source),
        '-t', str(duration), '-af', filters, '-ar', str(RATE), '-ac', str(channels),
        '-f', 'f32le', '-'])
    samples = array('f', data)
    count = int(crossfade * RATE) * channels
    if count:
        # The tail joins the head. The next repetition starts after the blended head.
        blend = array('f')
        for i in range(count):
            amount = (i // channels) / (count // channels - 1)
            blend.append(samples[-count + i] * (1 - amount) + samples[i] * amount)
        samples = samples[count:-count] + blend
    peak = max(abs(v) for v in samples)
    scale = 0.7 / peak
    samples = array('f', (v * scale for v in samples))
    subprocess.run([FFMPEG, '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE),
                    '-ac', str(channels), '-i', '-', '-c:a', 'libvorbis', '-q:a', '5',
                    str(DEST / (name + '.ogg'))], input=samples.tobytes(), check=True)
    report[name] = {'source': source, 'start_s': start, 'source_duration_s': duration,
                    'crossfade_s': crossfade, 'filters': filters,
                    'duration_s': round(len(samples) / channels / RATE, 3),
                    'peak_before_encode': 0.7}


prepare('engine', 'car_engine_qubodup.wav', 0, 4, 'highpass=f=60,lowpass=f=6000', 0.05)
prepare('forest', 'forest_birds.mp3', 2, 28, 'highpass=f=180,lowpass=f=10000', 1.5, 2)
prepare('wind', 'wind.ogg', 0, 8, 'highpass=f=150,lowpass=f=6000', 0.4)
prepare('road', 'wind.ogg', 0, 8, 'highpass=f=65,lowpass=f=350', 0.4)
prepare('landing', 'impact_soft.ogg', 0, 2, 'lowpass=f=2000,apad=pad_dur=0.15')
prepare('suspension', 'impact_metal.ogg', 0, 2, 'lowpass=f=2600,apad=pad_dur=0.15')
(DEST / 'processing.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
