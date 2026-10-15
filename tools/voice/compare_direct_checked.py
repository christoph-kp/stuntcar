"""Replay identical synthetic English PCM in real time for both current modes."""
import argparse
from difflib import SequenceMatcher
import hashlib
import json
from pathlib import Path
import platform
import statistics
import sys
import time
import wave

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from voice.recognizer import EnglishRecognizer, MODEL_ROOT
from voice.streaming import StreamingRecognizer
import vosk

CORE = ('left', 'right', 'faster', 'slower')
AUDIO = ROOT / 'voice/tests/audio'


def stats(values):
    return ({'min_ms': round(min(values), 1), 'median_ms': round(statistics.median(values), 1),
             'max_ms': round(max(values), 1)} if values else None)


def cases():
    items = [{**item, 'timed': item['text'] in CORE} for item in json.loads((AUDIO / 'manifest.json').read_text())[13:]]
    items += [{**item, 'file': 'english/' + item['file'], 'timed': False}
              for item in json.loads((AUDIO / 'english/manifest.json').read_text())]
    items += [{'file': f'continuous/{word}-five.wav', 'text': f'{word} x5',
               'expected': word, 'count': 5, 'timed': True} for word in CORE]
    model = vosk.Model(str(MODEL_ROOT / 'vosk-model-small-en-us-0.15'))
    result = []
    for item in items:
        with wave.open(str(AUDIO / item['file']), 'rb') as source:
            if (source.getframerate(), source.getnchannels(), source.getsampwidth()) != (16000, 1, 2):
                raise ValueError(item['file'])
            pcm = bytes(16000) + source.readframes(source.getnframes()) + bytes(32000)
        expected = [item['expected']] * item.get('count', 1) if item['expected'] else []
        ends = []
        if item['timed']:
            word = item['expected']
            aligner = vosk.KaldiRecognizer(model, 16000, json.dumps([word, '[unk]']))
            aligner.SetWords(True)
            aligner.AcceptWaveform(pcm)
            words = json.loads(aligner.FinalResult()).get('result', [])
            if [entry['word'] for entry in words] != expected:
                raise RuntimeError('Invalid reference words: ' + item['file'])
            ends = [entry['end'] * 1000 for entry in words]
        result.append({**item, 'expected': expected, 'pcm': pcm, 'reference_word_ends_ms': ends,
                       'pcm_sha256': hashlib.sha256(pcm).hexdigest()})
    result.append({'file': 'silence', 'text': 'silence', 'expected': [], 'pcm': bytes(32000 * 3),
                   'timed': False, 'reference_word_ends_ms': [],
                   'pcm_sha256': hashlib.sha256(bytes(32000 * 3)).hexdigest()})
    return result


