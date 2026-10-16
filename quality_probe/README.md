# Qualitätsprobe in Godot

Diese eigenständige Testszene zeigt ein kostenloses Auto auf einer Asphaltstrecke mit Kiefern.
Sie verwendet Godot 4.5.1 und den Grafikmodus Forward+.
Das bestehende Spiel bleibt ein eigenes Projekt.

## Start

Öffne im Projektordner die Datei `tools/macos/Qualitätsprobe starten.command`.
Die Probe startet mit der Ansicht des Autos.

| Taste | Funktion |
|---|---|
| 1 | Auto ansehen |
| 2 | Fahrkamera |
| W oder Pfeil nach oben | Gas |
| S oder Pfeil nach unten | Bremse |
| A / D oder Pfeiltasten | Lenken |
| L | Tageslicht oder Abendlicht |
| R | Auto zurücksetzen |
| H | Anzeige einblenden oder ausblenden |
| Escape | Probe schließen |
| Linke Maustaste ziehen | Ansicht um das Auto drehen |
| Mausrad | Abstand zum Auto ändern |

Die Strecke endet nach einem kurzen Abschnitt. Das Auto beginnt dann wieder am anderen Ende.
Die Probe enthält eine einfache Fahrbewegung. Sie enthält keine Rennsimulation, Sprünge oder Zusammenstöße.
Die Probe enthält noch keinen Ton.

## Modelle und Materialien

Alle verwendeten Quelldateien kosten nichts.
Die Dateien `assets/manifest.json` und `assets/*-source.json` halten die Herkunft fest.

### Auto

Quelle: [Car Concept, Khronos glTF Sample Assets](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept).

Urheber: Eric Chadwick, Darmstadt Graphics Group GmbH, 2024.
Lizenz: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
Das Modell basiert auf einem CC0-Entwurf von Unity Fan.
Die vollständigen Angaben stehen in `assets/car/SOURCE.md`.
Der Lizenztext liegt in `assets/car/CC-BY-4.0.txt`.
Die Angaben zu den ursprünglichen Khronos-Zeichen stehen in `assets/car/KHRONOS-MARKS.txt`.

Änderungen für diese Probe:

- Der Lack erhält eine orange Farbe.
- Die dunklen Flächen erhalten angepasste Glanzwerte.
- Die Scheiben erhalten eine für Godot angepasste Transparenz.
- Das Nummernschild erhält eine neutrale Oberfläche.
- Die Reifen erhalten eine matte Oberfläche.
- Die zusätzlichen Normalenbilder des Autos bleiben ausgeschaltet. Sie erzeugten störende Oberflächen in diesem Import.
- Die Räder erhalten zusätzliche Drehpunkte für die Fahrbewegung.
- Die Vorderräder stehen zu Beginn gerade. Das Ausgangsmodell zeigt eingeschlagene Vorderräder.
- Die Probe schaltet die mitgelieferte Abschattung des Autos aus. Godot berechnet die räumliche Abschattung in der Szene.

Das Modell ersetzt für diese Probe den zuvor genannten Renafox-Kandidaten.
Es besitzt getrennte Räder und einen direkt verfügbaren glTF-Download.
Es stellt nicht den ursprünglichen orangefarbenen Bildentwurf exakt nach.

### Kiefern, Straße, Boden und Himmel

Diese Quellen verwenden [CC0](https://polyhaven.com/license):

| Quelle | Urheber |
|---|---|
| [Pine Sapling Small](https://polyhaven.com/a/pine_sapling_small) | Rob Tuytel und Rico Cilliers |
| [Asphalt Track](https://polyhaven.com/a/asphalt_track) | Dimitrios Savva |
| [Forest Floor](https://polyhaven.com/a/forest_floor) | eye-candy.xyz |
| [Kloofendal 48d Partly Cloudy](https://polyhaven.com/a/kloofendal_48d_partly_cloudy) | Greg Zaal |

Die Probe verwendet drei Kiefernformen mit unterschiedlicher Größe und Drehung.
Die großen Kiefern sind vergrößerte Jungbäume. Sie ersetzen noch keinen vollständig ausgearbeiteten Wald.
Die Bodenfarbe und die Beleuchtung unterscheiden sich von den Ausgangsdateien.
Die Leitplanken und die Fahrbahnmarkierungen entstehen direkt in Godot.

## Prüfung und Grenzen

Die Aufnahmen im Ordner `captures` stammen direkt aus dem laufenden Godot-Fenster.
Die Probe verwendet keine erzeugten Bilder als Ersatz für die 3D-Szene.
Die Datei `captures/metrics.json` enthält die gemessenen Bildzeiten und den verwendeten Grafikchip.
Die Messung gilt nur für die dort genannte Ansicht und Auflösung.
Sie belegt keine Bildrate für das vollständige Spiel.
Der letzte Lauf erreichte rund 68 Bilder pro Sekunde in der unbewegten Abendansicht.
Der Rechner verwendete einen Apple M4 Pro bei 1600 × 1000 Bildpunkten.
Die Prüfung von Modellaufbau und Bedienung meldete 29 erfolgreiche Prüfungen.

Die Szene dient zur Auswahl einer grafischen Richtung.
Sie erreicht noch nicht die Gesamtqualität eines fertigen AAA-Rennspiels.
Für die weitere Arbeit fehlen eine ausgearbeitete Landschaft, zusätzliche Baumarten und die Einbindung in die Rennstrecke.

## Dateien für die Weiterarbeit

- `main.tscn`: Startszene.
- `probe.gd`: Aufbau der Szene und einfache Bedienung.
- `capture.gd`: Aufnahmen und kurze Messung.
- `check_probe.gd`: Prüfung von Modellaufbau, Fahrbewegung, Ansichten und Lichtwechsel.
- `assets`: Quelldateien mit Nutzungsrechten.
- `../tools/quality_probe/fetch_assets.py`: erneuter Abruf der kostenlosen Quelldateien.

Die Importdateien gehören zur Probe. Sie enthalten die Einstellungen gegen flimmernde Texturen.
Godot erzeugt den Ordner `.godot` bei einem neuen Import erneut.
