"""Real audio regressions: repeated directions must act before the utterance ends."""
from array import array
import math
import json
from pathlib import Path
import unittest
import wave

from voice import recognizer
from voice.streaming import command_words

AUDIO = Path(__file__).parent / 'audio'


def read_pcm(path):
    with wave.open(str(path), 'rb') as source:
        return source.readframes(source.getnframes())


class StreamingAudio(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = recognizer.BilingualRecognizer()

    def stream(self, pcm):
        stream_type = getattr(recognizer, 'StreamingRecognizer', None)
        self.assertIsNotNone(stream_type, 'Die laufende Erkennung fehlt; Wiederholungen brauchen einzelne Befehle.')
        stream = stream_type(self.engine)
        events = []
        feedback = []
        for offset in range(0, len(pcm) + 32000, 1600):
            block = pcm[offset:offset + 1600] if offset < len(pcm) else bytes(1600)
            commands, status = stream.feed(block)
            events.extend((offset / 32000 + .05, item) for item in commands)
            feedback.append(status)
        return events, feedback

    def test_five_fast_words_act_during_speech_once_each(self):
        pcm = read_pcm(AUDIO / 'continuous/links-five.wav')
        events, feedback = self.stream(pcm)
        self.assertEqual([event['command'] for _, event in events], ['left'] * 5)
        self.assertLess(events[0][0], len(pcm) / 32000 - .5)
        self.assertTrue(any(item['heard'] for item in feedback))
        self.assertTrue(any(item['level'] > 0 for item in feedback))

    def test_continuous_directions_and_long_repetitions(self):
        cases = {
            'rechts-five': ['right'] * 5,
            'mixed': ['left', 'left', 'right', 'right', 'left'],
            'left-five': ['left'] * 5,
            'right-five': ['right'] * 5,
            'links-fast': ['left'] * 5,
            'links-long': ['left'] * 15,
            'schneller-five': ['faster'] * 5,
            'langsamer-five': ['slower'] * 5,
            'speed-mixed': ['faster', 'faster', 'slower', 'slower'],
            'speed-fast': ['faster', 'faster', 'slower', 'slower'],
            'faster-five': ['faster'] * 5,
            'slower-five': ['slower'] * 5,
        }
        for name, expected in cases.items():
            with self.subTest(name=name):
                events, _ = self.stream(read_pcm(AUDIO / 'continuous' / (name + '.wav')))
                self.assertEqual([event['command'] for _, event in events], expected)

    def test_existing_commands_and_unknown_phrases(self):
        for item in json.loads((AUDIO / 'manifest.json').read_text()):
            with self.subTest(text=item['text']):
                events, _ = self.stream(read_pcm(AUDIO / item['file']))
                self.assertEqual([event['command'] for _, event in events],
                                 [item['expected']] if item['expected'] else [])

    def test_background_sound_does_not_hide_the_next_word(self):
        word = read_pcm(AUDIO / '0.wav')
        cases = [(word, ['left', 'left']), (read_pcm(AUDIO / '12.wav'), ['left'])]
        for first, expected in cases:
            with self.subTest(expected=expected):
                pcm = first + bytes(32000) + word + bytes(64000)
                samples = array('h', pcm)
                for index, value in enumerate(samples):
                    samples[index] = max(-32768, min(32767, value + round(500 * math.sin(2 * math.pi * 60 * index / 16000))))
                events, _ = self.stream(samples.tobytes())
                self.assertEqual([event['command'] for _, event in events], expected)

    def test_acoustic_variant_cannot_act_without_matching_command(self):
        self.assertEqual(command_words('langsame'), [])
        stream = recognizer.StreamingRecognizer(self.engine)
        variant = command_words('langsame', confirmation=True)
        results = [{'_words': command_words('schneller')}, {'_words': []},
                   {'_words': variant}, {'_words': []}]
        self.assertEqual(stream.confirmed(results), [])
        results[0]['_words'] = command_words('langsamer')
        self.assertEqual([word['command'] for word in stream.confirmed(results)], ['slower'])
        self.assertEqual(command_words('nicht langsame', confirmation=True), [])

    def test_silence_does_not_repeat_last_command(self):
        events, _ = self.stream(read_pcm(AUDIO / '0.wav') + bytes(32000 * 5))
        self.assertEqual([event['command'] for _, event in events], ['left'])
