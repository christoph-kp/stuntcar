"""Install the local helper and verified model archives inside this project."""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import urllib.request
import venv
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = {
    'de': 'b7e53c90b1f0a38456f4cd62b366ecd58803cd97cd42b06438e2c131713d5e43',
    'en-us': '30f26242c4eb449f948e42cb302dd7a686cb29a3423a8367f99ff41780942498',
}

def main():
    if sys.version_info < (3, 11):
        raise RuntimeError('Die Einrichtung braucht Python 3.11 oder neuer.')
    parser = argparse.ArgumentParser()
    parser.add_argument('--with-german', action='store_true', help='Zusatzmodell für alte Vergleichstests')
    args = parser.parse_args()
    environment = ROOT / '.tools' / 'voice-env'
    if not environment.exists():
        venv.EnvBuilder(with_pip=True).create(environment)
    python = environment / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')
    subprocess.run([str(python), '-m', 'pip', 'install', '-r', str(ROOT/'voice/requirements.txt')], check=True)
    models = ROOT / '.tools' / 'voice-models'
    models.mkdir(parents=True, exist_ok=True)
    for language, checksum in ARCHIVES.items():
        if language == 'de' and not args.with_german:
            continue
        name = f'vosk-model-small-{language}-0.15'
        if (models / name / 'am' / 'final.mdl').is_file():
            continue
        archive = models / f'{name}.zip'
        print(f'Lade Sprachmodell: {language}', flush=True)
        with urllib.request.urlopen(f'https://alphacephei.com/vosk/models/{name}.zip', timeout=60) as source:
            with archive.open('wb') as output:
                while block := source.read(1024*1024): output.write(block)
        with archive.open('rb') as source:
            if hashlib.file_digest(source, 'sha256').hexdigest() != checksum:
                raise RuntimeError('Die Prüfsumme des Sprachmodells stimmt nicht.')
        with zipfile.ZipFile(archive) as package:
            for item in package.infolist():
                destination = (models / item.filename).resolve()
                if not destination.is_relative_to(models.resolve()):
                    raise RuntimeError('Das Sprachmodell enthält einen ungültigen Dateipfad.')
            package.extractall(models)
        archive.unlink()
    print('Die lokale Sprachsteuerung ist bereit.')

if __name__ == '__main__':
    main()
