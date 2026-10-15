"""Measure command normalization without a speech model or microphone."""
import argparse
from pathlib import Path
from statistics import median
import sys
import timeit

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from voice.protocol import normalize_command


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--number', type=int, default=20000)
    parser.add_argument('--repeat', type=int, default=7)
    args = parser.parse_args()
    if args.number < 1 or args.repeat < 1:
        parser.error('--number and --repeat must be positive')
    cases = {
        'Exakte Wörter': ('left', 'right', 'fast', 'faster', 'slower'),
        'Ein Zeichen Abstand': ('lefft', 'light', 'fasst', 'faste', 'slowwer'),
        'Abgelehnte Wörter': ('hello', 'father', 'rigth', 'slwerr', 'nexxt'),
        'Abgelehnte Sätze': ('not light', 'light please', 'left turn'),
    }
    print('Nur der Wortabgleich; kein Sprachmodell und kein Mikrofon.')
    print(f'{args.repeat} Läufe mit {args.number} Wiederholungen je Wortgruppe.')
    for label, words in cases.items():
        def run():
            for word in words:
                normalize_command(word)
        samples = timeit.repeat(run, number=args.number, repeat=args.repeat)
        microseconds = median(samples) * 1e6 / (args.number * len(words))
        print(f'{label}: {microseconds:.3f} Mikrosekunden je Aufruf (Median).')


if __name__ == '__main__':
    main()
