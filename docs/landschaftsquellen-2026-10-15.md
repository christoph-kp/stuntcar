# Landschaftsquellen für Stuntcar

Stand: 15. Oktober 2026.

Poly Haven bietet die beste Grundlage für den weiteren Ausbau. Die naturgetreuen Modelle passen zum vorhandenen Auto und zu den Landschaftsentwürfen. Für große Berge und Schluchten ergänzen wir die Auswahl mit Blendkit und einzelnen Fab-Modellen.

Die Auswahl umfasst 31 Kandidaten aus neun Quellen. Der Vergleich berücksichtigt zusätzlich itch.io, Quaternius und Kenney. Er deckt zwölf Anbieter und Bibliotheken ab. Er ist keine vollständige Erfassung aller Angebote.

Die Stilbewertung ist eine Einschätzung anhand der Projektbilder und der Produktangaben. Die neuen Modelle brauchen noch einen Importtest in Godot. Preise und Zugänge können sich ändern.

## Was dem Spiel noch fehlt

Das Spiel nutzt bereits das orange Auto, Asphalt, Waldboden und Kiefern aus externen Quellen. Die Landschaft enthält daneben noch einfache Felsformen. Die Bilder zeigen einen deutlichen Unterschied zwischen dem Auto und diesen Felsen.

Der Code vergrößert dieselben Jungbäume für Wald und Alpen. Er verteilt die Objekte entlang der Straße. Eine große Bodenfläche liegt darunter. Daraus entstehen noch keine zusammenhängenden Berghänge, Täler oder Küsten.

Die nächsten Modelle sollen fünf Lücken schließen:

1. Große Bäume mit unterschiedlichen Formen.
2. Zusammenhängende Felswände und Geländeformen.
3. Kleine Pflanzen zwischen den Bäumen.
4. Übergänge zwischen Erde, Fels, Schnee und Wasser.
5. Ferne Berge und markante Punkte am Horizont.

Die Fahrbahn und die Richtungshinweise müssen dabei klar sichtbar bleiben. Dichte Pflanzen gehören vor allem neben die Straße und hinter die Kurven.

Grundlagen im Projekt: [Landschaftscode](/Users/stefan/Documents/railsapps/stuntcar/scripts/track/landscape.gd), [Waldaufnahme](/Users/stefan/Documents/railsapps/stuntcar/docs/qualitaet-kurve-forest.png), [Schluchtaufnahme](/Users/stefan/Documents/railsapps/stuntcar/docs/qualitaet-kurve-canyon.png) und [Landschaftsentwürfe](/Users/stefan/Documents/railsapps/stuntcar/assets/concepts/stuntcar-landschaften-01.png).

## Vergleich der Quellen

