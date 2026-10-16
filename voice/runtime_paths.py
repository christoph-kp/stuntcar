"""Find the model without depending on the current working directory."""
from pathlib import Path
import sys


def model_root():
    if getattr(sys, 'frozen', False):
        return Path(sys.executable).resolve().parent / 'models'
    return Path(__file__).resolve().parents[1] / '.tools' / 'voice-models'
