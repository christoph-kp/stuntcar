# Wald für „Erste Fahrt“

Diese Modelle ergänzen die Waldstrecke „Erste Fahrt“. Die Strecke hat nach dem Stuntumbau 940 Meter Länge.
Alle Quellen stammen von Poly Haven. Poly Haven stellt diese Modelle und Oberflächen unter CC0 bereit.
Die Nutzung umfasst auch Änderungen und kommerzielle Spiele. Siehe [Lizenz](https://polyhaven.com/license).

| Quelle | Inhalt | Urheber |
|---|---|---|
| [Pine Tree 01](https://polyhaven.com/a/pine_tree_01) | Drei Kiefern | Rob Tuytel, Rico Cilliers |
| [Fir Tree 01](https://polyhaven.com/a/fir_tree_01) | Drei Tannen | Rob Tuytel, Rico Cilliers |
| [Rock Moss Set 01](https://polyhaven.com/a/rock_moss_set_01) | Moosige Felsen | Kless Gyzen |
| [Fern 02](https://polyhaven.com/a/fern_02) | Farne | Rob Tuytel, Rico Cilliers |
| [Grass Medium 01](https://polyhaven.com/a/grass_medium_01) | Grasgruppen | Rob Tuytel, Rico Cilliers |
| [Forest Ground 04](https://polyhaven.com/a/forest_ground_04) | Waldboden | Rob Tuytel, Rico Cilliers |

Die Dateien `*-source.json` enthalten die ursprünglichen Angaben des Anbieters.
`manifest.json` enthält die Downloadadressen und Prüfsummen der Quelldateien.
Das Spiel nutzt zusätzlich den bisherigen Boden und Himmel aus `assets/quality`.

## Aufbereitung

Die Baumdateien enthalten jeweils drei Formen und zwei Detailstufen.
Das Spiel zeigt die größere Detailstufe in der Nähe des Autos.
Es zeigt die kleinere Detailstufe ab etwa 45 Metern Abstand.
Die Datei `trees/variants.json` nennt die Anzahl der Dreiecke je Datei.

Blender vereinfacht die ursprüngliche Detailstufe LOD2.
Die Aufbereitung erhält die Bildzuordnung der Nadeln.
Sie entfernt die getrennten abgestorbenen Äste.
Die Bodenbegrenzung verhindert, dass das Auto beim Fall durch das Gelände fällt.
Die Anordnung der Modelle folgt der Strecke mit einem festen Zufallswert.

Für einen erneuten Abruf dient `tools/forest/fetch_sources.py`.
Dieses Programm braucht eine Internetverbindung.
Für die Aufbereitung dient `tools/forest/prepare_trees.py` mit Blender 4.5.1.
Die großen Quelldateien liegen unter `.tools/forest-sources`.
Das fertige Spiel braucht weder Blender noch eine Internetverbindung.

## Prüfung

`tests/run_forest_tests.gd` prüft das Gelände und die Bildzuordnung der Bäume.
`tests/run_forest_fall_test.gd` prüft einen echten Fall und den anschließenden Neustart.
`tests/capture_forest.gd` erstellt sechs Bilder entlang der Strecke und das Vorschaubild.
`tests/capture_stunts.gd` zeigt die aktuelle Stuntstrecke mit elf Bildern und aktualisiert das Vorschaubild.
`tests/measure_forest.gd` misst eine vollständige Fahrt bei 1280 × 800 Bildpunkten.