| Quelle | Geeignet für | Kosten und Rechte | Entscheidung für Stuntcar |
|---|---|---|---|
| [Poly Haven](https://polyhaven.com/collections/pine_forest) | Bäume, Pflanzen, Felsen, Boden | Kostenlos; CC0 | Erste Wahl. Vorhandene Modelle stammen bereits von dort. |
| [ambientCG](https://ambientcg.com/view?id=Snow002) | Schnee und andere Oberflächen | Kostenlos; CC0 | Ergänzung für den Alpenpass. |
| [cgbookcase](https://www.cgbookcase.com/textures/red-rock-01) | Rote Felsen und Felswände | Kostenlos; CC0 | Gute Ergänzung für selbst geformtes Gelände. |
| [Fab und Quixel](https://www.fab.com/sellers/Quixel%20Megascans?is_free=1&ui_filter_price=1) | Große Felsformen und Küsten | Gratis-Auswahl und bezahlte Modelle; Lizenz je Angebot | Gezielt ergänzen. Dateiformat und Lizenz beim Bezug prüfen. |
| [Blendkit, früher BlenderKit](https://www.blendkit.com/asset-gallery-detail/edf789a1-964e-4480-86a0-ac3a1205f55e/) | Ganze Geländeformen und ferne Berge | Kostenlose und bezahlte Modelle; verschiedene Lizenzen | Gute zweite Quelle. Große Modelle vor dem Einsatz vereinfachen. |
| [Unity Asset Store](https://assetstore.unity.com/packages/3d/environments/landscapes/northern-mountain-free-258730) | Einzelne Hintergrundberge | Beispiel kostenlos; Standard Unity Asset Store EULA | Reserve. Der Weg aus dem Unity-Paket braucht eine Prüfung. |
| [Sketchfab](https://sketchfab.com/3d-models/free-sandstone-f0e03cb4b2534b9dac56466a1c9c16a2) | Einzelne besondere Felsen | Beispiel kostenlos; CC BY | Reserve. Herkunft und Lizenz für jedes Modell festhalten. |
| [CGTrader](https://www.cgtrader.com/free-3d-models/exterior/landscape/free-ultimate-rock-bundle-and-bonus-4k-texture-variations) | Einzelne Felsmodelle | Gratis-Proben und bezahlte Pakete | Nur gezielte Ergänzungen. Gratis-Proben enthalten oft weniger Modelle. |
| [ShareTextures](https://www.sharetextures.com/models/nature/stone-6) | Kleine Naturmodelle | Beispiel trägt CC0 | Ergänzung für Küstendetails. Dateiformat beim Bezug prüfen. |
| [itch.io](https://itch.io/game-assets/free/tag-3d/tag-terrain) | Kleine Gelände- und Naturpakete | Unterschiedliche Preise und Rechte | Die gesichtete Auswahl passt überwiegend zu einem einfacheren Stil. |
| [Quaternius](https://quaternius.com/packs/stylizednaturemegakit.html) | Naturpakete mit vereinfachten Formen | Gratis-Teil mit CC0; zusätzliche Paketstufen | Für unseren jetzigen Stil nachrangig. Nicht das ganze Paket ist kostenlos. |
| [Kenney](https://kenney.nl/assets/nature-kit) | Naturmodelle mit einfachen Flächen | Nature Kit: 330 Dateien; CC0 | Gut für einfache Entwürfe. Zu wenig Oberflächendetail für die jetzige Richtung. |

Quaternius nennt beim Stylized Nature MegaKit 116 Modelle für das Gesamtpaket. Die kostenlose Stufe enthält laut Anbieter etwa 60 bis 70 Prozent. Diese Zahl gilt nicht als Umfang des Gratis-Pakets.

## Auswahl für den Nebelwald

Diese zwölf Kandidaten stammen von Poly Haven. Alle kosten nichts und nutzen CC0. Die Modellseiten bieten glTF an. Die Bodenoberfläche besteht aus Bilddateien für das Material.

| Nr. | Modell oder Material | Zweck im Spiel | Aufwand vor dem Einsatz |
|---|---|---|---|
| 1 | [Pine Tree 01](https://polyhaven.com/a/pine_tree_01) | Große Kiefern hinter und neben der Straße | Hoch. Geeignete Detailstufe auswählen. |
| 2 | [Fir Tree 01](https://polyhaven.com/a/fir_tree_01) | Dichte Tannen als zweite Baumform | Hoch. Geeignete Detailstufe auswählen. |
| 3 | [Pine Sapling Medium](https://polyhaven.com/a/pine_sapling_medium) | Mittlere Baumhöhe zwischen großen und kleinen Bäumen | Mittel. Größe und Material prüfen. |
| 4 | [Fir Sapling Medium](https://polyhaven.com/a/fir_sapling_medium) | Junge Tannen am Waldrand | Mittel. Ergänzt die vorhandenen jungen Kiefern. |
| 5 | [Fern 02](https://polyhaven.com/a/fern_02) | Farne nahe an Felsen und Bäumen | Gering bis mittel. Nur in sichtbaren Gruppen einsetzen. |
| 6 | [Grass Medium 01](https://polyhaven.com/a/grass_medium_01) | Gras an Übergängen zum Waldboden | Mittel. Dichte und Sichtweite begrenzen. |
| 7 | [Rock Moss Set 01](https://polyhaven.com/a/rock_moss_set_01) | Verschiedene kleine und mittlere Felsen | Gering bis mittel. Sechs Felsformen laut Produktseite. |
| 8 | [Rock Moss Set 02](https://polyhaven.com/a/rock_moss_set_02) | Weitere Felsformen ohne auffällige Wiederholung | Gering bis mittel. Mit Set 01 kombinieren. |
| 9 | [Tree Stump 01](https://polyhaven.com/a/tree_stump_01) | Einzelne Baumstümpfe am Rand | Gering. Sparsam einsetzen. |
| 10 | [Dead Tree Trunk](https://polyhaven.com/a/dead_tree_trunk) | Liegende Stämme zwischen den Bäumen | Gering. Die Fahrbahn bleibt frei. |
| 11 | [Dry Branches Medium 01](https://polyhaven.com/a/dry_branches_medium_01) | Trockene Äste für nahe Bodenbereiche | Gering. Erst nach den großen Formen ergänzen. |
| 12 | [Forest Ground 04](https://polyhaven.com/a/forest_ground_04) | Zweite Bodenoberfläche neben dem vorhandenen Waldboden | Mittel. Übergänge zwischen den Oberflächen herstellen. |

Die [Pine Forest Collection](https://polyhaven.com/collections/pine_forest) bündelt passende Quellen und bietet eine Beispielszene an. Die Szene dient als Vorlage für die Anordnung. Sie ist noch keine fertige Godot-Strecke.

Die Seite zu Pine Tree 01 nennt rund 17 Millionen Dreiecke. Diese Angabe beschreibt nicht zwingend die gewählte Importvariante. Für die Fahrt müssen wir eine vereinfachte Variante prüfen. Kleine Bilddateien allein verringern die Anzahl der Dreiecke nicht.

## Auswahl für den Alpenpass

| Nr. | Modell oder Material | Kosten und Rechte | Zweck und Grenze |
|---|---|---|---|
| 13 | [Background Mountain bei Blendkit](https://www.blendkit.com/asset-gallery-detail/924eaed7-a06b-41ca-976d-498f4353e06b/) | Kostenlos; Royalty Free | Erster Kandidat für ferne Berge. Die Seite nennt 4.096 Modellflächen. Schnee braucht eine eigene Gestaltung. |
| 14 | [Snow Mountain bei Blendkit](https://www.blendkit.com/asset-gallery-detail/71616d28-b581-4ac2-8dcb-83ad9fa23bfd/) | Kostenlos; Royalty Free | Schneebedeckter Gebirgszug. Rund 1,05 Millionen Modellflächen laut Anbieter. Vorher vereinfachen. |
| 15 | [Northern Mountain FREE](https://assetstore.unity.com/packages/3d/environments/landscapes/northern-mountain-free-258730) | Kostenlos; Standard Unity Asset Store EULA | Hintergrundberg. Der Anbieter nennt fünf Detailstufen bis hinunter zu 6.144 Dreiecken. Importweg noch offen. |
| 16 | [Snow 002 bei ambientCG](https://ambientcg.com/view?id=Snow002) | Kostenlos; CC0 | Schneeoberfläche für Boden und Schneewälle. Kein fertiges Bergmodell. |
| 17 | [Rock Face 01 bei cgbookcase](https://www.cgbookcase.com/textures/rock-face-01) | Kostenlos; CC0 | Felsoberfläche für Hänge unterhalb der Schneegrenze. Kein fertiges Felsmodell. |

Die Tannen aus Nummer 2 und 4 ergänzen diese Auswahl. Für verschneite Tannen brauchen wir zusätzlich sichtbare Schneeauflagen. Eine weiße Baumfarbe allein ergibt keinen überzeugenden Schnee.

Northern Mountain FREE ist laut Anbieter ausschließlich für den Hintergrund gedacht. Die Straße braucht weiterhin eigenes Gelände und eigene Stützen.

## Auswahl für die Felsenschlucht

| Nr. | Modell oder Material | Kosten und Rechte | Zweck und Grenze |
|---|---|---|---|
| 18 | [Rock Face 02 bei Poly Haven](https://polyhaven.com/a/rock_face_02) | Kostenlos; CC0; glTF | Geschichtete Felswand. Die vorhandenen Moosstellen passen eher zu feuchten Abschnitten. |
| 19 | [Canyon Desert Landscape bei Blendkit](https://www.blendkit.com/asset-gallery-detail/edf789a1-964e-4480-86a0-ac3a1205f55e/) | Kostenlos; Royalty Free | Große Schlucht als Hintergrund. 571.749 Modellflächen laut Anbieter. Vorher vereinfachen. |
| 20 | [Sandstone Cliffs bei BlenderKit](https://www.blenderkit.com/asset-gallery-detail/37caa53b-2c45-470a-9b9d-a1aacaf7e343/) | Als kostenlos ausgewiesen; genaue Lizenz noch prüfen | Sandsteinwände als Reserve. Das ausgelesene Lizenzfeld nennt den Lizenztyp nicht. |
| 21 | [Sandstone Cracks bei Poly Haven](https://polyhaven.com/a/sandstone_cracks) | Kostenlos; CC0 | Helle Sandsteinoberfläche für eigene Geländeformen. |
| 22 | [Red Rock 01 bei cgbookcase](https://www.cgbookcase.com/textures/red-rock-01) | Kostenlos; CC0 | Rote Felsoberfläche. Passt zur Farbwahl des Schluchtentwurfs. |
| 23 | [Desert American Rock Cliff Sandstone Large 02 bei Fab](https://www.fab.com/listings/2aa4aa16-f242-4613-ac2e-0755bc84d7ca) | Preis und konkrete Lizenz offen; FBX und glTF | Große Felswand. Der Anbieter nennt etwa 64 × 67 × 42 Meter. Nur als mögliche Ergänzung vormerken. |
| 24 | [FREE ULTIMATE ROCK BUNDLE bei CGTrader](https://www.cgtrader.com/free-3d-models/exterior/landscape/free-ultimate-rock-bundle-and-bonus-4k-texture-variations) | Kostenlos; Royalty Free License mit Zusatz „no AI“; OBJ | Die Gratis-Probe enthält zwei Felsvarianten. Die 13 beworbenen Formen gehören zum Gesamtpaket. |
| 25 | [Free SandStone bei Sketchfab](https://sketchfab.com/3d-models/free-sandstone-f0e03cb4b2534b9dac56466a1c9c16a2) | Suchindex nennt kostenlos und CC BY | Einzelner Fels mit etwa 24.500 Dreiecken. Die Produktseite ließ sich nicht direkt öffnen. Vor dem Einsatz erneut prüfen. |

Für die Schlucht sind große zusammenhängende Formen besonders wichtig. Kleine Felsen allein ersetzen keine hohen Wände und tiefen Täler. Rote Oberflächen auf den bisherigen einfachen Formen sind nur ein Zwischenschritt.

## Auswahl für die Regenküste

| Nr. | Modell oder Material | Kosten und Rechte | Zweck und Grenze |
|---|---|---|---|
| 26 | [Coast Rocks 01 bei Poly Haven](https://polyhaven.com/a/coast_rocks_01) | Kostenlos; CC0; glTF | Felsen mit erodierten Formen für den nahen Küstenbereich. |
| 27 | [Coast Rocks 05 bei Poly Haven](https://polyhaven.com/a/coast_rocks_05) | Kostenlos; CC0; glTF | Größere Vorsprünge und unterspülte Felsen. |
| 28 | [Coast Line 01 bei Poly Haven](https://polyhaven.com/a/coast_line_01) | Kostenlos; CC0; glTF | Zusammenhängender Uferabschnitt zwischen Land und Wasser. |
| 29 | [Coast Sand Rocks 02 bei Poly Haven](https://polyhaven.com/a/coast_sand_rocks_02) | Kostenlos; CC0 | Bodenoberfläche zwischen den Küstenfelsen. |
| 30 | [Nordic Coastal Cliff bei Fab](https://www.fab.com/listings/35d695d8-ac00-4ac5-8bba-1d46e973af68) | Seite zeigt kostenlos; FBX, GLB und glTF; Lizenz beim Bezug bestätigen | Kantiger Küstenfels. Das konkrete Modell misst nur etwa 1 × 2,6 × 4,1 Meter. Keine ganze Steilküste. |
| 31 | [Stone 6 bei ShareTextures](https://www.sharetextures.com/models/nature/stone-6) | CC0; kostenloses Quellenangebot; Dateiformat offen | Kleiner Strandstein mit ausgewaschenen Löchern. Ergänzung für nahe Bereiche. |

Die Küste braucht zusätzlich Wasserbewegung, Schaum und nasse Oberflächen. Diese Auswahl liefert dafür noch kein fertiges System. Der vorhandene Leuchtturm kann zunächst bleiben. Eine fertige Küstenlandschaft entsteht erst durch die Anordnung und die Wasserübergänge.

## Rechte und Dateiformate

CC0 erlaubt die Nutzung und Bearbeitung ohne Pflicht zur Namensnennung. Die Quellen bleiben trotzdem in unserem Herkunftsverzeichnis. Das erleichtert spätere Änderungen. Quellen: [Poly Haven](https://polyhaven.com/license), [ambientCG](https://docs.ambientcg.com/license/) und [cgbookcase](https://www.dorianzgraggen.com/projects/cgbookcase/).

Die [Fab Standard License](https://www.fab.com/eula?lang=en) erlaubt die Nutzung mit kompatiblen Programmen. Sie beschränkt die Nutzung nicht grundsätzlich auf Unreal Engine. Sie erlaubt jedoch keinen freien Weitervertrieb der einzelnen Quelldateien. Die konkrete Lizenz eines Angebots bleibt entscheidend.

Epics [Mitteilung vom 2. Januar 2025](https://forums.unrealengine.com/t/megascans-starter-content-on-fab/2255322) nennt über 1.500 kostenlose Megascans-Inhalte. Die dort genannten Baum- und Szenenpakete richten sich an Unreal Engine. Diese ältere Zahl belegt keinen heutigen Umfang und keinen fertigen Godot-Import.

[Blendkit](https://www.blendkit.com/docs/licenses/) unterscheidet CC0 und Royalty Free. Royalty Free erlaubt die kommerzielle Verwendung im Werk. Es erlaubt keinen Weiterverkauf des Modells als Modellpaket. Deshalb behandeln wir diese Quellen anders als CC0-Dateien.

Für Modelle bevorzugen wir glTF oder GLB. Beide Formate gehören zu glTF 2.0. Godot empfiehlt dieses Format. Blender-Dateien können eine Umwandlung benötigen. Die Dateiendung allein garantiert jedoch keine passenden Materialien. Quelle: [Godot zu den 3D-Dateiformaten](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

## Vorgeschlagene Reihenfolge für den Einbau

Zuerst entsteht ein kurzer Waldabschnitt als Maßstab für alle weiteren Landschaften. Dafür reichen etwa 150 bis 250 Meter. Dieser Abschnitt zeigt große Bäume, kleine Pflanzen, echte Felsen und Bodenübergänge zusammen.

1. Beziehe Pine Tree 01 und Fir Tree 01 in geeigneten Detailstufen.
2. Ergänze Rock Moss Set 01, Fern 02 und Grass Medium 01.
3. Ersetze die einfachen nahen Felsen im Testabschnitt.
4. Ergänze einen zusammenhängenden Hang hinter den Felsen.
5. Prüfe die Szene aus der tatsächlichen Fahrkamera.
6. Miss die Bildzeiten während einer Fahrt.

Danach folgt die Küste mit den Nummern 26 bis 29. Diese vier Quellen bieten einen klaren nächsten Ausbau ohne neue Anbieter. Anschließend folgen die Alpen mit einem Hintergrundberg und Schnee. Die Schlucht folgt mit einer vereinfachten Geländeform und passenden Felsoberflächen.

Für den ersten Import reichen meist Bilddateien mit 1.024 oder 2.048 Pixeln Seitenlänge als Ausgangspunkt. Das ist ein vorgeschlagener Startwert. Die Fahrkamera bestimmt den nötigen Detailgrad. Große Felswände können andere Werte brauchen.

Entfernte Modelle erhalten weniger Details. LOD bezeichnet solche Detailstufen nach Entfernung. Viele gleichartige Pflanzen sollen gemeinsame Modelldaten nutzen. Ihre Zahl, Schatten und Sichtweite brauchen eine Messung im Spiel.

Bei jedem Import halten wir Quelle, Urheber, Lizenz, Variante und Änderungen fest. Die vorhandene Prüfung auf Abstand zur Fahrbahn bleibt notwendig. Hohe neue Geländeformen brauchen zusätzlich eine Sichtprüfung vor Kurven und Sprüngen.

## Offene Arbeit

Die Recherche liefert die Quellen und die Reihenfolge. Sie enthält noch keinen Import der neuen Modelle. Ein Importtest muss Materialdarstellung, Größe, Dateiumfang und Bildzeiten bestätigen.

Offen bleiben vor allem Schnee auf Bäumen, Wasser und Schaum, zusammenhängendes Gelände sowie die genaue Lizenz einzelner Reservemodelle. Diese Punkte brauchen eigene Arbeitsschritte. Ein großes Gratis-Paket löst sie nicht automatisch.
