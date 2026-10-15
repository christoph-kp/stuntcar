import unittest
from voice.protocol import normalize_command, choose_command


class Commands(unittest.TestCase):
    def test_aliases(self):
        groups = {
            'left': ['links', 'left'], 'right': ['rechts', 'right'],
            'faster': ['schneller', 'gas', 'gas geben', 'fast', 'faster', 'accelerate', 'throttle'],
            'slower': ['langsamer', 'bremsen', 'bremse', 'slower', 'brake', 'brakes'],
            'pause': ['pause'], 'resume': ['weiter', 'continue', 'resume'],
            'next': ['nächstes', 'next'], 'select': ['wählen', 'select'], 'start': ['start', 'starten'],
        }
        for command, aliases in groups.items():
            for word in aliases:
                with self.subTest(word=word):
                    self.assertEqual(normalize_command(word.upper() + '!'), command)

    def test_unknown_and_sentences_do_not_steer(self):
        for text in ['', 'hello', '[unk]', 'nicht links', 'links rechts', 'bitte bremsen', 'left turn']:
            self.assertIsNone(normalize_command(text))

    def result(self, text, confidence):
        return {'text': text, 'result': [{'word': text, 'conf': confidence}]}

    def test_languages_agree_emit_once(self):
        self.assertEqual(choose_command([self.result('gas', .95), self.result('faster', .98)]), ('faster', 'faster'))

    def test_conflict_or_uncertain_is_rejected(self):
        self.assertIsNone(choose_command([self.result('links', .9), self.result('right', .92)]))
        self.assertIsNone(choose_command([self.result('links', .4)]))

    def test_clear_language_wins(self):
        self.assertEqual(choose_command([self.result('links', .97), self.result('right', .5)]), ('left', 'links'))

if __name__ == '__main__':
    unittest.main()
