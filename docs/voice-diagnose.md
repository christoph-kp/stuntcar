# Mikrofontest

1. Schließe eine bereits offene Spielinstanz.
2. Öffne `Mikrofon testen.command`.
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

## Bisheriger Befund

Die Kalibrierung speichert den höchsten Pegel des ganzen Wortes.
Ein Befehl nutzt den höchsten Pegel der letzten 450 Millisekunden.
Ein kontrollierter Versuch zeigt den Unterschied:
Ein Anfangspegel von 6.000 ergibt nach einem längeren leisen Wortende einen Befehlspegel von 700.
Diese unterschiedlichen Messungen können die Stufe senken.
Der Versuch belegt noch nicht die Ursache an Stefans Mikrofon.
Der Mikrofontest soll diese Ursache prüfen.

Die normalen Starts erstellen keinen Bericht.
