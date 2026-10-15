"""English audio must keep confirmation, repetitions, and prompt responses."""
from array import array
import json
import math
from pathlib import Path
import unittest
from unittest.mock import patch
import wave

from voice import recognizer

AUDIO = Path(__file__).parent / 'audio'


def read_pcm(path):
    with wave.open(str(path), 'rb') as source:
        return source.readframes(source.getnframes())


class EnglishAudio(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = recognizer.EnglishRecognizer()

    def stream(self, pcm):
        stream = recognizer.StreamingRecognizer(self.engine)
        events = []
        pcm = bytes(16000) + pcm + bytes(32000)
        for offset in range(0, len(pcm), 1600):
            commands, _ = stream.feed(pcm[offset:offset + 1600])
            events.extend((offset / 32000 + .05, item['command']) for item in commands)
        return events

    def test_english_commands_and_unknown_speech(self):
        for item in json.loads((AUDIO / 'manifest.json').read_text())[13:]:
            with self.subTest(text=item['text']):
                events = self.stream(read_pcm(AUDIO / item['file']))
                self.assertEqual([command for _, command in events],
                                 [item['expected']] if item['expected'] else [])

    def test_negations_unknown_sentences_and_menu_commands(self):
        for item in json.loads((AUDIO / 'english/manifest.json').read_text()):
            with self.subTest(text=item['text']):
                events = self.stream(read_pcm(AUDIO / 'english' / item['file']))
                self.assertEqual([word for _, word in events],
                                 [item['expected']] if item['expected'] else [])

    def test_all_repeated_words_once_and_first_confirmation_sooner(self):
        for command in ('left', 'right', 'faster', 'slower'):
            with self.subTest(command=command):
                events = self.stream(read_pcm(AUDIO / 'continuous' / (command + '-five.wav')))
                self.assertEqual([word for _, word in events], [command] * 5)
                # Includes 500 ms leading silence; old pipeline needs 1100-1300 ms.
                if command in ('left', 'right'):
                    self.assertLess(events[0][0], 1.1)

    def test_background_and_silence_do_not_hide_or_repeat_words(self):
        word = read_pcm(AUDIO / '13.wav')
        pcm = word + bytes(32000) + word + bytes(64000)
        samples = array('h', pcm)
        for index, value in enumerate(samples):
            samples[index] = max(-32768, min(32767, value + round(500 * math.sin(2 * math.pi * 60 * index / 16000))))
        self.assertEqual([word for _, word in self.stream(samples.tobytes())], ['left', 'left'])
        self.assertEqual([word for _, word in self.stream(word + bytes(160000))], ['left'])

    def test_reset_discards_incomplete_command(self):
        stream = recognizer.StreamingRecognizer(self.engine)
        pcm = read_pcm(AUDIO / 'continuous/left-five.wav')[:6400]
        stream.feed(pcm)
        stream.reset()
        events = []
        for _ in range(30):
            commands, _ = stream.feed(bytes(1600))
            events.extend(commands)
        self.assertEqual(events, [])

    def test_model_configuration_stays_unchanged(self):
        path = recognizer.MODEL_ROOT / 'vosk-model-small-en-us-0.15/conf/model.conf'
        before = path.read_bytes()
        # An English-only installation must never try to open the German model.
        original = recognizer.MODEL_ROOT
        class EnglishRoot:
            def __truediv__(self, name):
                if 'en-us' not in name:
                    raise AssertionError('German model requested')
                return original / name
        with patch.object(recognizer, 'MODEL_ROOT', EnglishRoot()):
            engine = recognizer.EnglishRecognizer()
            self.assertEqual(len(engine.recognizers), 1)
            self.assertEqual(len(engine.fallback_recognizers), 1)
        self.assertEqual(path.read_bytes(), before)
