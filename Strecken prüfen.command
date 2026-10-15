#!/bin/zsh
cd -- "$(dirname -- "$0")"
if [[ -x .tools/Godot.app/Contents/MacOS/Godot ]]; then
  .tools/Godot.app/Contents/MacOS/Godot --headless --path . --log-file "${TMPDIR:-/tmp/}stuntcar-streckenpruefung.log" --script tools/check_tracks.gd
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/check_tracks.gd
else
  print 'Godot fehlt. Öffne project.godot mit Godot 4.5.1 oder neuer.'
fi
read -r '?Drücke die Eingabetaste zum Schließen.'
