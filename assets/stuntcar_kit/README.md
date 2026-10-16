# Stuntcar: 3D-Bauteile

Dieses Paket enthält 44 Bauteile für Godot 4.5.1.
Die Modelle nutzen einfache Flächen. Sie haben weniger Details als die Bildentwürfe.
Die sieben Beispielszenen zeigen die Modelle direkt in Godot.
Das Paket braucht keine fremden Modelle, Bilddateien oder Erweiterungen.

## Inhalt

| Ordner | Anzahl | Inhalt |
|---|---:|---|
| vehicle | 1 | Orangefarbenes Auto mit vier getrennten Rädern |
| track | 9 | Gerade, zwei Kurven, zwei Steilkurven, Sprungrampe, Landerampe, Kuppe, Looping |
| shared | 3 | Randpfosten, Brückenstütze, Streckentor |
| alpine | 8 | Zwei Schneetannen, zwei Felsen, Felswand, Bodenplatte, Berggruppe, Schneewall |
| forest | 8 | Zwei Tannen, zwei Felsen, Felswand, Bodenplatte, Baumstamm, Strauch |
| canyon | 6 | Zwei Felsen, Felswand, Bodenplatte, Tafelberg, Felsturm |
| coast | 7 | Zwei Felsen, Felswand, Bodenplatte, Leuchtturm, Wasserfläche, Schaumkante |
| weather | 2 | Schneefall und Regen |

Die Datei `catalog.json` enthält die einzelnen Dateinamen.
Der Ordner `materials` enthält 28 gemeinsame Materialien.
Eine Änderung an einer Materialdatei wirkt auf alle Teile mit diesem Material.
Erstelle für eine örtliche Änderung zuerst eine eigene Kopie des Materials.

## Vorschau öffnen

Auf diesem Mac öffnet `tools/macos/Bauteile ansehen.command` die Vorschau im Godot-Editor.

1. Öffne das vorhandene Projekt in Godot.
2. Öffne `assets/stuntcar_kit/examples/stunt_preview.tscn`.
3. Drücke F6 für die Vorschau.

Die Datei `track_gallery.tscn` zeigt alle neun Streckenteile.
Die Datei `vehicle_studio.tscn` zeigt das Auto aus der Nähe.
Die vier Dateien mit dem Ende `_preview.tscn` zeigen Alpen, Wald, Schlucht und Küste.
Die zusätzliche Datei `stunt_preview.tscn` zeigt den Looping mit Steilkurve und Sprung.
Diese Szenen zeigen die Modelle. Sie enthalten keine Fahrsteuerung.
Die PNG-Dateien unter `previews` stammen aus Godot.

## Einbau in ein anderes Projekt

1. Kopiere den ganzen Ordner `assets/stuntcar_kit` in das andere Godot-Projekt.
2. Behalte den Ordnerpfad bei.
3. Ziehe die gewünschte TSCN-Datei in eine 3D-Szene.

Die TSCN-Dateien enthalten gespeicherte Geometrie.
Der Einbau braucht keinen Erzeugungscode.
Godot kann die einzelnen Knoten und Materialien bearbeiten.
Das Paket enthält keine GLB-Dateien und keine Blender-Dateien.

## Maße und Anschlüsse

Eine Einheit entspricht einem Meter.
Die Y-Achse zeigt nach oben. Die Fahrtrichtung zeigt entlang der lokalen Achse -Z.
Die Fahrbahn ist sechs Meter breit. Die seitlichen Markierungen liegen innerhalb dieser Breite.
Der Anfang der Fahrbahn liegt am Ursprung jedes Streckenteils.
Die Marker `Entry` und `Exit` geben den Anfang und das Ende an.
Ihre lokale Achse -Z zeigt in die Fahrtrichtung. Ihre lokale Achse Y zeigt zur Fahrbahnoberseite.
Die Landerampe beginnt mit einer Neigung von 18 Grad nach unten.
Ihr Marker `Entry` hat deshalb eine andere Drehung als der Ursprung.

Diese Formel verbindet zwei Teile unter demselben übergeordneten Knoten:

```gdscript
next_part.transform = previous_part.transform \
    * previous_part.get_node("Exit").transform \
    * next_part.get_node("Entry").transform.affine_inverse()
```

Für eine Lücke zwischen Sprungrampe und Landerampe braucht die Landerampe eine eigene Position.
Die Sprungvorschau zeigt eine Lücke von zwölf Metern.
Diese Lücke legt noch keine geeignete Geschwindigkeit fest.
Prüfe den Flug später mit der tatsächlichen Fahrsteuerung.

| Teil | Maße |
|---|---|
| Gerade | Länge 24 m |
| Flache Kurven | Winkel 45 Grad; Radius der Mittellinie 28 m |
| Steilkurven | Winkel 90 Grad; Radius 28 m; seitliche Neigung bis 45 Grad |
| Sprungrampe | Horizontale Länge 18 m; Ausfahrt 18 Grad nach oben; Höhe etwa 2,92 m |
| Landerampe | Horizontale Länge 18 m; Einfahrt 18 Grad nach unten; Abstieg etwa 2,92 m |
| Kuppe | Länge 32 m; Höhe 3 m |
| Looping | Vertikaler Radius 12 m; Höhe 24 m; seitlicher Versatz 9 m |

