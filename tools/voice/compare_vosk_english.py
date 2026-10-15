"""Replay identical English PCM at microphone speed against a fixed Git baseline."""
import argparse
import importlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import sys
import tempfile
import time
import wave

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from voice import recognizer
import vosk

BASELINE = 'b20d7bb'
CASES = [(f'{13 + i}.wav', word, 1) for i, word in enumerate(('left', 'right', 'faster', 'slower'))]
CASES += [(f'continuous/{word}-five.wav', word, 5) for word in ('left', 'right', 'faster', 'slower')]


def stats(values):
    return {'min_ms': round(min(values), 1), 'median_ms': round(statistics.median(values), 1),
            'max_ms': round(max(values), 1)}


def measure(engine, stream_class, cases):
    records = []
    for file, command, count, pcm, ends in cases:
        stream = stream_class(engine)
        start = time.monotonic()
        events, costs = [], []
        for offset in range(0, len(pcm), 1600):
            block = pcm[offset:offset + 1600]
            due = start + (offset + len(block)) / 32000
            time.sleep(max(0, due - time.monotonic()))
            before = time.monotonic()
            commands, _ = stream.feed(block)
            after = time.monotonic()
            costs.append((after - before) * 1000)
            events.extend({'command': item['command'], 'wall_ms': (after - start) * 1000,
                           'audio_ms': (offset + len(block)) / 32} for item in commands)
        correct = [event['command'] for event in events] == [command] * count
        records.append({'file': file, 'expected': [command] * count, 'correct': correct,
                        'estimated_word_ends_ms': [end * 1000 for end in ends], 'events': events,
                        'delay_ms': [(event['wall_ms'] - end * 1000) for event, end in zip(events, ends)] if correct else None,
                        'feed_total_ms': sum(costs), 'feed_max_ms': max(costs)})
    return records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'docs/vosk-english-latency.json')
    parser.add_argument('--rounds', type=int, default=2)
    args = parser.parse_args()
    if args.rounds < 1:
        parser.error('--rounds muss mindestens 1 sein')
    vosk.SetLogLevel(-1)
    model = vosk.Model(str(recognizer.MODEL_ROOT / 'vosk-model-small-en-us-0.15'))
    cases = []
    for file, word, count in CASES:
        with wave.open(str(ROOT / 'voice/tests/audio' / file), 'rb') as source:
            assert (source.getframerate(), source.getnchannels(), source.getsampwidth()) == (16000, 1, 2)
            pcm = bytes(16000) + source.readframes(source.getnframes()) + bytes(32000)
        aligner = vosk.KaldiRecognizer(model, 16000, json.dumps([word, '[unk]']))
        aligner.SetWords(True)
        aligner.AcceptWaveform(pcm)
        words = json.loads(aligner.FinalResult()).get('result', [])
        if [item['word'] for item in words] != [word] * count:
            raise RuntimeError(f'Ungültige Wortzeiten: {file}')
        cases.append((file, word, count, pcm, [item['end'] for item in words]))
    with tempfile.TemporaryDirectory(prefix='stuntcar-baseline-') as folder:
        package = Path(folder) / 'baseline_voice'
        package.mkdir()
        (package / '__init__.py').write_text('')
        for name in ('recognizer.py', 'streaming.py', 'protocol.py'):
            source = subprocess.check_output(['git', 'show', f'{BASELINE}:voice/{name}'], cwd=ROOT)
            (package / name).write_bytes(source)
        sys.path.insert(0, folder)
        baseline = importlib.import_module('baseline_voice.recognizer')
        baseline.MODEL_ROOT = recognizer.MODEL_ROOT
        modes = {
            'bilingual_before': (baseline.BilingualRecognizer(), baseline.StreamingRecognizer),
            'english_default_chunks': (recognizer.BilingualRecognizer(languages=('en-us',)), recognizer.StreamingRecognizer),
            'english_short_chunks': (recognizer.EnglishRecognizer(), recognizer.StreamingRecognizer),
        }
        runs = {mode: [] for mode in modes}
        for iteration in range(args.rounds):
            order = list(modes) if iteration % 2 == 0 else list(reversed(modes))
            for mode in order:
                print(f'Durchlauf {iteration + 1}: {mode}', flush=True)
                engine, stream_class = modes[mode]
                runs[mode].append(measure(engine, stream_class, cases))
    summary = {}
    for mode, rounds in runs.items():
        records = [record for run in rounds for record in run]
        correct = all(record['correct'] for record in records)
        summary[mode] = {'all_correct': correct, 'expected_words': sum(len(r['expected']) for r in records),
                         'emitted_words': sum(len(r['events']) for r in records),
                         'latency': stats([delay for r in records for delay in r['delay_ms']]) if correct else None,
                         'feed_total_ms': round(sum(r['feed_total_ms'] for r in records), 1),
                         'feed_max_ms': round(max(r['feed_max_ms'] for r in records), 1)}
    result = {'baseline_commit': BASELINE, 'platform': platform.platform(), 'python': platform.python_version(),
              'method': '50 ms real-time PCM blocks, 500 ms leading silence, 1000 ms trailing silence; includes elapsed time in recognition; excludes microphone, TCP and Godot; model-estimated word ends; synthetic Samantha voice',
              'rounds': args.rounds, 'summary': summary, 'runs': runs}
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(summary, indent=2), flush=True)
    if not all(item['all_correct'] for item in summary.values()):
        raise SystemExit('Nicht alle Befehle stimmen; kein gültiger Zeitvergleich.')


if __name__ == '__main__':
    main()
