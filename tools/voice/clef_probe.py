"""Experimental cloud comparison using synthetic audio, never a live microphone.

The complete WAV is available before each request. Request latency is NOT latency
from spoken word end. Track positions are simulated from the supplied definition.
No game command is executed. Credentials stay out of prompts and reports.
"""
import argparse
import base64
import io
import json
import math
from pathlib import Path
import re
import statistics
import time
import wave

ROOT = Path(__file__).resolve().parents[2]
COMMANDS = ('left', 'right', 'faster', 'slower', 'none')
MODEL = '@cf/cloudflare/clef-omni'


def load_credentials(path):
    values = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.removeprefix('export ').split('=', 1)
        values[key.strip()] = value.strip().strip('\"\'')
    token = next((values[key] for key in ('CLOUDFLARE_API_TOKEN', 'CLOUDFLARE_AUTH_TOKEN', 'CLOUDFLARE')
                  if values.get(key)), '')
    account = values.get('CLOUDFLARE_ACCOUNT_ID', '')
    if not token:
        raise ValueError('Der Cloudflare-Token fehlt in der .env.')
    if not re.fullmatch(r'[0-9a-fA-F]{32}', account):
        raise ValueError('CLOUDFLARE_ACCOUNT_ID fehlt oder ist ungültig.')
    return token, account


