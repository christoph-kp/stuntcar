# Tonquellen

Stand: 15. Oktober 2026. Die Motoraufnahme nutzt CC BY 3.0. Die anderen verwendeten Quellen nennen CC0.
Die Angaben zur Herkunft stammen von den Autoren. Ein eigener Hörvergleich steht noch aus.

| Datei | Autor und Quelle | Herkunft laut Quellseite |
| --- | --- | --- |
| `source/car_engine_qubodup.wav` | [qubodup: Car Engine Loop 96kHz, 4s](https://opengameart.org/content/car-engine-loop-96khz-4s) | Eigene Motoraufnahme. Der Autor bereitete sie für das Rennspiel Trigger vor. Lizenz: CC BY 3.0. |
| `source/forest_birds.mp3` | [ktokrzysiek: forest_birds.wav](https://freesound.org/people/ktokrzysiek/sounds/392603/) | Aufnahme eines Waldes im Frühling. |
| `source/wind.ogg` | [SketchMan3: wind whoosh loop](https://opengameart.org/content/wind-whoosh-loop) | Bearbeiteter Ausschnitt aus einer Windaufnahme. |
| `source/impact_soft.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactSoft_heavy_000.ogg` aus dem Paket. |
| `source/impact_metal.ogg` | [Kenney: Impact Sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactMetal_heavy_000.ogg` aus dem Paket. |

Die Windquelle basiert auf [JaggedStone: Loopable Dungeon Ambience](https://opengameart.org/content/loopable-dungeon-ambience).
Auch diese Quellseite nennt CC0.

Die Freesound-Dateien sind die öffentlichen MP3-Hörproben in hoher Qualität.
Sie sind keine Original-WAV-Dateien. Der Abruf der Originale braucht eine Anmeldung.
Die genaue Herkunft der gespeicherten Dateien steht in `sources.json`.
Die Kenney-Lizenz steht zusätzlich in `source/kenney-license.txt`.
Für Wald, Wind und Landungen gilt [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
Für die Motoraufnahme gilt [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
Die Namensnennung steht zusätzlich in `CREDITS.txt`. Sie muss der Weitergabe des Spiels beiliegen.

## Bearbeitung

`tools/audio/prepare_audio.py` erzeugt die sechs Spielaufnahmen aus den gespeicherten Quellen.
Das Werkzeug braucht Python und FFmpeg.
`processing.json` enthält die Ausschnitte und die Filter.

- Der Motorton verwendet die vollständige viersekündige Aufnahme von qubodup.
- Die Bearbeitung wandelt sie in einen Kanal um und filtert sehr tiefe und hohe Frequenzen.
- Eine kurze Überblendung verbindet das Ende mit dem Anfang.
- Die Waldaufnahme verwendet die Sekunden 2 bis 30.
- Die Windaufnahme bildet den Fahrtwind.
- Ein tiefer gefilterter Teil der Windaufnahme bildet das Rollgeräusch.
- Die beiden Kenney-Aufnahmen bilden den Stoß und das kurze Geräusch der Federung.
- Der vorhandene Hinweiston entsteht weiterhin im Spiel.

Das Spiel verändert die Tonhöhe mit der Geschwindigkeit.
Diese Fassung verwendet einen Motorabschnitt. Sie bildet keine einzelnen Gänge nach.
Das Spiel verwendet keine aus Gran Turismo entnommenen Geräusche.
Die Ferrari-Aufnahme von PritzProductions bleibt ungenutzt. Stefan hörte Stimmen im zuvor verwendeten Ausschnitt.
Die anderen Ferrari-Kandidaten bleiben ebenfalls ungenutzt.
Der neue Motorton braucht noch eine Hörprüfung. Die automatische Spracherkennung ersetzt diese Prüfung nicht.

## Bedienung

Öffne „Einstellungen“ und dann „Lautstärke“.
Die drei Einträge regeln den Motor, die Umgebung und die Hinweise.
Jeder Druck erhöht den Wert um 25 Prozentpunkte. Nach 100 Prozent folgt 0 Prozent.
„Ton: Aus“ schaltet alle Spielgeräusche aus.

Der Motor umfasst auch die Reifen und die Landungen.
Die Umgebung umfasst den Fahrtwind und den Wald.
Die Waldaufnahme läuft nur auf Waldstrecken.
Ein Hinweis senkt die Fahrgeräusche kurz ab.
Die Sprachsteuerung senkt die Fahrgeräusche zusätzlich ab.
Der Test mit Lautsprechern und einem echten Mikrofon steht noch aus.
