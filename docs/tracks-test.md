# Prüfung der drei Strecken

Stand: 15. Oktober 2026. Godot 4.5.1 auf diesem Mac.

## Ergebnis

Alle elf Godot-Prüfprogramme melden null fehlgeschlagene Prüfungen. Die 15 Python-Prüfungen der Spracheingabe bestehen ebenfalls.

| Bereich | Prüfungen |
|---|---:|
| Grundregeln | 27 |
| Tasten | 12 |
| Randnähe und Korrektur | 13 |
| Spracheingabe | 10 |
| Sprachverbindung | 12 |
| Sprachbefehle in der Spielszene | 10 |
| Strecken, Vorlage und Sprungkorrekturen | 66 |
| Steuerungswahl und gespeicherte Auswahl | 9 |
| Sprünge mit dem sichtbaren Fahrzeug | 44 |
| Tempo und Steilkurven | 62 |

Zusätzlich fährt die bisherige Szenenprüfung die erste Strecke bis zum Ziel. Sie prüft auch den Fall und den erneuten Start ohne Menü.

## Fahrten

Die Tests geben vor jeder Kurve einmal die passende Richtung vor. Sie verändern das Tempo während der Fahrt nicht. Das Fahrzeug erreicht auf allen drei Strecken das Ziel.

| Strecke | 50 km/h | 79 km/h | 101 km/h |
|---|---:|---:|---:|
| Erste Fahrt | 43,1 s | 27,4 s | 21,6 s |
| Höhenfahrt | 90,0 s | 57,2 s | 45,0 s |
| Sprungstrecke | 97,1 s | 61,8 s | 48,5 s |

Die Höhenfahrt enthält einen Sprung. Die Sprungstrecke enthält zwei Sprünge. Das Fahrzeug überfliegt alle Lücken bei jedem geprüften Tempo. Eine Pause hält auch die Flugbewegung an. Die Fahrt setzt danach denselben Sprung fort.

Die Korrekturprüfung setzt das Auto vor dem Sprung seitlich versetzt auf die Strecke. Ein kurzer Druck zur Mitte korrigiert die Landung. Eine weitere Prüfung gibt den Befehl erst einen Meter vor dem Ende des Sprungs. Weitere Fälle prüfen Befehle 8 und 18 Meter nach der Landung. Das Auto bleibt danach bis 80 Meter hinter der Landung auf der Geraden. Diese Prüfung umfasst beide Seiten.

Die Codeprüfung fand einen Restwinkel nach einer späten Korrektur. Die Hilfe richtet das Auto nun am Ende an der Geraden aus. Die neue Prüfung bestätigt die Weiterfahrt. Die Codeprüfung fand außerdem feste Tastennamen in der Steuerungswahl. Die Anzeige nutzt nun die gewählten Tasten.

## Auswahl und Speicherung

Ein Start ohne gespeicherte Steuerung öffnet die Steuerungswahl. Die Tastenwahl führt zum Startmenü. Die Streckenauswahl aktualisiert die Fahrbahn und das Fahrmodell gemeinsam. Ein zweiter Start übernimmt die gespeicherte Strecke und die Steuerung. Die Steuerungswahl aus den Einstellungen kehrt zu den Einstellungen zurück.

Die bisherigen Sprachprüfungen prüfen weiterhin die Befehlsübertragung und wiederholte Korrekturen. Diese Änderung enthält keinen neuen Versuch mit einem echten Mikrofon. Der erste Start der Sprache kann eine Mikrofonfreigabe verlangen.

## Sichtprüfung

Godot hat die Bilder in diesem Ordner direkt aus der Spielansicht erzeugt. Geprüft wurden die erste Steuerungswahl und die Flugansicht der neuen Strecken. Die Fahrbahn enthält sichtbare Lücken. Die Kamera zeigt das Auto und die Landung. Felsen stehen nicht mehr auf der Fahrbahn.

Die Tests ohne Fenster liefen in der eingeschränkten Prüfumgebung. Godot meldete dabei einen Fehler beim Lesen der macOS-Systemzertifikate. Die Prüfprogramme liefen vollständig und endeten erfolgreich. Die Sichtprüfung außerhalb dieser Einschränkung meldete diesen Fehler nicht.

Die Fahrtests belegen die technische Funktion. Sie belegen noch nicht den Spaßfaktor. Dafür braucht es einen Spieltest mit den vorgesehenen Spielern.

## Steilkurven und Tempobefehle

Die drei Strecken enthalten Neigungen zwischen 12 und 40 Grad. Der optionale Wert `bank_degrees` steht auch in der Vorlage. Ohne diesen Wert bleibt die Fahrbahn quer eben. Die Prüfung weist Werte über 45 Grad ab.

Das Fahrzeug folgt der Fahrbahn in Höhe, Querneigung und Längsneigung. Die Längsneigung berücksichtigt auch die seitliche Position. Die Sichtprüfung zeigt eine Steilkurve und die Tempoanzeige. Die Bilder heißen `preview-bank-580.png`, `preview-bank-290.png` und `preview-speed.png`.

Der Tempobereich reicht nun von 14 bis 46 Metern pro Sekunde. Das entspricht etwa 50 bis 166 km/h. Jeder Tempobefehl verändert das Ziel um fünf Meter pro Sekunde. Das entspricht etwa 18 km/h. Die Grenzen begrenzen den letzten Schritt. Die Anzeige bestätigt auch das Erreichen einer Grenze.

Bei hohem Tempo erhöht das Fahrmodell die Randnähe. Der Test vergleicht dafür dieselbe Kurve bei normalem und hohem Tempo. Bei 166 km/h erreichen alle drei Strecken mit kurzen Korrekturen das Ziel. Der Modelltest benötigt drei zusätzliche Korrekturen auf der ersten Strecke. Die beiden weiteren Strecken benötigen jeweils fünf. Die Szenenprüfung bestätigt auch alle Sprünge bei diesem Tempo.

Die neuen künstlichen Sprachproben prüfen fünf Wiederholungen von „schneller“, „langsamer“, „faster“ und „slower“. Sie prüfen außerdem „schneller schneller langsamer langsamer“ mit 200 und 280 Wörtern pro Minute. Alle Wörter kommen jeweils einmal an.

Vor der Änderung gingen die beiden Bremsbefehle in der gemischten Folge verloren. Der freie Erkenner lieferte „langsame“. Der eingeschränkte Erkenner lieferte korrekt „langsamer“. Die Bestätigung akzeptiert nun diese Abweichung. Sie verlangt weiterhin einen passenden Befehl aus dem eingeschränkten Erkenner. Ein weiterer Test prüft, dass die Abweichung allein und eine verneinte Äußerung keinen Befehl auslösen.

Die Szenenprüfung sendet zwei Gasbefehle und zwei Bremsbefehle durch die Sprachverbindung. Jeder Befehl verändert das Zieltempo. Die Anzeige bestätigt das Zieltempo.

Die Sprachproben enthalten keine Mikrofonaufnahmen. Der Test mit der Stimme des Spielers steht weiterhin aus.
