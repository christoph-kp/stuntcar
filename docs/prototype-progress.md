# Umsetzung des Godot Prototyps

Plan: docs/superpowers/plans/2026-10-15-godot-prototyp.md

- Umfang: Strecke, Auto, Richtungseingaben und Menüs mit zwei Tasten. Sprache folgt später, wie von Stefan gewünscht.
- Entscheidung: Arbeit direkt im neuen Projektordner. Es gibt noch kein Git-Repository und keinen vorhandenen Spielcode.
- Entscheidung: Godot 4.5.1 liegt nur unter `.tools`. Die Anwendung verändert keine vorhandene Godot-Installation.
- Schnittstellen: Streckendaten liefern Abschnitt und Fahrbahnprojektion an das Fahrmodell. Die Oberfläche sendet Befehle an die Zustandsverwaltung.
- Ablauf: Zuerst Prüfungen der Richtungseingaben. Danach Fahrzeugbewegung, Darstellung und vollständige Bedienung.
- Stand: Der erste Prototyp mit Tastensteuerung ist umgesetzt.
- Godot: 4.5.1, Darstellung mit „Compatibility“, Fahrzeugberechnung mit 60 Schritten pro Sekunde.
- Strecke: 600 Meter, drei Kurven, eine kleine Kuppe, Stützen und Richtungsschilder.
- Auto: selbst erzeugte Körper, echte Bodenkollision und sichtbarer Fall.
- Lenkhilfe: Eine passende Eingabe gilt nur für eine Kurve. Ohne Eingabe bleibt die Richtung unverändert.
- Bedienung: Start, Fahrt, Pause, Fortsetzung, erneuter Versuch, Einstellungen und Ergebnis. Eine Maus bleibt optional.
- Einstellungen: Zwei unterschiedliche Tasten, drei Hinweiszeiten und abschaltbarer Ton.
- Schnittstellenänderung: `TrackData` hält die Streckendaten. `TrackBuilder` erzeugt daraus die sichtbare Strecke und die Bodenkollision.
- Schnittstellenänderung: `CommandRouter.press()` verarbeitet die Tasten. Die getrennten Sprachbefehle folgen mit der Sprachsteuerung.
- Prüfung: 27 Prüfungen der Spielregeln und zwölf Prüfungen der Tasteneingaben bestehen.
- Prüfung: Drei vollständige Szenenprüfungen mit 30, 60 und 120 simulierten Bildern pro Sekunde bestehen. Die Fahrzeit beträgt jeweils 60,483 Sekunden.
- Prüfung: Der Projektimport und die Darstellung im Spielfenster funktionieren. Die Bilder liegen unter `docs/preview-*.png`.
- Codeprüfung: Ein unabhängiger Prüfer fand einen Fehler bei der Pause. Ein neuer Test bestätigte ihn. Die Korrektur besteht diesen Test.
- Codeprüfung: Die Tastenbelegung zeigt nun die Frist für einen Abbruch ohne weitere Taste.
- Bewusste Grenze: Keine Sprachsteuerung in dieser Lieferung. Stefan wünscht sie erst im nächsten Schritt.
- Weitere Grenzen: Noch kein Test mit Menschen aus der Zielgruppe. Noch kein Test unter Windows. Die getrennte Abschaltung der Texthinweise folgt später.
- Rückmeldung von Stefan: Die Pause durch erneuten Tastendruck unterbricht die Fahrt. Die bisherige Fahrt wirkt zu langsam und zu sicher.

## Änderung nach dem ersten Spieltest

- Stefans neue Vorgabe ersetzt die bisherige Pause durch erneuten Tastendruck.
- A und D lenken bei jedem getrennten Tastendruck. Escape pausiert weiterhin bewusst. Der Fensterwechsel pausiert weiterhin.
- Das Auto hält 22 Meter pro Sekunde. Das entspricht rund 79 km/h. Eine Fahrt dauert jetzt 27,433 Sekunden.
- Die Lenkhilfe führt nahe an den äußeren Rand. Eine weitere passende Eingabe zieht das Auto nach innen.
- Jede Kurve braucht weiterhin eine passende Richtungseingabe. Ohne Eingabe fährt das Auto über den Rand.
- Nach einem Fall startet das Auto nach 1,1 Sekunden ohne Menü erneut. Die Startpunkte liegen früher auf den Geraden. Das lässt mehr Zeit bis zur Kurve.
- Die Kamera steht tiefer. Das Sichtfeld ist weiter. Die Markierungen am Rand zeigen das Tempo.
- Die Karosserie neigt sich leicht am Rand. Die Kamera wackelt nicht.
- Die neue Prüfung bestätigt Randnähe und die Wirkung einer Korrektur für alle drei Kurven.
- 52 Einzelprüfungen bestehen. Drei vollständige Szenenprüfungen erreichen das Ziel mit gleicher Fahrzeit.
- Die Bilder `preview-edge.png` und `preview-correction.png` zeigen die echte Spielansicht vor und nach einer Korrektur.
- Die Sprachsteuerung bleibt für den nächsten Schritt offen.

