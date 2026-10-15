"""Mode boundaries independent of speech model timing."""
from array import array
import json
from types import SimpleNamespace
import unittest

from voice.streaming import StreamingRecognizer, command_words


class Decoder:
    """Feed complete Vosk-shaped partial and final packets to the real stream."""
    def __init__(self):
        self.text = ''
        self.final = False

    def Reset(self):
        self.text = ''
        self.final = False

    def AcceptWaveform(self, pcm):
        return self.final

    def PartialResult(self):
        return json.dumps({'partial': self.text})

    def Result(self):
        self.final = False
        result = json.dumps({'text': self.text})
        self.text = ''
        return result

    def FinalResult(self):
        return json.dumps({'text': self.text})


class RecognitionModes(unittest.TestCase):
    def stream(self, mode):
        decoder = Decoder()
        fallback = Decoder()
        engine = SimpleNamespace(mode=mode, recognizers=[decoder],
                                 fallback_recognizers=[fallback] if mode == 'checked' else [],
                                 recognize=lambda pcm: (None, []))
        return StreamingRecognizer(engine), decoder, fallback

    def feed(self, stream, decoder, text, fallback=None):
        decoder.text = text
        if fallback:
            fallback.text = text
        return stream.feed(array('h', [1500] * 800).tobytes())

    def test_direct_acts_on_first_free_word_without_stability_wait(self):
        stream, decoder, _ = self.stream('direct')
        events, status = self.feed(stream, decoder, 'left')
        self.assertEqual([event['command'] for event in events], ['left'])
        self.assertEqual(status['direction'], 'left')
        self.assertEqual(events[0]['strength'], .5)

    def test_checked_keeps_stability_wait(self):
        stream, decoder, fallback = self.stream('checked')
        events, _ = self.feed(stream, decoder, 'left', fallback)
        self.assertEqual(events, [])
        events, _ = self.feed(stream, decoder, 'left', fallback)
        self.assertEqual([event['command'] for event in events], ['left'])

    def test_direct_emits_each_repeat_once_and_reset_discards_old_words(self):
        stream, decoder, _ = self.stream('direct')
        events = []
        for text in ('left', 'left', 'left left', 'left left right fast slower'):
            emitted, _ = self.feed(stream, decoder, text)
            events.extend(event['command'] for event in emitted)
        self.assertEqual(events, ['left', 'left', 'right', 'faster', 'slower'])
        stream.reset()
        events, _ = stream.feed(bytes(1600))
        self.assertEqual(events, [])
        events, _ = self.feed(stream, decoder, 'right')
        self.assertEqual([event['command'] for event in events], ['right'])

    def test_direct_menu_waits_for_utterance_end(self):
        stream, decoder, _ = self.stream('direct')
        events, _ = self.feed(stream, decoder, 'start')
        self.assertEqual(events, [])
        events = []
        for _ in range(6):
            emitted, _ = stream.feed(bytes(1600))
            events.extend(event['command'] for event in emitted)
        self.assertEqual(events, ['start'])

    def test_direct_rejects_full_unknown_text_including_previous_decoder_result(self):
        for text in ('not left', 'left turn', 'hello right', 'langsame', '[unk] left'):
            stream, decoder, _ = self.stream('direct')
            events, _ = self.feed(stream, decoder, text)
            self.assertEqual(events, [], text)
        stream, _, _ = self.stream('direct')
        # Cached command words must not hide unknown words in the full transcript.
        self.assertEqual(stream.confirmed([{'partial': 'not left', '_words': command_words('left')}]), [])


if __name__ == '__main__':
    unittest.main()
