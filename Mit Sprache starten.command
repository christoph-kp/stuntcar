#!/bin/zsh
# Der bisherige Startweg bleibt als Verknüpfung erhalten.
set -eu
cd -- "$(dirname -- "$0")"
exec ./Starten.command "$@"
