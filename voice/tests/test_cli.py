"""The selected mode changes the real WAV command at the CLI boundary."""
import json
from pathlib import Path
import subprocess
import sys
import unittest

from voice.recognizer import EnglishRecognizer

ROOT = Path(__file__).resolve().parents[2]


class CommandLineMode(unittest.TestCase):
    def test_default_checked_and_explicit_modes_decode_the_same_audio(self):
        for mode, expected in ((None, ['slower', 'brake']), ('checked', ['slower', 'brake']), ('direct', None)):
            with self.subTest(mode=mode):
                command = [sys.executable, '-m', 'voice.recognizer', '--wav', str(ROOT / 'voice/tests/audio/17.wav')]
                if mode:
                    command += ['--mode', mode]
                result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=True)
                self.assertEqual(json.loads(result.stdout)['chosen'], expected)

    def test_invalid_mode_fails_before_loading_a_model(self):
        with self.assertRaises(ValueError):
            EnglishRecognizer(mode='unknown')
