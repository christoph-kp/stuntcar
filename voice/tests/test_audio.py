"""Synthetic speech only; these fixtures contain no microphone recordings."""
import json
from pathlib import Path
import unittest
import wave

from voice.recognizer import BilingualRecognizer, Segmenter

class AudioCommands(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = BilingualRecognizer()

    def test_bilingual_audio_and_unknown_phrases(self):
        folder = Path(__file__).parent / 'audio'
        for item in json.loads((folder / 'manifest.json').read_text()):
            with self.subTest(text=item['text']):
                with wave.open(str(folder / item['file']), 'rb') as source:
                    pcm = source.readframes(source.getnframes())
                segmenter = Segmenter()
                commands = []
                for offset in range(0, len(pcm) + 16000, 1600):
                    block = pcm[offset:offset + 1600] if offset < len(pcm) else bytes(1600)
                    segment, _ = segmenter.feed(block)
                    if segment:
                        chosen, _ = self.engine.recognize(segment)
                        if chosen:
                            commands.append(chosen[0])
                self.assertEqual(commands, [item['expected']] if item['expected'] else [])

    def test_silence_does_not_make_commands(self):
        segmenter = Segmenter()
        for _ in range(200):
            segment, _ = segmenter.feed(bytes(1600))
            self.assertIsNone(segment)

    def test_repeated_words_are_separate_commands(self):
        folder = Path(__file__).parent / 'audio'
        with wave.open(str(folder / '0.wav'), 'rb') as source:
            word = source.readframes(source.getnframes())
        pcm = bytes(6400) + word + bytes(16000) + word + bytes(16000)
        segmenter = Segmenter()
        commands = []
        for offset in range(0, len(pcm), 1600):
            segment, _ = segmenter.feed(pcm[offset:offset+1600])
            if segment:
                chosen, _ = self.engine.recognize(segment)
                if chosen: commands.append(chosen[0])
        self.assertEqual(commands, ['left', 'left'])
