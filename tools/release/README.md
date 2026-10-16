# Windows package build

The Windows preview workflow builds a portable x64 ZIP on `windows-2022`.
It uses Godot 4.5.1, Python 3.11, and the versions in the two requirements files.
The tester needs neither Godot nor Python.

## Build

A push to `main` starts the build when a relevant file changes.
You can also start the workflow from the GitHub Actions page.
A push to a tag such as `v0.0.0-windows-preview.1` builds and publishes a prerelease.
The prerelease contains `stuntcar-windows.zip` as a direct download.
Other builds keep the ZIP as an Actions artifact for 30 days.

To build on a Windows development computer:

```powershell
python -m pip install -r voice/requirements.txt -r tools/release/requirements.txt
python voice/setup.py --with-german
python tools/release/install_godot.py
python tools/release/build_windows.py --godot .tools/export-toolchain/Godot_v4.5.1-stable_win64.exe
```

The German model serves the old automatic tests only.
The package includes only the English model.
The Godot download uses the fixed release and checks its SHA-512 values.
The voice setup checks the downloaded model's SHA-256 value.

## Package checks

The workflow first runs the Python voice tests.
PyInstaller then bundles the voice helper, Python, Vosk, and PortAudio.
Godot exports the game and its track data into an executable and a PCK file.
The build adds the English model, credits, license files, and the tester instructions.

The build extracts the final ZIP into a temporary folder with spaces.
It starts the helper from another folder.
It checks the native voice libraries and reads a real test WAV with the packaged recognizer.
It starts the exported game without a display.
The game check loads all four tracks, their preview images, and the car.
It checks that the car can move on each track.
A script error, a resource error, or a failed check stops the build.

These checks use no microphone.
They do not test a graphics card or a person's voice.
The tester follows [the Windows test guide](../../docs/windows-testing.md) for those checks.

## Package structure

```text
stuntcar-windows/
  Stuntcar.exe
  Stuntcar.pck
  README.md
  WINDOWS-TEST.txt
  licenses/
  voice/
    stuntcar-voice.exe
    _internal/
    models/vosk-model-small-en-us-0.15/
```

Keep all these files together.
The helper finds its model beside its own executable.
It does not use the current folder or a Python installation on the tester's computer.
Godot starts the helper without a separate console window.
The local Mac setup keeps its existing Python path.
