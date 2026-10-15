"""Exact aliases and a one-edit match for English driving commands."""
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

# Keep this set separate from aliases. German words and menu commands stay exact.
DRIVING_WORDS = {
    'left': 'left', 'right': 'right', 'fast': 'faster',
    'faster': 'faster', 'slower': 'slower',
}


def _within_one_edit(text, word):
    """Check Levenshtein distance <= 1 without a full distance matrix."""
    if abs(len(text) - len(word)) > 1:
        return False
    left = right = edits = 0
    while left < len(text) and right < len(word):
        if text[left] == word[right]:
            left += 1
            right += 1
            continue
        edits += 1
        if edits > 1:
            return False
        if len(text) >= len(word):
            left += 1
        if len(word) >= len(text):
            right += 1
    return edits + len(text) - left + len(word) - right <= 1


def normalize_command(text):
    if not isinstance(text, str):
        return None
    text = unicodedata.normalize('NFC', text).lower().strip()
    text = re.sub(r'[.!?,;:]+$', '', text).strip()
    exact = ALIASES.get(text)
    if exact is not None:
        return exact
    if not re.fullmatch(r'[a-z]{4,7}', text):
        return None
    matches = {command for word, command in DRIVING_WORDS.items()
               if _within_one_edit(text, word)}
    return matches.pop() if len(matches) == 1 else None

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
