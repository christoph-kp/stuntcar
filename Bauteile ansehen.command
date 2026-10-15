#!/bin/zsh
set -eu
cd -- "${0:A:h}"
exec .tools/Godot.app/Contents/MacOS/Godot --path "$PWD" --editor res://assets/stuntcar_kit/examples/stunt_preview.tscn
