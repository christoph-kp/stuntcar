"""Compare English keyword spotting against the existing Vosk path.

This probe never opens a microphone. It feeds synthetic fixtures on a simulated
sample clock. Times exclude microphone, OS queues, decoder computation and Godot.
Missing repetitions fail the suitability gate; they never improve latency scores.
"""
import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
import platform
import statistics
import sys
import tempfile
import time
import wave

import numpy as np
import sherpa_onnx

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from voice.recognizer import BilingualRecognizer
from voice.streaming import StreamingRecognizer

WORDS = ('left', 'right', 'faster', 'slower')
CASES = [(f'{i + 13}.wav', [word]) for i, word in enumerate(WORDS)] + [
    (f'continuous/{word}-five.wav', [word] * 5) for word in WORDS
] + [('23.wav', [])]


def samples(path):
    with wave.open(str(path), 'rb') as source:
        if (source.getframerate(), source.getnchannels(), source.getsampwidth()) != (16000, 1, 2):
            raise ValueError(f'Unsupported fixture format: {path}')
        # Keep the same lead-in and tail for both engines.
        return bytes(16000) + source.readframes(source.getnframes()) + bytes(32000)


def run_case(pcm, expected, stream, block_frames, feed):
    events, costs = [], []
    block_bytes = block_frames * 2
    for offset in range(0, len(pcm), block_bytes):
        block = pcm[offset:offset + block_bytes]
        start = time.perf_counter()
        commands = feed(stream, block)
        costs.append((time.perf_counter() - start) * 1000)
        delivered_ms = (offset + len(block)) / 32
        events.extend({'command': command, 'audio_time_ms': round(delivered_ms, 2)} for command in commands)
    actual = [event['command'] for event in events]
    return {'expected': expected, 'events': events, 'exact_match': actual == expected,
            'decode_cost_median_ms': round(statistics.median(costs), 3),
            'decode_cost_max_ms': round(max(costs), 3)}


def keywords(model, phonetic):
    if phonetic:
        lexicon = dict(line.split(' ', 1) for line in (model / 'en.phone').read_text().splitlines())
        return '\n'.join(f'{lexicon[word.upper()]} @{word}' for word in WORDS) + '\n'
    import sentencepiece as spm
    tokenizer = spm.SentencePieceProcessor(model_file=str(model / 'bpe.model'))
    return '\n'.join(' '.join(tokenizer.encode(word.upper(), out_type=str)) + f' @{word}' for word in WORDS) + '\n'


def summary(records):
    repeated = [record for record in records if len(record['expected']) == 5]
    singles = [record for record in records if len(record['expected']) == 1]
    return {'exact_files': sum(record['exact_match'] for record in records),
            'files': len(records), 'repetition_expected': 20,
            'repetition_correct_commands': sum(sum(event['command'] == record['expected'][0]
                for event in record['events']) for record in repeated),
            'all_repetition_files_exact': all(record['exact_match'] for record in repeated),
            'single_word_times_ms': [record['events'][0]['audio_time_ms'] if record['exact_match'] else None
                                     for record in singles]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--english-model', type=Path, required=True)
    parser.add_argument('--small-chunk-model', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    fixtures = [(name, expected, samples(ROOT / 'voice/tests/audio' / name)) for name, expected in CASES]
    engine = BilingualRecognizer()
    baseline = []
    for name, expected, pcm in fixtures:
        record = run_case(pcm, expected, StreamingRecognizer(engine), 800,
                          lambda stream, block: [event['command'] for event in stream.feed(block)[0]])
        baseline.append({'file': name, **record})
    variants = []
    configs = [(args.english_model, False, 16, 1., .25, 1)] + [
        (args.small_chunk_model, True, 8, score, threshold, blanks)
        for score in (1., 2., 4.) for threshold in (.1, .25) for blanks in (0, 1)
    ]
    with tempfile.TemporaryDirectory(prefix='stuntcar-keywords-') as temporary:
        keyword_file = Path(temporary) / 'keywords.txt'
        for model, phonetic, chunk, score, threshold, blanks in configs:
            keyword_file.write_text(keywords(model, phonetic))
            epoch = 13 if phonetic else 12
            suffix = f'epoch-{epoch}-avg-2-chunk-{chunk}-left-64.onnx'
            spotter = sherpa_onnx.KeywordSpotter(tokens=str(model / 'tokens.txt'),
                encoder=str(model / f'encoder-{suffix}'), decoder=str(model / f'decoder-{suffix}'),
                joiner=str(model / f'joiner-{suffix}'), keywords_file=str(keyword_file),
                num_threads=1, keywords_score=score, keywords_threshold=threshold,
                num_trailing_blanks=blanks)

            def feed(stream, block):
                stream.accept_waveform(16000, np.frombuffer(block, dtype='<i2').astype(np.float32) / 32768)
                commands = []
                while spotter.is_ready(stream):
                    spotter.decode_stream(stream)
                    result = spotter.get_result(stream)
                    if result:
                        commands.append(result)
                        # The official API requires this reset after each hit.
                        spotter.reset_stream(stream)
                return commands

            records = [{'file': name, **run_case(pcm, expected, spotter.create_stream(), 320, feed)}
                       for name, expected, pcm in fixtures]
            variants.append({'model': model.name, 'chunk': chunk, 'score': score,
                             'threshold': threshold, 'trailing_blanks': blanks,
                             'summary': summary(records), 'records': records})
            print(model.name, score, threshold, blanks, summary(records), flush=True)
    report = {'method': 'Synthetic PCM, simulated sample clock; same 500 ms lead-in and 1000 ms tail. '
                       'Vosk receives 50 ms blocks, sherpa receives 20 ms blocks. '
                       'Audio times start at the lead-in, not at word end. '
                       'Excluded: microphone, OS queues, computation, transport, Godot. '
                       'Compute costs are measured separately. One synthetic English speaker. '
                       'Parameter search uses these fixtures; it is not an independent validation set.',
              'platform': platform.platform(), 'python': platform.python_version(),
              'versions': {package: importlib.metadata.version(package)
                           for package in ('sherpa-onnx', 'numpy', 'sentencepiece', 'vosk')},
              'keywords': WORDS,
              'fixture_sha256': {name: hashlib.sha256((ROOT / 'voice/tests/audio' / name).read_bytes()).hexdigest()
                                 for name, _, _ in fixtures},
              'baseline': {'summary': summary(baseline), 'records': baseline}, 'variants': variants,
              'decision': 'Do not replace Vosk: no tested sherpa configuration passes all fast repetitions.'}
    if any(item['summary']['all_repetition_files_exact'] for item in variants):
        report['decision'] = 'A configuration passes repetitions. Compare latency and independent real voices before integration.'
    args.output.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
