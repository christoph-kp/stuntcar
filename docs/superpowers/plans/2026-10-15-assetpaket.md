# 3D-Bauteile für Stuntcar

## Auftrag
Stefan hat die Bildentwürfe bestätigt und braucht echte Bauteile für Godot.
Das Paket enthält ein Auto, vier Landschaftsgruppen und Streckenteile.
Die Streckenteile unterstützen Sprünge, Loopings und Steilkurven als Geometrie.
Die bestehende Fahrsteuerung bleibt eine getrennte Aufgabe.

## Maße und Dateien
- Godot 4.5.1; bestehender Grafikmodus Compatibility.
- Eine Einheit entspricht einem Meter. Y zeigt nach oben. Die Fahrtrichtung zeigt nach -Z.
- Die Fahrbahn ist sechs Meter breit. Der Anfang jedes Streckenteils liegt bei (0, 0, 0).
- Marker Entry und Exit geben die Anschlüsse an. Ihre lokale -Z-Achse zeigt in Fahrtrichtung.
- Die Dateien liegen unter assets/stuntcar_kit. Die Szenen enthalten echte gespeicherte Geometrie.
- Die Materialien liegen getrennt vor. Kein fremdes Modell und keine externe Bibliothek sind nötig.
- Das Auto erhält vier getrennte Räder und getrennte Materialien für Licht und Oberflächen.
- Die Vorschau zeigt die Bauteile in Godot. Sie nutzt keine erzeugten Konzeptbilder als Geometrie.

## Schritte
- [x] Ladeprüfung und geometrische Prüfungen erstellen. Fehlende Bauteile müssen den Test scheitern lassen.
- [x] Gemeinsame Materialien und wiederverwendbare Formen erstellen.
- [x] Das Auto, Streckenteile und Landschaftsteile erzeugen.
- [x] Die Übersichtsszene und vier Landschaftsbeispiele erstellen.
- [x] Den Import und die Anschlüsse prüfen. Die Kollision an der Looping-Oberseite prüfen.
- [x] Bilder aus Godot erstellen und sichtbar prüfen.
- [x] Eine Anleitung und ein Dateiverzeichnis schreiben.

## Prüfpunkte
Ein fehlendes Material darf keine weiße Ersatzfläche erzeugen.
Der Looping darf sich am unteren Ende nicht schneiden.
Die Fahrbahn muss an den Anschlüssen ohne Versatz passen.
Die Steilkurve beginnt und endet ohne seitliche Neigung.
Die Kollision muss im Looping nach innen zeigen.
Alle vier Landschaften brauchen eine erkennbare Formensprache.
Die Bilder sind eine Formvorlage. Dieses erste Paket nutzt weniger Einzelheiten als die Bilder.

## Arbeitsstand
Das Projekt hat kein Git-Verzeichnis. Die neuen Dateien liegen getrennt vom bestehenden Spielcode.

## Ergebnis
44 Bauteile, 28 Materialien und sieben Beispielszenen liegen vor.
Die Asset-Prüfung meldet 2881 Prüfungen ohne Fehler.
Die Prüfungen für Strecken, Spielszene, Sprünge und Tempo liefen ohne Fehler.
Eine zweite Prüfung fand keine wichtigen Fehler.
Die Bildprüfung führte zu einer Korrektur der Brückenstützen.
Ein zusätzlicher Test prüft jetzt den Abstand zur Fahrbahndecke.
Die Modelle haben weniger Details als die Konzeptbilder.
Die Fahrsteuerung für den Looping gehört nicht zu diesem Paket.
