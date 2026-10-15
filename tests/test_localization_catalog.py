"""Check that each built-in text key has one non-empty English translation."""
import ast
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read_catalog():
    entries = []
    key = value = None
    field = None
    for line in (ROOT / 'locales/en.po').read_text().splitlines() + ['msgid ""']:
        if line.startswith('msgid '):
            if key is not None:
                entries.append((key, value))
            key, value, field = ast.literal_eval(line[6:]), '', 'key'
        elif line.startswith('msgstr '):
            value, field = ast.literal_eval(line[7:]), 'value'
        elif line.startswith('"'):
            if field == 'key':
                key += ast.literal_eval(line)
            elif field == 'value':
                value += ast.literal_eval(line)
    return entries


class LocalizationCatalog(unittest.TestCase):
    def test_catalog_has_unique_nonempty_messages(self):
        entries = read_catalog()
        keys = [key for key, _ in entries]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertTrue(all(value for _, value in entries))
        self.assertIn('Language: en', dict(entries)[''])

    def test_runtime_and_builtin_track_keys_exist(self):
        catalog = dict(read_catalog())
        files = list((ROOT / 'scripts').rglob('*.gd')) + list((ROOT / 'tracks').rglob('*.json'))
        files.append(ROOT / 'voice/recognizer.py')
        for path in files:
            for key in re.findall(r'\bI18N_[A-Z_]+\b', path.read_text()):
                with self.subTest(path=str(path.relative_to(ROOT)), key=key):
                    self.assertIn(key, catalog)

    def test_game_scripts_have_no_german_display_strings(self):
        # Comments and developer diagnostics may remain German. Inspect literals only.
        for path in (ROOT / 'scripts').rglob('*.gd'):
            for literal in re.findall(r'"(?:\\.|[^"\\])*"', path.read_text()):
                self.assertIsNone(re.search('[äöüÄÖÜß]', literal), (str(path), literal))


if __name__ == '__main__':
    unittest.main()
