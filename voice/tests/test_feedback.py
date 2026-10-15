"""The real English decoder attaches microphone strength to its commands."""
from array import array
from pathlib import Path
import unittest
import wave

from voice.recognizer import EnglishRecognizer
from voice.streaming import StreamingRecognizer

AUDIO = Path(__file__).parent / 'audio'


def speech_at_level(target):
    with wave.open(str(AUDIO / '13.wav'), 'rb') as source:
        samples = array('h', source.readframes(source.getnframes()))
    peak = max((sum(v * v for v in samples[i:i + 800]) / len(samples[i:i + 800])) ** .5
               for i in range(0, len(samples), 800))
    return array('h', (round(max(-32768, min(32767, v * target / peak))) for v in samples)).tobytes()


class VoiceFeedback(unittest.TestCase):
    mode = 'checked'

    @classmethod
    def setUpClass(cls):
        cls.engine = EnglishRecognizer(mode=cls.mode)

    def run_audio(self, pcm, stream=None):
        stream = stream or StreamingRecognizer(self.engine)
        events, feedback = [], []
        for offset in range(0, len(pcm), 1600):
            commands, status = stream.feed(pcm[offset:offset + 1600])
            events.extend(commands)
            feedback.append(status)
        return events, feedback

    def test_same_word_keeps_its_direction_and_has_three_distinct_strengths(self):
        strengths = []
        for level in (600, 1500, 3000):
            events, _ = self.run_audio(bytes(16000) + speech_at_level(level) + bytes(32000))
            self.assertEqual([e['command'] for e in events], ['left'])
            self.assertIn('strength', events[0])
            strengths.append(events[0]['strength'])
        self.assertLess(strengths[0], .34)
        self.assertGreaterEqual(strengths[1], .34)
        self.assertLess(strengths[1], .67)
        self.assertGreaterEqual(strengths[2], .67)

    def test_raw_levels_keep_loud_signals_distinct_above_old_limit(self):
        samples = array('h', [6000] * 800).tobytes()
        stream = StreamingRecognizer(self.engine)
        _, feedback = stream.feed(samples)
        self.assertAlmostEqual(feedback['rms'], 6000)
        self.assertAlmostEqual(feedback['peak_rms'], 6000)
        self.assertEqual(feedback['level'], 1.0)
        events, _ = self.run_audio(bytes(16000) + speech_at_level(6000) + bytes(32000))
        self.assertEqual([event['command'] for event in events], ['left'])
        self.assertGreater(events[0]['peak_rms'], 3000)

    def test_feedback_has_direction_only_for_confirmed_speech(self):
        events, feedback = self.run_audio(bytes(16000) + speech_at_level(1500) + bytes(32000))
        self.assertEqual(len(events), 1)
        self.assertTrue(any(f.get('direction') == 'left' for f in feedback))
        self.assertEqual(feedback[-1].get('direction'), '')
        with wave.open(str(AUDIO / 'english/not-left.wav'), 'rb') as source:
            unknown = source.readframes(source.getnframes())
        events, feedback = self.run_audio(unknown + bytes(32000))
        self.assertEqual(events, [])
        self.assertTrue(all(not f.get('direction') for f in feedback))

    def test_reset_discards_previous_loudness(self):
        stream = StreamingRecognizer(self.engine)
        self.run_audio(speech_at_level(3000) + bytes(32000), stream)
        stream.reset()
        events, _ = self.run_audio(bytes(16000) + speech_at_level(600) + bytes(32000), stream)
        self.assertEqual(len(events), 1)
        self.assertIn('strength', events[0])
        self.assertLess(events[0]['strength'], .34)


class DirectVoiceFeedback(VoiceFeedback):
    mode = 'direct'