## Sprachsteuerung und Tempo

- Auftrag: Sprache für links und rechts sowie schneller und langsamer. Deutsche und englische Wörter für Gas und Bremsen.
- Umsetzung nach dem bestehenden Sprachplan. Die zusätzliche Tempowahl gehört zu Stefans neuem Auftrag.
- Entscheidung: Vosk 0.3.44 mit den kleinen deutschen und englischen Modellen 0.15. Diese Version bietet ein passendes Paket für den Mac.
- Entscheidung: Beide Sprachen laufen gleichzeitig. Nur vollständige, bekannte Befehle zählen. Widersprüchliche Ergebnisse lösen nichts aus.
- Entscheidung: Das Tempo ändert sich schrittweise zwischen 14 und 28 Metern pro Sekunde. Bremsen hält die Fahrt nicht an.
- Verbindung: Nur auf dem eigenen Rechner. Eine Kennung prüft den Helfer. Nummern verhindern doppelte Befehle. Eine Zustandsnummer verwirft alte Befehle nach Pause und Neustart.
- Stand: Sprachbefehle, Mikrofon, Oberfläche und Startdatei sind umgesetzt. Deutsch und Englisch funktionieren gleichzeitig.
- Prüfung: 76 Godot-Einzelprüfungen, die vollständige Spielszene und neun Python-Prüfungen bestehen. 24 künstliche Sprachproben liefern das erwartete Ergebnis.
- Prüfung: Das echte Mikrofon meldet Bereitschaft und regelmäßige Lebenszeichen. Ein Test mit Stefans Stimme steht aus.
- Codeprüfung: Ein unabhängiger Prüfer fand alte Tonblöcke nach einem Zustandswechsel während der Erkennung.
- Korrektur: Beide Stellen für einen Zustandswechsel verwerfen jetzt alte Tonblöcke. Der neue Test scheiterte vorher und besteht danach.
- Grenze: Die Erkennungsquote mit Menschen und bei Umgebungsgeräuschen bleibt offen.


## Schnelle Wiederholungen und sichtbare Rückmeldung

- Rückmeldung: Mehrere schnell gesprochene Richtungswörter funktionierten nicht zuverlässig.
- Ursache: Die bisherige Erkennung wartete auf 300 Millisekunden Stille. Danach akzeptierte sie nur einen Befehl für die ganze Äußerung.
- Änderung: Die Erkennung verarbeitet bestätigte Wörter während des Sprechens. Sie vergleicht die Erkennung mit begrenztem Wortschatz mit einer freien Erkennung.
- Änderung: Eine Wortfolge darf mehrere Richtungsbefehle enthalten. Jeder neue bestätigte Wortplatz erzeugt höchstens einen Befehl. Das endgültige Ergebnis wiederholt keine früheren Befehle.
- Anzeige: Mikrofonname, Mikrofonpegel, vermutete Wörter und eine Nummer für jeden ausgeführten Befehl. Erkannte Befehle ohne Wirkung erhalten einen eigenen Hinweis.
- Codeprüfung: Der unabhängige Prüfer fand einen verlorenen Folgebefehl bei Hintergrundgeräuschen. Die automatische Prüfung stellte den Fehler nach.
- Korrektur: Die Erkennung behält abgeschlossene Wortfolgen über interne Ergebniswechsel hinweg. Sie beendet eine Äußerung auch nach dem Abschluss aller vier Erkenner.
- Prüfung: Die Wiederholung nach einer Sprechpause funktioniert auch mit dem künstlichen Störton. Eine unbekannte Äußerung verhindert den folgenden Richtungsbefehl nicht.
- Prüfung: 81 Godot-Einzelprüfungen, die vollständige Fahrt und 14 Python-Prüfungen bestehen. Das echte MacBook-Pro-Mikrofon liefert weiterhin Daten.
- Grenze: Die Zeitmessung verwendet künstliche Sprache und geschätzte Wortenden. Sie ersetzt weder eine Messung der Mikrofonverzögerung noch einen Test mit Stefans Stimme.
