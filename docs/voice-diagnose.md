# Mikrofontest

1. Schließe eine bereits offene Spielinstanz.
2. Öffne `tools/macos/Mikrofon testen.command`.
3. Klicke in der Sprachübung auf **Start**.
4. Führe die drei Schritte der Kalibrierung durch.
5. Sprich die angezeigten Wörter zuerst normal und dann laut.
6. Wiederhole die Sprachübung bei Bedarf.
7. Schließe das Spiel.

Der Start erstellt für jeden Test eine eigene Datei unter `reports/voice/`.
Die Datei enthält Messwerte und erkannte Befehle.
Die Datei enthält keine Tonaufnahme und keine freien Gesprächsinhalte.
Der Test nutzt dieselbe Erkennung, Kalibrierung und Steuerung wie das Spiel.
Der Test ändert die Berechnung der Lautstärke nicht.

Der Bericht enthält diese Daten:

| Eintrag | Bedeutung |
| --- | --- |
| `packet` | Die Erkennung meldet einen Pegel oder einen Befehl. |
| `state` | Das Spiel meldet das Mikrofon, das Profil und den Schritt der Kalibrierung. |
| `command_result` | Das Spiel meldet die berechnete Stärke und die Balkenzahl. |
| `profile_reason` | Der Wert erklärt, ob das Spiel das Profil nutzt. |
| `end` | Das Spiel hat den Bericht geschlossen. |
| `limit` | Der Bericht hat die Grenze von 20.000 Einträgen erreicht. |

`calibrated` bedeutet: Das Spiel nutzt das Profil.
`missing_profile` bedeutet: Das Profil fehlt oder enthält ungültige Werte.
`invalid_signal` bedeutet: Der Befehl enthält keinen gültigen Rohpegel.
`device_mismatch` bedeutet: Das aktuelle Mikrofon passt nicht zum gespeicherten Profil.

Die Datei enthält Zeitabstände und die Reihenfolge der Nachrichten.
Damit können wir den gemessenen Pegel mit dem Pegel des Befehls vergleichen.
Die Zahl `bars` beschreibt die berechnete Stufe.
Die Anzeige hängt zusätzlich vom Spielzustand ab.
Der Wert `accepted` zeigt, ob das Spiel den Befehl angenommen hat.

## Bestätigter Fehler und Korrektur

Der Bericht vom 16. Oktober zeigt den Pegelverlust bei echten Befehlen.
Bei einem „right“ fällt der verwendete Pegel von 5.781 auf 511.
Bei einem „faster“ fällt er von 5.525 auf 2.237.
Das Profil bleibt währenddessen gleich.
Das Spiel nutzt das richtige Mikrofon und das gespeicherte Profil.

Bisher behält ein Befehl nur den höchsten Pegel der letzten 450 Millisekunden.
Die Erkennung gibt manche Befehle später aus.
Dann fehlt der laute Anfang des Wortes in dieser Messung.
Die Kalibrierung behält dagegen den höchsten Pegel des ganzen Wortes.

Die Korrektur behält den höchsten Pegel bis zur Ausgabe des Befehls.
Danach beginnt die Messung für den nächsten Befehl neu.
Das kurze Messfenster bleibt zusätzlich erhalten.
Es schützt den Anfang eines Folgewortes, das schon vor der vorherigen Erkennung beginnt.
Eine Sprechpause oder ein Wechsel der Übung löscht einen noch nicht zugeordneten Pegel.
Die Korrektur fügt keine Wartezeit hinzu.
Mehrere Befehle aus demselben Verarbeitungsschritt teilen sich den gemessenen Pegel.
Die Live-Anzeige behält ihr kurzes Messfenster.
Die Bestätigung am Pfeil nutzt den erhaltenen Befehlspegel.
Bei sehr schnellen Befehlen können sich die Messungen der Wörter überlappen.
Die Messung ordnet dann nicht jeden Pegel eindeutig einem Wort zu.

Die normalen Starts erstellen keinen Bericht.
