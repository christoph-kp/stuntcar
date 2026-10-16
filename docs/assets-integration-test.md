# Auto, Landschaften und Streckenauswahl

Stand: 15. Oktober 2026.

## Ergebnis

Das Spiel verwendet das Auto aus `assets/stuntcar_kit/vehicle/stunt_coupe.tscn`.
Die Räder drehen um ihre lokale X-Achse.
Die Strecken nutzen die Landschaften Nebelwald, Alpenpass, Felsenschlucht und Regenküste.
Die Küstenfahrt nutzt den Verlauf der Ersten Fahrt.
Die Fahrbahn folgt weiterhin dem vorhandenen Streckenformat.
Die neuen Leitpfosten und Brückenstützen begleiten diese Fahrbahn.
Loopings und Änderungen am Fahrmodell gehören nicht zu diesem Schritt.

Bei jedem Start erscheint zuerst die Streckenauswahl.
Die Bilder unter `tracks/previews` zeigen die tatsächlichen Strecken.
Die erste Steuerungswahl folgt erst nach der Streckenwahl.
Die Einstellungen bleiben später erreichbar.

## Prüfungen

Alle 13 Godot-Prüfprogramme bestanden.
Die zwölf Dateien `tests/run*tests.gd` meldeten zusammen 337 erfolgreiche Einzelprüfungen.
`tests/run_scene_test.gd` erreichte das Ziel ohne Fehler.
Die 15 Python-Prüfungen der Sprache bestanden ebenfalls.
Die Dateiprüfung `tools/check_tracks.gd` meldete vier gültige Strecken ohne Hinweise.
Die Shell-Prüfung der Datei `tools/macos/Strecken prüfen.command` bestand.

Die Auswahlprüfung umfasst den ersten Start, den späteren Start, den Streckenwechsel und die gespeicherten Einstellungen.
Sie prüft auch eine Datei, die nach dem Öffnen der Auswahl fehlt.
Eine solche Auswahl zeigt eine Meldung und öffnet keine alte Strecke.
Ein Mikrofonfehler bleibt auch in der Streckenauswahl sichtbar.

Die Katalogprüfung nutzt einen eigenen temporären Ordner.
Sie prüft eine gültige Datei, einen JSON-Fehler mit Zeilenangabe und das Entfernen einer Datei.
Eine fehlende Standarddatei verhindert den Start der Auswahl nicht.

Die Landschaftsprüfung kontrolliert alle vier Strecken.
Sie prüft die freie Fahrbahn, die Räder, den Wetterwechsel und das Entfernen der vorherigen Umgebung.

## Sichtprüfung

Das Spiel erzeugte die Bilder mit dem vorhandenen Grafikprogramm von Godot.
Die Sichtprüfung umfasste alle vier Landschaften und die Auswahl bei 1280 × 800 sowie 960 × 640.
Die Datei `docs/auswahl-fehlerpruefung.png` zeigt einen gezielt erzeugten Fehlerzustand.
Dieser Test verändert keine echten Streckendateien und benutzt kein Mikrofon.

Die Prüfung ohne Spielfenster meldet weiterhin den bekannten macOS-Zertifikathinweis.
Die Prüfprogramme beenden sich erfolgreich.
Die Aufnahmen mit Spielfenster melden diesen Hinweis nicht.

## Grenzen

Die Dateiprüfung prüft das Format, die Werte und die vorgeschriebenen Abstände.
Sie erkennt keine Kreuzungen der Fahrbahn.
Eine neue Strecke braucht deshalb eine Probefahrt.
Dieser Schritt enthält keinen neuen Test mit einer echten Stimme.
