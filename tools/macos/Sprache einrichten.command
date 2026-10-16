#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")/../.."
python3 voice/setup.py
read -r '?Die Einrichtung ist fertig. Drücke die Eingabetaste zum Schließen.'
