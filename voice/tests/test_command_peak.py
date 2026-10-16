"""Keep the spoken peak until recognition; never reuse it for the next command."""
from array import array
import json
from types import SimpleNamespace
import unittest

from voice.streaming import StreamingRecognizer
from voice.tests.test_modes import Decoder


class CommandPeak(unittest.TestCase):
    def stream(self, mode='direct'):
        decoders = [Decoder(), Decoder()] if mode == 'checked' else [Decoder()]
        engine = SimpleNamespace(mode=mode, recognizers=decoders[:1],
                                 fallback_recognizers=decoders[1:],
                                 recognize=lambda pcm: (None, []))
        return StreamingRecognizer(engine), decoders

    def feed(self, stream, decoders, level, text=''):
        for decoder in decoders:
            decoder.text = text
        return stream.feed(array('h', [level] * 800).tobytes())[0]

    def test_late_right_preserves_the_loud_onset_in_both_modes(self):
        # The report has a 5781 onset, then a 511 command peak after recognition.
        for mode in ('direct', 'checked'):
            with self.subTest(mode=mode):
                stream, decoders = self.stream(mode)
                self.assertEqual(self.feed(stream, decoders, 5781), [])
                for _ in range(11):
                    self.assertEqual(self.feed(stream, decoders, 511), [])
                events = self.feed(stream, decoders, 511, 'right')
                if mode == 'checked':
                    self.assertEqual(events, [])
                    events = self.feed(stream, decoders, 511, 'right')
                self.assertEqual([e['command'] for e in events], ['right'])
                self.assertEqual(events[0]['peak_rms'], 5781)

    def test_quiet_repeat_does_not_inherit_an_expired_loud_command(self):
        stream, decoders = self.stream()
        loud = self.feed(stream, decoders, 6000, 'left')
        self.assertEqual(loud[0]['peak_rms'], 6000)
        # A word can already start while the previous transcript is pending.
        # After the overlap window, a quiet repeat must use its own level.
        for _ in range(10): self.feed(stream, decoders, 500, 'left')
        quiet = self.feed(stream, decoders, 500, 'left left')
        self.assertEqual([e['command'] for e in quiet], ['left'])
        self.assertEqual(quiet[0]['peak_rms'], 500)
        self.assertLess(quiet[0]['strength'], .34)

    def test_one_partial_can_release_two_commands_without_an_empty_peak(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 6000)
        for _ in range(11): self.feed(stream, decoders, 700)
        events = self.feed(stream, decoders, 700, 'left right')
        self.assertEqual([e['command'] for e in events], ['left', 'right'])
        self.assertEqual([e['peak_rms'] for e in events], [6000, 6000])

    def test_final_only_command_preserves_the_spoken_peak(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 6000)
        for _ in range(11): self.feed(stream, decoders, 700)
        self.assertEqual(self.feed(stream, decoders, 700, 'start'), [])
        events = []
        for _ in range(6): events += self.feed(stream, decoders, 0, 'start')
        self.assertEqual([e['command'] for e in events], ['start'])
        self.assertEqual(events[0]['peak_rms'], 6000)

    def test_context_reset_discards_an_unassigned_loud_peak(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 6000)
        stream.reset()
        events = self.feed(stream, decoders, 500, 'left')
        self.assertEqual(events[0]['peak_rms'], 500)

    def test_rejected_utterance_does_not_change_the_next_command(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 6000, 'hello')
        for _ in range(6): self.feed(stream, decoders, 0, 'hello')
        events = self.feed(stream, decoders, 500, 'left')
        self.assertEqual(events[0]['peak_rms'], 500)

    def test_partial_and_final_commands_in_one_block_keep_the_same_signal(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 6000)
        decoders[0].FinalResult = lambda: json.dumps({'text': 'right'})
        decoders[0].final = True
        events = self.feed(stream, decoders, 700, 'left')
        self.assertEqual([e['command'] for e in events], ['left', 'right'])
        self.assertEqual([e['peak_rms'] for e in events], [6000, 6000])

    def test_loud_next_onset_survives_a_delayed_previous_transcript(self):
        stream, decoders = self.stream()
        self.feed(stream, decoders, 4000)
        first = self.feed(stream, decoders, 6000, 'left')
        second = self.feed(stream, decoders, 500, 'left left')
        self.assertEqual([e['peak_rms'] for e in first + second], [6000, 6000])
