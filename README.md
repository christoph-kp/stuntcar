# Stuntcar · First Drive

**Version 0.0 · An early game prototype with voice control.**

Stuntcar is a fully “vibe-coded” game, made as a side project with Godot 4.5.1.
We describe the idea, and AI agents write the game code.
We test the result and work with the agents to change it.

## Why we make this game

We want to make computer games available to people who cannot use a controller because of physical limitations.
This is why we chose voice control.
Short English commands control the car.
Your voice level sets the force of a turn, the acceleration, and the brake.
A system helps you turn through each curve after you give the correct direction.

We also work on projects such as Voice Tech.
Those projects have a different focus.
Our goal here is access to computer games.
We also want Stuntcar to be fun for anyone who wants to play it.

This prototype needs tests with people who have different physical limitations.
Voice control will not meet every person's needs.
We want to add other ways to control the game.

## What comes next

We plan to add gesture control.
This feature is not in the current prototype.

In the past, a project like this would probably have cost too much for us to develop.
A commercial project would probably not have covered that cost.
New tools with AI agents reduce the work that we need to do.
These tools let us start projects that we could not otherwise make.

Version 0.0 is an early prototype.
We hope that it will develop further and that you will already have fun with it.
Tell us what works, what fails, and what makes the game fun.

## Windows test version

We are preparing a portable Windows x64 package for a tester.
We use a Windows computer on GitHub to build the package and run automatic checks.
A tester will then check the game, the microphone, and the voice control on a real Windows computer.
We do not yet claim that this prototype works on every Windows computer.

