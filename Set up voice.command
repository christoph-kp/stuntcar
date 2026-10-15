#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")"
python3 voice/setup.py
read -r '?Setup is complete. Press Enter to close.'
