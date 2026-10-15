# Kostenlose Modelle im Spiel

Dieser Ordner enthält die Quelldateien aus der Godot-Qualitätsprobe.
Das Spiel nutzt sie unabhängig vom separaten Projekt `quality_probe`.
Alle verwendeten Quelldateien kosten nichts.

## Auto

Quelle: [Car Concept, Khronos glTF Sample Assets](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept).

Urheber: Eric Chadwick, Darmstadt Graphics Group GmbH, 2024.
Lizenz: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
Das Modell basiert auf einem CC0-Entwurf von Unity Fan.
Die vollständigen Angaben stehen in `car/SOURCE.md`.
Der Lizenztext liegt in `car/CC-BY-4.0.txt`.
Die Angaben zu den ursprünglichen Khronos-Zeichen stehen in `car/KHRONOS-MARKS.txt`.

Änderungen im Spiel:

- Der Lack erhält eine orange Farbe.
- Die Scheiben erhalten eine angepasste Transparenz.
- Das Nummernschild erhält eine neutrale Oberfläche.
- Die Reifen und die Felgen erhalten angepasste Oberflächen.
- Das Spiel deaktiviert die zusätzlichen Normalenbilder und die mitgelieferte Abschattung des Autos.
- Godot berechnet die räumliche Abschattung in der Szene.
- Die Vorderräder stehen zu Beginn gerade.
- Vier zusätzliche Drehpunkte verbinden die Räder mit der vorhandenen Fahrbewegung.

Die ursprünglichen Modelldateien bleiben erhalten. Das Spiel ändert die Oberflächen beim Laden.

## Natur und Oberflächen

Diese Quellen verwenden [CC0](https://polyhaven.com/license):

| Quelle | Urheber |
|---|---|
| [Pine Sapling Small](https://polyhaven.com/a/pine_sapling_small) | Rob Tuytel und Rico Cilliers |
| [Asphalt Track](https://polyhaven.com/a/asphalt_track) | Dimitrios Savva |
| [Forest Floor](https://polyhaven.com/a/forest_floor) | eye-candy.xyz |
| [Kloofendal 48d Partly Cloudy](https://polyhaven.com/a/kloofendal_48d_partly_cloudy) | Greg Zaal |

Das Spiel verändert die Größe und die Drehung der Kiefern.
Die großen Kiefern sind vergrößerte Jungbäume.
In den Alpen stehen diese Kiefern im Schnee. Die Äste besitzen noch keine eigene Schneeschicht.
Der Waldboden erhält eine dunklere Farbe.
Der Asphalt folgt den Kurven, den Kuppen und den Steilkurven.

Die Datei `manifest.json` nennt die Downloadquellen und die Prüfsummen der Originaldateien.
Die Pfade in dieser Datei gelten relativ zu diesem Ordner.
Die Dateien `*-source.json` enthalten die Angaben von Poly Haven.

## Verwendung

Die Datei `scripts/quality_assets.gd` im Projekt erstellt die Modelle und Materialien für das Spiel.
Die Importdateien aktivieren kleinere Texturstufen für entfernte Oberflächen.
Die Kiefern verwenden die von Godot erzeugten vereinfachten Modelle für größere Entfernungen.
Das Spiel blendet weit entfernte Kiefern aus.

Das neue Auto erscheint auf allen vier Strecken.
Der Canyon und die Küste behalten ihre bisherigen Landschaftsmodelle.
Die vollständige Landschaft erreicht noch nicht die Qualität eines fertigen AAA-Rennspiels.

## Prüfung am 15. Oktober 2026

Die Spieltests meldeten 192 Prüfungen ohne Fehler.
Sie prüften die Landschaften, die Sprünge, die Steilkurven, die Tasten und die Streckenauswahl.
Eine zusätzliche Codeprüfung fand keinen wichtigen Fehler.

Eine kurze Messung nutzte den Apple M4 Pro bei 1280 × 800 Bildpunkten:

| Landschaft | Durchschnittliche Bilder pro Sekunde |
|---|---:|
| Wald | 90 |
| Alpen | 107 |
| Canyon | 147 |
| Küste | 147 |

Die Messung umfasst jeweils die erste Kurve. Sie garantiert keine Bildrate für jede Stelle der Strecke.
Die genauen Werte stehen in `docs/qualitaet-bildzeiten.json` im Projekt.
