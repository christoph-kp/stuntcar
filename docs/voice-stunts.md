# Sprachsteuerung und Fahrgefühl

Die persönliche Kalibrierung bestimmt die drei Stufen.
Die Pfeile zeigen dieselbe Stufe, die das Auto verwendet.

| Befehl | Ein Balken | Zwei Balken | Drei Balken |
| --- | --- | --- | --- |
| `left` / `right` | Kleine Korrektur | Normale Lenkung | Starke Lenkung |
| `faster` / `fast` | Kleine Tempoerhöhung | Normale Tempoerhöhung | Tempoerhöhung und kurzer Turbo |
| `slower` | Kleine Temposenkung | Normale Temposenkung | Vollbremsung bis zum Stillstand |

Nach einer Vollbremsung fährt das Auto mit `faster` wieder an.
Dafür reicht ein leiser Befehl.
Ein Bremsbefehl beendet einen laufenden Turbo.
Der Turbo dauert 1,2 Sekunden.
Ein weiterer lauter Befehl verlängert ihn nicht.
Nach 2,8 Sekunden ab dem Start kann ein neuer Turbo beginnen.
Die normale Höchstgeschwindigkeit beträgt 46 Meter pro Sekunde.
Der Turbo erlaubt kurz bis zu 58 Meter pro Sekunde.

Die Vorderreifen und die Karosserie zeigen den Lenkeinschlag.
Bei schnellen Kurven dreht sich die Karosserie sichtbar zur Kurveninnenseite.
Die Vorderreifen lenken dabei sichtbar gegen den Drift.
Reifenrauch verstärkt den Eindruck des Rutschens.
Die vorhandene Kurvenhilfe und die tatsächliche Fahrspur bleiben erhalten.
Der sichtbare Drift beginnt oberhalb von 26 Metern pro Sekunde.

Der Turbo erzeugt Auspuffflammen und erweitert den Blickwinkel.
Die Karosserie hebt sich vorne etwas an.
Die Vollbremsung senkt die Karosserie vorne ab und erzeugt Reifenrauch.
In der Luft erzeugen die Reifen keinen Rauch.
Eine Vollbremsung in der Luft wirkt nach der Landung.
Dadurch bleibt das Auto nicht im Sprung stehen.

Eine Pause hält die Zeit des Turbos an und unterbricht die sichtbaren Effekte.
Ein Neustart löscht den Turbo, die Vollbremsung und den Drift.

Die Bilder zeigen die echte Godot-Szene mit künstlich eingegebenen Befehlen:

- [Turbo](stunt-boost.png)
- [Drift](stunt-drift.png)
- [Vollbremsung](stunt-brake.png)
