#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")"
if [[ -x .tools/Godot.app/Contents/MacOS/Godot ]]; then
  exec .tools/Godot.app/Contents/MacOS/Godot --path . "$@"
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path . "$@"
else
  print 'Godot fehlt. Öffne project.godot mit Godot 4.5.1 oder neuer.'
  read -r '?Drücke die Eingabetaste zum Schließen.'
fi