The [Windows build page](https://github.com/stefan-kp/stuntcar/actions/workflows/windows-preview.yml) has the build results and test packages.
The [release page](https://github.com/stefan-kp/stuntcar/releases) has the published test packages.
Use a Windows ZIP file from a release when one is available.
The GitHub “Source code” ZIP contains the project files. It is not a ready-to-run game.

1. Download `stuntcar-windows.zip`.
2. Extract the complete ZIP into a folder.
3. Keep `Stuntcar.exe`, `Stuntcar.pck`, and the `voice` folder together.
4. Open `Stuntcar.exe`.
5. Select a track.
6. Select “Voice + keys” or “Two keys”.
7. Select “Start drive”.

The portable package includes Python, the voice libraries, and the English voice model.
You do not need to install Godot or Python.
Read `WINDOWS-TEST.txt` in the package for the microphone setup and the test steps.
The [Windows test guide](docs/windows-testing.md) also has those steps.

## The game

The game has four tracks, jumps, banked curves, and a car with lights and shadows.
There is no time limit.
After a fall, the car starts again before the curve.
Loops are not yet available.

| Track | Length | Main features |
| --- | --- | --- |
| First Drive | 940 m | Forest, two large jumps, three banked curves |
| High Drive | 1,250 m | Mountain pass, five curves, one jump |
| Jump Track | 1,350 m | Canyon, five curves, two jumps |
| Coast Drive | 600 m | Wet coast, three curves, one hill |

Give one direction command before each curve.
The system then helps the car turn through that curve.
Another command in the same direction moves the car towards the inside of the curve.
A late command gives less time for a correction.
A command in the wrong direction turns the car in that direction.

The car jumps without a separate command.
A direction command can help the car reach the centre of the track before it lands.
The flight follows a fixed path.
The car shows a drift effect in fast curves.
The camera stays level with the horizon.

## Controls

The menus and the voice commands use English.
You can use the two keys at the same time as voice control.
You do not need to hold a key.

| Action | Key | Voice command |
| --- | --- | --- |
| Turn left | A | `left` |
| Turn right | D | `right` |
| Increase speed | — | `faster` or `fast` |
| Decrease speed | — | `slower` |
| Pause | Escape | `pause` in “Two checks” mode |
| Resume | D in the pause menu | `resume` or `continue` |
| Select the next menu item | A | `next` |
| Open a menu item | D | `select` |
| Start from the start menu | Select “Start drive” | `start` |

One spoken word is sufficient for a command.
You can say `left left left` to make three corrections.
The default voice mode uses one recognizer and adds no second check.
“Two checks” uses two recognizers for the same speech. It does not need a second spoken word.

The arrow display shows the command and its force.
The upper arrow increases speed. The lower arrow applies the brake.

| Bars | Turn | `faster` | `slower` |
| --- | --- | --- | --- |
| 1 | Small correction | Small speed increase | Small speed decrease |
| 2 | Normal correction | Normal speed increase | Normal speed decrease |
| 3 | Large correction | Short turbo boost | Full brake to a stop |

Say `faster` to move again after a full brake.
A quiet command is sufficient.
A brake command stops an active turbo boost.
The [voice control notes](docs/voice-stunts.md) have more details.

## Set your voice levels

1. Open “Settings”.
2. Open “Voice practice”.
3. Select “Calibrate voice”.
4. Say `okay` with your normal voice.
5. Say `okay` more loudly at the next step.
6. Say `okay` very loudly at the last step.
7. Complete the word test that follows.

The display tells you when to speak again.
The word test asks for `left`, `right`, `fast`, and `slower`.
It shows how many commands the game recognized.
It does not train or change the voice model.

The game saves the voice levels for your microphone.
It also saves the keys, the control mode, the track, and the sound levels.
You do not need to set your voice levels after each start.
A different microphone needs a new check of the voice levels.

Voice input runs locally with Vosk.
The game does not save microphone audio or send it to an internet service.
Background noise, microphone settings, and the distance from the microphone can change the result.

## Run the project on a Mac

The files under `.tools` are local tools. Git does not include them.
A new project copy needs Godot 4.5.1.
Voice input also needs Python 3.11 or later for the first setup.

1. Open `project.godot` with Godot 4.5.1.
2. Open `tools/macos/Sprache einrichten.command` to set up voice input.
3. Run the project from Godot with F5.

The first voice setup needs an internet connection.
After setup, voice input works without an internet connection.
Allow microphone access when macOS asks for it.

`Starten.command` starts the game when Godot is in `.tools/Godot.app` or `/Applications/Godot.app`.
It is the only game start file in the main folder.
The [Mac tools guide](tools/macos/README.md) describes the other tools.

## Thanks to the asset creators

Other people's work makes this prototype possible.
We thank everyone who shares models, surface images, and sounds.
This includes the creators who use CC0, even when they do not require a credit.
We want to show our thanks for their work.

| Part | Creators | Source and license details |
| --- | --- | --- |
| Car Concept | Eric Chadwick and Darmstadt Graphics Group; original design by Unity Fan | [Car and surfaces](assets/quality/README.md), CC BY 4.0 |
| Trees, plants, rocks, ground, road, and sky | Poly Haven and the creators named in the source lists | [Base assets](assets/quality/README.md), [forest assets](assets/forest/README.md), CC0 |
| Engine sound | qubodup | [Audio credits](assets/audio/CREDITS.txt), CC BY 3.0 |
| Forest, wind, and impact sounds | ktokrzysiek, SketchMan3, JaggedStone, and Kenney | [Audio sources](assets/audio/README.md), CC0 |

The sources are free of charge. They use different licenses.
The source lists give the creator names, source links, and our changes.
The game packages include the asset credits and license files.

We also thank the people who make these tools and voice libraries:

- [Godot](https://godotengine.org/): the game engine.
- [Vosk](https://alphacephei.com/vosk/): local speech recognition.
- [Vosk models](https://alphacephei.com/vosk/models): the small English model 0.15, under Apache 2.0.
- [sounddevice](https://python-sounddevice.readthedocs.io/): microphone access.

## Development

The project uses Godot 4.5.1 and the Forward+ graphics mode.
The English interface text is in `locales/en.po`.
The [language guide](locales/README.md) describes how to add another interface language.
The [track guide](tracks/README.md) describes how to add a track.
Some of the detailed project notes are still in German.

Use these checks from the project folder on a Mac:

```sh
.tools/voice-env/bin/python -m unittest discover -s voice/tests
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_tests.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/run_voice_runtime_tests.gd
```

The [Windows build guide](tools/release/README.md) describes the automatic package build and its checks.
The automatic checks do not prove that the controls meet the needs of people with physical limitations.
We need their feedback to improve the game.

## License

The game code uses the [Apache License 2.0](LICENSE).
The models, images, sounds, and libraries keep their own licenses.
See the source lists above for those licenses.
