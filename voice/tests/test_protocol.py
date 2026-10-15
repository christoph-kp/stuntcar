import unittest
from unittest.mock import patch
import voice.protocol as protocol
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

    def test_single_edit_english_driving_words(self):
        variants = {
            'lefft': 'left', 'lift': 'left', 'light': 'right',
            'righht': 'right', 'fasst': 'faster', 'fastter': 'faster',
            'slowwer': 'slower', 'slwer': 'slower',
        }
        for word, command in variants.items():
            with self.subTest(word=word):
                self.assertEqual(normalize_command(word.upper() + '!'), command)

    def test_close_words_for_same_command_are_not_ambiguous(self):
        # "faste" is one edit from both "fast" and "faster".
        self.assertEqual(normalize_command('faste'), 'faster')

    def test_exact_alias_takes_priority_over_close_driving_word(self):
        with patch.dict(protocol.ALIASES, {'faste': 'pause'}):
            self.assertEqual(normalize_command('faste'), 'pause')

    def test_close_words_for_different_commands_are_ambiguous(self):
        # Current commands have no cross-command tie within one edit.
        # This vocabulary also checks rejection if future commands overlap.
        with patch.object(protocol, 'DRIVING_WORDS',
                          {'left': 'left', 'lest': 'right'}, create=True):
            self.assertIsNone(normalize_command('lent'))

    def test_only_one_edit_and_four_ascii_letters_can_match(self):
        for text in ('lef', 'fst', 'ast', 'fäst', 'fast1', 'lefftish',
                     'lftt', 'rigth', 'slwerr', 'fasste', 'fosterr', '[light]', 'light/right'):
            with self.subTest(text=text):
                self.assertIsNone(normalize_command(text))

    def test_menu_words_german_words_and_synonyms_stay_exact(self):
        for text in ('paus', 'resum', 'stat', 'nexxt', 'selekt',
                     'link', 'recht', 'schneler', 'langsame', 'brems',
                     'throtle', 'accelerat', 'brak'):
            with self.subTest(text=text):
                self.assertIsNone(normalize_command(text))

    def test_close_driving_words_do_not_accept_added_words(self):
        for text in ('not light', 'light please', 'lefft turn',
                     'my slowwer brother', 'faste faste'):
            with self.subTest(text=text):
                self.assertIsNone(normalize_command(text))

    def test_choose_command_uses_close_driving_words(self):
        self.assertEqual(choose_command([self.result('light', .97)]), ('right', 'light'))
        self.assertIsNone(choose_command([self.result('light', .74)]))
        self.assertIsNone(choose_command([self.result('light', .97), self.result('lift', .96)]))

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
