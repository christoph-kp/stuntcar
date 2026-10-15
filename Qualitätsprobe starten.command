#!/bin/zsh
set -eu
project_dir="${0:A:h}"
exec "$project_dir/.tools/Godot.app/Contents/MacOS/Godot" --path "$project_dir/quality_probe" --log-file /tmp/stuntcar-qualitaetsprobe.log
