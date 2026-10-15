"""Whole-utterance commands with a small list of known spoken variants."""
import re
import unicodedata

ALIASES = {
    'links': 'left', 'left': 'left', 'rechts': 'right', 'right': 'right',
    'schneller': 'faster', 'gas': 'faster', 'gas geben': 'faster',
    'fast': 'faster', 'faster': 'faster', 'fasta': 'faster', 'foster': 'faster', 'accelerate': 'faster', 'throttle': 'faster',
    'langsamer': 'slower', 'bremsen': 'slower', 'bremse': 'slower',
    'slower': 'slower', 'brake': 'slower', 'brakes': 'slower',
    'pause': 'pause', 'weiter': 'resume', 'continue': 'resume', 'resume': 'resume',
    'nächstes': 'next', 'next': 'next', 'wählen': 'select', 'select': 'select',
    'start': 'start', 'starten': 'start',
}

def normalize_command(text):
    if not isinstance(text, str):
        return None
    text = unicodedata.normalize('NFC', text).lower().strip()
    text = re.sub(r'[.!?,;:]+$', '', text).strip()
    return ALIASES.get(text)

def choose_command(results):
    candidates = []
    for result in results:
        text = result.get('text', '')
        command = normalize_command(text)
        words = result.get('result', [])
        if command and words:
            confidence = min(float(word.get('conf', 0)) for word in words)
            candidates.append((confidence, command, text))
    candidates.sort(reverse=True)
    if not candidates or candidates[0][0] < .75:
        return None
    best = candidates[0]
    if any(command != best[1] and confidence > best[0] - .15 for confidence, command, _ in candidates[1:]):
        return None
    return best[1], best[2]