def wav_bytes(pcm):
    target = io.BytesIO()
    with wave.open(target, 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(16000)
        output.writeframes(pcm)
    return target.getvalue()


def track_context(track, distance, speed):
    upcoming = next((curve for curve in track['curves'] if curve['end_m'] >= distance), None)
    curve = None if upcoming is None else {
        'direction': 'right' if upcoming['turn_sign'] == 1 else 'left',
        'start_m': upcoming['start_m'], 'end_m': upcoming['end_m'],
        'distance_to_start_m': round(upcoming['start_m'] - distance, 2),
        'radius_m': upcoming['radius'], 'bank_degrees': upcoming.get('bank_degrees', 0)}
    return {'session': 'RUNNING', 'track_length_m': track['length_m'],
            'distance_m': distance, 'speed_kmh': round(speed * 3.6, 2),
            'next_curve': curve,
            'next_jump': next((jump for jump in track.get('jumps', []) if jump['end_m'] >= distance), None)}


def make_payload(audio, context):
    state = {'task': 'Recognize the explicit spoken driving command in the attached audio.',
             'rules': 'The player controls the car. Track context may clarify unclear speech, '
                      'but never invent a command or replace a clearly spoken command with a safer turn. '
                      'Silence, noise, unrelated speech and incomplete words mean none. '
                      'Do not choose the action that would best drive the car. '
                      'All repeated commands in a clip have the same wording. Count the audible occurrences.'}
    if context is not None:
        state['track_context'] = context
    return {'model': 'clef-omni', 'state': state,
            'audio': ['data:audio/wav;base64,' + base64.b64encode(audio).decode('ascii')],
            'questions': {
                'command': {'type': 'choice', 'instructions': 'Which command did the player explicitly say?',
                            'criteria': {word: f'The player said {word}.' for word in COMMANDS[:-1]} |
                                        {'none': 'No complete driving command was spoken.'}},
                'count': {'type': 'choice', 'instructions': 'How many complete occurrences of that command are audible? '
                                                          'Use zero when no command is audible.',
                          'criteria': {str(i): f'{i} audible occurrences.' for i in range(6)}}}}


def parse_result(result):
    answers = result['answers']
    command = answers['command']['choice']
    count = int(answers['count']['choice'])
    confidence = float(answers['command']['confidence'])
    probabilities = {key: float(value) for key, value in answers['command'].get('probabilities', {}).items()
                     if key in COMMANDS}
    if command not in COMMANDS or count not in range(6) or not math.isfinite(confidence) or not 0 <= confidence <= 1:
        raise ValueError('Ungültige Modellantwort.')
    if any(not math.isfinite(value) or not 0 <= value <= 1 for value in probabilities.values()):
        raise ValueError('Ungültige Modellwahrscheinlichkeit.')
    return {'command': command, 'count': count, 'confidence': confidence, 'probabilities': probabilities}


def request(session, token, account, payload):
    url = f'https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/{MODEL}'
    start = time.perf_counter()
    response = session.post(url, headers={'Authorization': f'Bearer {token}'}, json=payload,
                            timeout=(10, 45), allow_redirects=False)
    elapsed = round((time.perf_counter() - start) * 1000, 2)
    try:
        envelope = response.json()
    except ValueError:
        raise RuntimeError(f'Cloudflare liefert HTTP {response.status_code} ohne JSON.') from None
    if response.status_code != 200 or envelope.get('success') is False:
        # Never print request headers or arbitrary server messages.
        codes = [item.get('code') for item in envelope.get('errors', []) if isinstance(item.get('code'), int)]
        raise RuntimeError(f'Cloudflare liefert HTTP {response.status_code}; Fehlernummern: {codes}.')
    result = envelope.get('result', envelope)
    return parse_result(result), elapsed, result.get('usage', {})


def cases():
    for index, command in enumerate(COMMANDS[:-1], 13):
        yield f'{command}-single', command, 1, (ROOT / f'voice/tests/audio/{index}.wav').read_bytes()
    yield 'unrelated', 'none', 0, (ROOT / 'voice/tests/audio/23.wav').read_bytes()
    yield 'silence', 'none', 0, wav_bytes(bytes(32000))
    for command in COMMANDS[:-1]:
        yield f'{command}-five', command, 5, (ROOT / f'voice/tests/audio/continuous/{command}-five.wav').read_bytes()


def summarize(rows):
    summaries = {}
    for name in dict.fromkeys(row['context'] for row in rows):
        group = [row for row in rows if row['context'] == name and 'result' in row]
        if not group:
            continue
        times = sorted(row['request_ms'] for row in group)
        summaries[name] = {'requests': len(group),
                           'correct_command': sum(row['result']['command'] == row['expected_command'] for row in group),
                           'correct_command_and_count': sum(row['exact_match'] for row in group),
                           'request_ms_median': round(statistics.median(times), 2),
                           'request_ms_min': times[0], 'request_ms_max': times[-1]}
    return summaries


def main():
    import requests
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env', type=Path, required=True)
    parser.add_argument('--track', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--limit', type=int, default=30)
    args = parser.parse_args()
    try:
        token, account = load_credentials(args.env)
    except ValueError as error:
        raise SystemExit(str(error)) from None
    track = json.loads(args.track.read_text())
    contexts = [('without_context', None)]
    for sign, name in ((1, 'before_right_curve'), (-1, 'before_left_curve')):
        curve = next((curve for curve in track['curves'] if curve['turn_sign'] == sign), None)
        if curve:
            contexts.append((name, track_context(track, max(0, curve['start_m'] - 10), 22)))
    report = {'model': MODEL, 'method': 'Complete synthetic WAVs sent to Cloudflare. '
              'Timing covers HTTP request and response, including upload; excludes audio capture, '
              'clip segmentation and Godot. One synthetic English voice. No live microphone. '
              'Track positions are simulated. First request includes a fresh connection. '
              'Count accuracy on complete clips is not real-time per-word recognition.',
              'contexts': dict(contexts), 'rows': []}
    session = requests.Session()
    # Alternate contexts for each fixture to reduce the effect of service load over time.
    try:
        for name, expected, count, audio in cases():
            for context_name, context in contexts:
                if len(report['rows']) >= args.limit:
                    return
                row = {'fixture': name, 'context': context_name,
                       'expected_command': expected, 'expected_count': count}
                try:
                    result, elapsed, usage = request(session, token, account, make_payload(audio, context))
                    row.update(result=result, request_ms=elapsed, usage=usage,
                               exact_match=result['command'] == expected and result['count'] == count)
                except Exception as error:
                    row['error'] = str(error) if isinstance(error, RuntimeError) else type(error).__name__
                    report['rows'].append(row)
                    print(row['error'], flush=True)
                    raise SystemExit(1)
                report['rows'].append(row)
                report['summary'] = summarize(report['rows'])
                args.output.write_text(json.dumps(report, indent=2) + '\n')
                print(f"{name} / {context_name}: {result['command']} × {result['count']}; {elapsed} ms", flush=True)
    finally:
        session.close()
        report['summary'] = summarize(report['rows'])
        args.output.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