Die Steilkurven beginnen und enden ohne seitliche Neigung.
Der seitliche Versatz trennt die Einfahrt und die Ausfahrt des Loopings.
Die Mittellinie und die Oberseitenrichtungen stehen in den Metadaten `centerline` und `up_vectors`.
Die Fahrbahnen enthalten eine Dreiecksfläche für die Kollision auf Ebene 1.
Der Unterbau und die Landschaftsteile enthalten keine Kollision.
Die Brückenstütze reicht vom Ursprung acht Meter nach unten.
Passe ihre Höhe an das jeweilige Gelände an.

## Auto und Licht

Das Auto ist etwa 3,3 m lang, 2 m breit und 1,4 m hoch.
Die Knoten `WheelFL`, `WheelFR`, `WheelRL` und `WheelRR` enthalten die vier Räder.
Die Vorderachse liegt bei Z = -1 m. Die Hinterachse liegt bei Z = 1 m.
Der Radradius beträgt 0,4 m. Die Räder drehen um ihre lokale X-Achse.
Ein Spielobjekt mit Fahrsteuerung kann die Autoszene als sichtbares Kind enthalten.
Das Modell selbst enthält weder Fahrsteuerung noch Fahrzeugkollision.

Lack, Glas, Gummi, Metall, Scheinwerfer und Rückleuchten haben getrennte Materialien.
Die Leuchten nutzen selbstleuchtende Materialien.
Sie beleuchten die Umgebung noch nicht.
Die Marker `HeadlightSocketLeft` und `HeadlightSocketRight` dienen als Anschlüsse für Scheinwerfer.
Der Leuchtturm enthält dafür den Marker `LightSocket`.
Spiegelungen und Lichtschein hängen zusätzlich von den Lichtern und der Umgebung der Spielszene ab.
Die Wasserfläche ist statisch. Sie enthält keine Wellenbewegung.

## Wetter

Schnee und Regen nutzen die Godot-Funktion `CPUParticles3D`.
Diese Funktion bewegt viele kleine Flächen oder Körper.
Schnee nutzt 360 kleine Körper. Regen nutzt 600 schmale Flächen.
Setze die Wetterquelle etwa sieben Meter über das Auto.
Bewege die Quelle mit der Kamera. Die bereits erzeugten Teilchen bleiben im Raum.
Das Wetter verändert weder die Haftung noch die Fahrsteuerung.
Die Beispielszenen enthalten festen Nebel für Wald und Küste.
Die Nebelfunktion gehört zur Umgebung der Szene, nicht zum Landschaftsmodell.

## Grenzen des ersten Pakets

Das bestehende Spiel lädt diese Bauteile noch nicht automatisch.
Die bisherige Fahrsteuerung folgt einer anderen Streckenbeschreibung.
Sie braucht eine Erweiterung für die vollständige Drehung im Looping.
Die Kameraführung braucht dafür ebenfalls eine Prüfung.
Eine geometrisch passende Fahrbahn beweist noch keinen sicheren Fahrverlauf.
Die Vorschauen belegen die Darstellung auf diesem Mac, aber noch keine feste Bildrate für größere Strecken.

## Erneut erzeugen und prüfen

Der Erzeugungscode liegt unter `tools/assets` im Projekt.
Er ersetzt die Dateien des Pakets bei jedem Aufruf.
Bewahre eigene Änderungen deshalb in getrennten Dateien auf.

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/stuntcar-assets-build.log --path . --script tools/assets/build_kit.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --log-file /tmp/stuntcar-assets-check.log --path . --script tests/assets/check_kit.gd
.tools/Godot.app/Contents/MacOS/Godot --log-file /tmp/stuntcar-assets-capture.log --path . --script tools/assets/capture_kit.gd
```

Der letzte Aufruf öffnet ein Grafikfenster.
Die Prüfung kontrolliert Geometrie, Materialdateien, Räder, Wetter und Streckenanschlüsse.
Sie prüft außerdem die Kollision an der Oberseite des Loopings und die Neigung der Steilkurven.

## Prüfergebnis vom 15. Oktober 2026

Die Asset-Prüfung meldet 2881 Prüfungen und null Fehler.
Die Prüfungen für Strecken, Spielszene, Sprünge sowie Tempo und Steilkurven liefen ebenfalls ohne Fehler.
Eine zweite Prüfung fand keine wichtigen Fehler.
Die Grafikprüfung nutzte Godot 4.5.1 mit dem Grafikmodus Compatibility auf einem Apple M4 Pro.
Die Prüfung ohne Grafikfenster meldete zusätzlich einen Fehler beim Zugriff auf die Zertifikate von macOS.
Dieser Zugriff gehört nicht zu den Bauteilen. Die Tests liefen bis zum Ende.
