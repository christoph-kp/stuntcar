#!/bin/zsh
set -eu
cd -- "$(dirname -- "$0")"
mkdir -p reports/voice
report="$PWD/reports/voice/$(date +%Y%m%d-%H%M%S)-$$.jsonl"
print 'Der Test öffnet die Sprachübung im Spiel.'
print 'Klicke auf Start und führe die Kalibrierung durch.'
print 'Sprich die angezeigten Wörter zuerst normal und dann laut.'
print 'Schließe danach das Spiel.'
print "Der Bericht steht hier: $report"
print 'Der Bericht enthält Messwerte und Befehle. Er enthält keine Tonaufnahme.'
./Starten.command -- "--voice-diagnostics=$report"
print "Der Bericht steht hier: $report"
read -r '?Drücke die Eingabetaste zum Schließen.'