def measure(engine, items):
    records = []
    for item in items:
        stream = StreamingRecognizer(engine)
        events, costs = [], []
        pcm = item['pcm']
        start = time.monotonic()
        for offset in range(0, len(pcm), 1600):
            block = pcm[offset:offset + 1600]
            audio_ms = (offset + len(block)) / 32
            time.sleep(max(0, start + audio_ms / 1000 - time.monotonic()))
            before = time.monotonic()
            commands, _ = stream.feed(block)
            after = time.monotonic()
            costs.append((after - before) * 1000)
            events += [{'command': command['command'], 'text': command['text'],
                        'wall_ms': (after - start) * 1000, 'audio_ms': audio_ms} for command in commands]
        actual = [event['command'] for event in events]
        correct = actual == item['expected']
        extra, missing = [], []
        for tag, a, b, c, d in SequenceMatcher(a=item['expected'], b=actual, autojunk=False).get_opcodes():
            if tag in ('insert', 'replace'):
                extra += actual[c:d]
            if tag in ('delete', 'replace'):
                missing += item['expected'][a:b]
        records.append({key: value for key, value in item.items() if key != 'pcm'} | {
            'correct': correct, 'events': events, 'extra_commands': extra, 'missing_commands': missing,
            'delay_ms': [event['wall_ms'] - end for event, end in zip(events, item['reference_word_ends_ms'])]
                        if correct and item['timed'] else [],
            'feed_total_ms': sum(costs), 'feed_max_ms': max(costs)})
    return records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rounds', type=int, default=2)
    parser.add_argument('--output', type=Path, default=ROOT / 'docs/voice-direct-comparison.json')
    args = parser.parse_args()
    if args.rounds < 1:
        parser.error('--rounds must be at least 1')
    vosk.SetLogLevel(-1)
    items = cases()
    engines = {mode: EnglishRecognizer(mode=mode) for mode in ('direct', 'checked')}
    runs = {mode: [] for mode in engines}
    for iteration in range(args.rounds):
        order = list(engines) if iteration % 2 == 0 else list(reversed(engines))
        for mode in order:
            print(f'Durchlauf {iteration + 1}: {mode}', flush=True)
            runs[mode].append(measure(engines[mode], items))
    summary = {}
    for mode, rounds in runs.items():
        records = [record for run in rounds for record in run]
        summary[mode] = {
            'correct_cases': sum(record['correct'] for record in records), 'cases': len(records),
            'expected_commands': sum(len(record['expected']) for record in records),
            'emitted_commands': sum(len(record['events']) for record in records),
            'extra_commands': sum(len(record['extra_commands']) for record in records),
            'extra_driving_commands': sum(word in CORE for record in records for word in record['extra_commands']),
            'missing_commands': sum(len(record['missing_commands']) for record in records),
            'core_word_latency': stats([delay for record in records for delay in record['delay_ms']]),
            'feed_total_ms': round(sum(record['feed_total_ms'] for record in records), 1),
            'feed_max_ms': round(max(record['feed_max_ms'] for record in records), 1),
            'failed_files': sorted({record['file'] for record in records if not record['correct']})}
    checked_ok = {record['file'] for run in runs['checked'] for record in run if record['correct']}
    new_errors = sorted({record['file'] for run in runs['direct'] for record in run
                         if not record['correct'] and record['file'] in checked_ok})
    result = {
        'platform': platform.platform(), 'python': platform.python_version(), 'rounds': args.rounds,
        'method': 'Beide Modi erhalten identische Tondaten mit 16 kHz, einem Kanal und 16 Bit. Die Zufuhr erfolgt in Echtzeit mit Blöcken von 50 ms. Jede Datei erhält davor 500 ms Stille und danach 1000 ms Stille. Beide Modi nutzen dasselbe englische Modell mit Modellblöcken von 60 ms. Die Reihenfolge wechselt zwischen den Durchläufen. Die Zeitmessung beginnt nach der Rücksetzung des Erkenners. Sie enthält die Verarbeitung und die Zeitverteilung des Betriebssystems. Sie enthält keine Modellladezeit, Mikrofonlaufzeit, Verbindungslaufzeit, Godot-Verarbeitung, Anzeigezeit oder menschliche Reaktion. Alle Sprachdateien nutzen die künstliche Samantha-Stimme.',
        'reference': 'Eine gesonderte Vosk-Messung schätzt die Wortenden. Beide Modi nutzen dieselben Schätzwerte. Das Messmodell nutzt Modellblöcke von 240 ms und eine Wortliste mit einem Fahrwort. Die Messung enthält keine von Menschen bestimmten Wortgrenzen. Negative Zeitwerte entstehen, wenn ein Befehl vor dem geschätzten Wortende erscheint. Nur die vier einzelnen Fahrwörter und ihre Folgen mit fünf Wiederholungen zählen für die Zeitwerte. Diese Tondateien geben keine Zusage für eine Verbesserung bei echten Stimmen.',
        'summary': summary, 'new_direct_errors': new_errors, 'runs': runs}
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    lines = ['Vergleich der englischen Spracherkennung',
             f'Durchläufe je Modus: {args.rounds}. Fälle je Durchlauf: {len(items)}.',
             'Beide Modi erhalten dieselben Tondateien in Echtzeit mit Blöcken von 50 ms.',
             'Die Wortenden stammen aus einer gesonderten Vosk-Messung. Sie sind Schätzwerte.',
             'Die Zeitmessung enthält die Verarbeitung der Tonblöcke.',
             'Die Zeitmessung enthält keine Mikrofon-, Verbindungs- oder Bildschirmlaufzeit.',
             'Die Modellladezeit liegt außerhalb der Zeitmessung.',
             'Die Tondateien enthalten nur künstliche Sprache. Die Messung gibt keine allgemeine Zusage für echte Stimmen.',
             'Ein negativer Zeitwert bedeutet: Der Befehl erschien vor dem geschätzten Wortende.',
             'Der Median liegt an der mittleren Position aller sortierten Zeitwerte.',
             'Andere Programme können diese Werte verändern.', '']
    for mode, label in (('direct', 'Einzelprüfung'), ('checked', 'Gegenprüfung')):
        value = summary[mode]
        latency = value['core_word_latency']
        lines += [f'{label}: {value["correct_cases"]}/{value["cases"]} Fälle korrekt.',
                  f'Zusätzliche falsche Fahrbefehle: {value["extra_driving_commands"]}. Fehlende Befehle: {value["missing_commands"]}.',
                  f'Zeit ab geschätztem Wortende: Median {latency["median_ms"]} ms; Bereich {latency["min_ms"]} bis {latency["max_ms"]} ms.',
                  f'Fälle mit Fehlern: {", ".join(value["failed_files"]) or "keine"}.', '']
    lines += ['Neue Fehler der Einzelprüfung gegenüber der Gegenprüfung: ' + (', '.join(new_errors) or 'keine') + '.',
              'Der freie Erkenner hört „break“ statt „brake“ und „cause“ statt „pause“. Diese Wörter erzeugen keinen Befehl.',
              'Die Einzelprüfung hat keine zusätzliche Wartezeit von 50 ms. Die Gegenprüfung behält diese Wartezeit.',
              'Die Messung erlaubt keine Zusage für eine allgemeine Verbesserung.']
    args.output.with_suffix('.txt').write_text('\n'.join(lines) + '\n')
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == '__main__':
    main()
