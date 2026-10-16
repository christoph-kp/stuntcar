"""Install the fixed Windows build tools after a checksum check."""
import hashlib
import os
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
VERSION = '4.5.1-stable'
BASE = f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}/'


def main():
    if os.name != 'nt':
        raise SystemExit('Run this installer on Windows.')
    cache = ROOT / '.tools/export-toolchain'
    cache.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(BASE + 'SHA512-SUMS.txt', timeout=120) as source:
        checksums = {line.split()[1].lstrip('*'): line.split()[0] for line in source.read().decode().splitlines() if line.strip()}
    names = [f'Godot_v{VERSION}_win64.exe.zip', f'Godot_v{VERSION}_export_templates.tpz']
    for name in names:
        archive = cache / name
        print('Download:', name, flush=True)
        urllib.request.urlretrieve(BASE + name, archive)
        with archive.open('rb') as source:
            actual = hashlib.file_digest(source, 'sha512').hexdigest()
        if actual != checksums[name]:
            raise RuntimeError('The Godot checksum does not match: ' + name)
        with zipfile.ZipFile(archive) as package:
            if name.endswith('.zip'):
                for member in package.namelist():
                    if member.endswith('.exe') and '/' not in member:
                        package.extract(member, cache)
            else:
                target = Path(os.environ['APPDATA']) / 'Godot/export_templates/4.5.1.stable'
                target.mkdir(parents=True, exist_ok=True)
                for binary in ('windows_release_x86_64.exe', 'windows_debug_x86_64.exe'):
                    (target / binary).write_bytes(package.read('templates/' + binary))
        archive.unlink()
    for name in ('LICENSE.txt', 'COPYRIGHT.txt'):
        urllib.request.urlretrieve('https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/' + name, cache / name)


if __name__ == '__main__':
    main()
