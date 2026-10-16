"""Build and test a portable Windows x64 package on a Windows host."""
import argparse
import importlib.metadata
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def run(arguments, cwd=ROOT):
    print('Run:', ' '.join(map(str, arguments)), flush=True)
    result = subprocess.run(list(map(str, arguments)), cwd=cwd, capture_output=True, text=True,
                            encoding='utf-8', errors='replace', timeout=900)
    print(result.stdout, flush=True)
    print(result.stderr, file=sys.stderr, flush=True)
    result.check_returncode()
    if 'SCRIPT ERROR:' in result.stdout + result.stderr or '\nERROR:' in result.stdout + result.stderr:
        raise RuntimeError('Godot reported an error.')
    return result


def copy_credits(bundle):
    credits = bundle / 'licenses'
    credits.mkdir()
    shutil.copy2(ROOT / 'LICENSE', credits / 'Stuntcar-Apache-2.0.txt')
    shutil.copy2(ROOT / 'README.md', bundle / 'README.md')
    shutil.copy2(ROOT / 'tools/release/WINDOWS-TEST.txt', bundle / 'WINDOWS-TEST.txt')
    for folder in ('quality', 'forest', 'audio', 'landscapes'):
        source = ROOT / 'assets' / folder
        if not source.exists():
            continue
        target = credits / 'assets' / folder
        target.mkdir(parents=True)
        for name in ('README.md', 'CREDITS.txt', 'manifest.json', 'sources.json'):
            if (source / name).is_file():
                shutil.copy2(source / name, target / name)
    car = credits / 'car'
    car.mkdir()
    for name in ('SOURCE.md', 'CC-BY-4.0.txt', 'KHRONOS-MARKS.txt'):
        shutil.copy2(ROOT / 'assets/quality/car' / name, car / name)
    shutil.copy2(ROOT / 'assets/audio/source/kenney-license.txt', credits / 'Kenney-CC0.txt')
    for name in ('LICENSE.txt', 'COPYRIGHT.txt'):
        shutil.copy2(ROOT / '.tools/export-toolchain' / name, credits / ('Godot-' + name))
    for package in ('vosk', 'sounddevice', 'cffi', 'srt', 'requests', 'tqdm', 'websockets', 'certifi', 'charset-normalizer', 'idna', 'urllib3', 'pycparser'):
        distribution = importlib.metadata.distribution(package)
        target = credits / 'python' / package
        target.mkdir(parents=True)
        (target / 'METADATA.txt').write_text(distribution.read_text('METADATA') or '', encoding='utf-8')
        for item in distribution.files or []:
            if 'license' in str(item).lower() or 'copying' in str(item).lower():
                source = Path(distribution.locate_file(item))
                if source.is_file():
                    shutil.copy2(source, target / source.name)
    shutil.copy2(Path(sys.base_prefix) / 'LICENSE.txt', credits / 'Python-LICENSE.txt')
    shutil.copy2(ROOT / 'tools/release/licenses/PortAudio-LICENSE.txt', credits / 'PortAudio-LICENSE.txt')
    shutil.copy2(ROOT / 'LICENSE', credits / 'Vosk-model-Apache-2.0.txt')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True, type=Path)
    args = parser.parse_args()
    if os.name != 'nt':
        parser.error('Build the Windows package on Windows.')
    godot = args.godot.resolve()
    exports = ROOT / 'exports'
    bundle = exports / 'stuntcar-windows'
    if bundle.exists():
        shutil.rmtree(bundle)
    bundle.mkdir(parents=True)
    run([sys.executable, '-m', 'PyInstaller', '--noconfirm', '--clean', '--onedir', '--console',
         '--name', 'stuntcar-voice', '--collect-all', 'vosk', '--paths', ROOT / 'voice',
         '--distpath', exports / 'voice-dist', '--workpath', exports / 'voice-build',
         '--specpath', exports, ROOT / 'voice/recognizer.py'])
    shutil.copytree(exports / 'voice-dist/stuntcar-voice', bundle / 'voice')
    for binary in (bundle / 'voice/_internal/_sounddevice_data/portaudio-binaries').glob('libportaudio*.dll'):
        if binary.name != 'libportaudio64bit.dll':
            binary.unlink()
    shutil.copytree(ROOT / '.tools/voice-models/vosk-model-small-en-us-0.15',
                    bundle / 'voice/models/vosk-model-small-en-us-0.15')
    copy_credits(bundle)
    run([godot, '--headless', '--editor', '--path', ROOT, '--import'])
    run([godot, '--headless', '--path', ROOT, '--export-release', 'Windows Desktop', bundle / 'Stuntcar.exe'])
    # Start from a different folder with spaces. Use only files from the final ZIP.
    archive = Path(shutil.make_archive(str(exports / 'stuntcar-windows'), 'zip', exports, bundle.name))
    with tempfile.TemporaryDirectory(prefix='Stuntcar package test ') as temporary:
        shutil.unpack_archive(archive, temporary)
        portable = Path(temporary) / bundle.name
        for name in ('Python-LICENSE.txt', 'PortAudio-LICENSE.txt', 'car/CC-BY-4.0.txt', 'assets/audio/CREDITS.txt'):
            if not (portable / 'licenses' / name).is_file():
                raise RuntimeError('The package lacks a license or credit: ' + name)
        voice = portable / 'voice/stuntcar-voice.exe'
        run([voice, '--check-runtime'], cwd=temporary)
        result = run([voice, '--mode', 'checked', '--wav', ROOT / 'voice/tests/audio/17.wav'], cwd=temporary)
        if json.loads(result.stdout)['chosen'] != ['slower', 'brake']:
            raise RuntimeError('The packaged recognizer failed to read the test command.')
        run([portable / 'Stuntcar.exe', '--headless', '--path', temporary,
             '--script', ROOT / 'tools/release/export_smoke.gd', '--log-file', portable / 'package-check.log'], cwd=temporary)
    print('Package ready:', archive, flush=True)


if __name__ == '__main__':
    main()
