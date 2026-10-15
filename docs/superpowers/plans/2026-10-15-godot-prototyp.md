# Plan für den ersten Godot Prototyp

> Aktualisierung nach Stefans Spieltest am 15. Oktober 2026: Wiederholte Richtungseingaben dürfen die Fahrt nicht pausieren. Das Auto fährt jetzt mit etwa 79 km/h. Die Lenkhilfe führt nahe an den Rand. Weitere kurze Eingaben korrigieren nach innen. Nach einem Fall geht die Fahrt ohne Menü weiter. Diese Vorgabe ersetzt die abweichenden Stellen des ursprünglichen Plans unten. Die aktuelle Bedienung steht in `README.md`.

> Für die Umsetzung: Nutze `superpowers:executing-plans`. Arbeite die Aufgaben nacheinander ab. Die Kästchen zeigen den Fortschritt.

**Ziel:** Eine kurze Rennstrecke vermittelt Spannung durch grobe Richtungseingaben, eine unterstützte Lenkung und eine Bedienung mit Sprache oder zwei Tasten.

**Aufbau:** Das Fahrzeug bewegt sich frei auf der Fahrbahn. Die Spieler geben links oder rechts vor. Erst eine passende Eingabe aktiviert die Fahrhilfe für eine einzelne Kurve. Eine gemeinsame Befehlsverarbeitung verbindet Tasten, Sprache und Menüs.

**Technik:** Godot 4.5 oder neuer, GDScript, Python 3.11 und Vosk. Nutze zunächst Godots Darstellungsart „Compatibility“.

**Entwurf:** Der Abschnitt „Festgelegter Entwurf“ in diesem Dokument enthält die Anforderungen für diesen Plan.

Stefan bestätigte den Plan am 15. Oktober 2026 mit einer Korrektur: Die Spieler müssen die Richtung selbst vorgeben. Dieser Entwurf berücksichtigt diese Korrektur. Die Zahlen dienen als erste Prüfwerte. Der erste Prototyp mit Tastensteuerung ist umgesetzt. Stefan hat die Sprachsteuerung auf den nächsten Schritt verschoben. Die Prüfergebnisse stehen in `docs/prototype-test.md`.

## Umfang dieser Lieferung

Stand vom 15. Oktober 2026: Strecke, Auto, Tastensteuerung und Menüs sind vorhanden. Die Sprachsteuerung ist inzwischen ergänzt. Deutsch und Englisch erlauben Richtung und Tempo. Die offenen Prüfungen mit Menschen stehen unten.

Die Umsetzung trennt die Streckendaten in `TrackData` von der sichtbaren Strecke in `TrackBuilder`. Die Dateien `tests/run_tests.gd`, `tests/run_input_tests.gd` und `tests/run_scene_test.gd` enthalten die automatischen Prüfungen.

## Gemeinsame Anforderungen

- Entwickle den Spielcode vollständig neu.
- Erzeuge alle sichtbaren Objekte selbst aus einfachen Körpern.
- Übernimm keinen Spielcode und keine Grafik aus anderen Rennspielen.
- Nutze keine gekauften Grafikpakete für diesen Prototyp.
- Ermögliche den vollständigen Spielablauf mit genau zwei frei belegbaren Tasten.
- Ermögliche denselben Ablauf mit Sprache nach der ersten Einrichtung des Mikrofons.
- Verlange weder gleichzeitige Tastendrücke noch dauerhaftes Drücken.
- Verarbeite Sprache auf dem Gerät. Speichere keine Tonaufnahmen.
- Nutze Deutsch für die Oberfläche und die ersten Sprachbefehle.
- Entwickle zunächst für den vorhandenen Mac. Plane einen getrennten Test unter Windows vor Tests auf fremden Windows-Geräten.
- Halte die Tastenbedienung auch ohne Mikrofon, Sprachmodell oder Hilfsprogramm funktionsfähig.
- Halte die Spielregeln unabhängig von der Bildrate. Nutze einen festen Berechnungsschritt von 60 Hz.
- Fahre ohne Richtungseingabe geradeaus weiter. Folge keiner Kurve automatisch.
- Erlaube das Verlassen der Fahrbahn bei fehlender oder falscher Richtungseingabe.
- Unterstütze die Genauigkeit einer passenden Richtungseingabe. Ersetze diese Entscheidung niemals durch eine automatische Kurvenwahl.

## Festgelegter Entwurf

### Strecke und Darstellung

Die Strecke hat einen Anfang und ein Ziel. Sie umfasst ungefähr 600 Meter. Eine Fahrt dauert etwa 45 bis 70 Sekunden.

| Abschnitt | Länge | Aufgabe |
|---|---:|---|
| Startgerade | 100 m | Die Richtungseingaben kennenlernen |
| Weite Rechtskurve | 70 m | Rechts vorgeben |
| Gerade mit kleiner Kuppe | 100 m | Das Auto fährt selbstständig geradeaus |
| Enge Linkskurve | 60 m | Links vorgeben |
| Gerade | 100 m | Die nächste Kurve erkennen |
| Weite Rechtskurve | 70 m | Erneut rechts vorgeben |
| Zielgerade | 100 m | Das Ziel erreichen |

Die Fahrbahn ist sechs Meter breit. Die Kurvenradien betragen zunächst 35 Meter und 20 Meter. Weiche Übergänge verbinden die Abschnitte.

Ein Quader bildet die Karosserie. Vier Zylinder bilden die Räder. Weitere Quader bilden Stützen und Streckenmarkierungen.

Die Kuppe bleibt durchgehend befahrbar. Freie Sprünge und Loopings folgen erst nach dem Test der Grundsteuerung.

Eine ruhige Kamera folgt dem Fahrzeug von hinten. Sie übernimmt keine seitliche Fahrzeugneigung. Kameraerschütterungen bleiben ausgeschaltet.

### Fahrhilfe und Spannung

Das Auto beschleunigt selbstständig auf 10 m/s. Die Beschleunigung beträgt höchstens 4 m/s pro Sekunde. Die Spieler steuern im ersten Schritt ausschließlich die Richtung.

Nutze einen `CharacterBody3D` mit eigener Fahrzeugbewegung und Bodenprüfung. Die Streckenkurve dient zur Berechnung der Fahrhilfe. Sie führt das Auto ohne Eingabe nicht.

Ohne Eingabe bleibt die waagerechte Fahrtrichtung erhalten. Das Auto fährt in einer Kurve über den Rand, wenn die Spieler nicht lenken.

Eine Eingabe „links“ oder „rechts“ gibt eine grobe Lenkabsicht vor. Außerhalb einer passenden Kurve dreht sie das Auto zunächst 0,75 Sekunden mit 25 Grad pro Sekunde.

Vor einer Kurve beginnt ein großzügiger Eingabebereich. Er umfasst zunächst fünf Sekunden Anfahrt bei der aktuellen Geschwindigkeit. Drei oder acht Sekunden sind ebenfalls einstellbar.

Eine passende Eingabe in diesem Bereich gilt für genau diese Kurve. Die Fahrhilfe wartet bis zur Kurve und übernimmt dann die genaue Dosierung.

Die Spieler müssen keine Taste halten. Sie müssen die Lenkung am Kurvenende nicht selbst zurücknehmen. Nach der Kurve endet die Hilfe vollständig.

Eine spätere passende Eingabe darf das Fahrzeug noch korrigieren, solange die Fahrbahn ausreichend Platz bietet. Die Hilfe verändert den Lenkwinkel weich. Sie versetzt das Auto niemals unmittelbar auf eine Fahrlinie.

Begrenze die Drehgeschwindigkeit der Hilfe zunächst auf 50 Grad pro Sekunde. Bei einer falschen Eingabe endet eine zuvor aktive Hilfe. Das Auto lenkt in die tatsächlich gewählte Richtung.

Wiederholte Tastenereignisse durch dauerhaftes Drücken aktivieren keine weiteren Kurven. Jede Kurve braucht eine neue Eingabe. Bereits vor dem Eingabebereich empfangene Befehle gelten nicht für eine spätere Kurve.

Eine frühe passende Eingabe führt durch die Kurve mit mehr Abstand zum Rand. Eine spätere Eingabe lässt weniger Platz für die Korrektur.

Der knappe Moment entsteht aus der tatsächlichen Fahrzeugposition und der begrenzten Korrektur. Er entsteht nicht durch eine rein optische Verschiebung eines automatisch geführten Autos.

Das Auto ist 1,6 Meter breit. Die Hilfe plant bei ausreichendem Platz mindestens 0,5 Meter Abstand zum Rand. Sie garantiert keine Rettung aus jeder Lage.

Fehlende Bodenkontakte lösen einen sichtbaren Fall aus. Unterhalb der Fahrbahn hält das Spiel an und bietet einen erneuten Versuch am letzten Streckenpunkt an.

Setze solche Streckenpunkte vor jede Kurve. Ein erneuter Versuch löscht alle alten Lenkbefehle. Er beginnt auf einer ausreichend langen Geraden.

Vor jeder Kurve erscheint ein Richtungshinweis. Ein einfacher Ton begleitet ihn. Text und Ton bleiben einzeln abschaltbar.

Keine Eingabe auf einer Geraden ist richtig. Keine Eingabe vor einer Kurve führt zum Verlassen der Fahrbahn. Das ist der zentrale Unterschied dieses Entwurfs.

### Bedienung mit zwei Tasten

Die Vorgabe nutzt die Tasten A und D. Zwei Spezialtaster können dieselben Befehle auslösen. Die Beschriftung zeigt immer die aktuelle Bedeutung.

| Zustand | Taste A | Taste D |
|---|---|---|
| Menü | Nächsten Eintrag markieren | Markierten Eintrag auswählen |
| Fahrt | Links vorgeben | Rechts vorgeben |
| Pause | Nächsten Eintrag markieren | Markierten Eintrag auswählen |
| Ergebnis | Nächsten Eintrag markieren | Markierten Eintrag auswählen |

Ein einzelner Tastendruck löst genau eine Aktion aus. Wiederholungen durch eine gehaltene Taste zählen nicht. Gleichzeitige Tastendrücke lösen keine Richtungseingabe aus.

Für die Pause mit zwei Tasten gilt: Eine erneute Betätigung derselben Taste nach dem Loslassen pausiert. Dafür gibt es keine kurze Frist.

Das Spiel merkt sich dafür die letzte Richtungseingabe bis zur nächsten anderen Richtung oder bis zum Kurvenende. Die Oberfläche zeigt diese zweite Tastenfunktion an.

Auf einer Geraden lässt sich die Pause durch zwei getrennte Betätigungen derselben Taste erreichen. Die erste Betätigung kann das Auto kurz lenken. Prüfe diese Bedienung im ersten Nutzertest ausdrücklich.

Die zusätzliche Taste Escape darf sofort pausieren. Sie gehört nicht zu den notwendigen Spieleingaben. Der Sprachbefehl „Pause“ pausiert ebenfalls sofort.

Im Pausenmenü steht „Weiter“ zuerst. Weitere Einträge heißen „Neu starten“, „Einstellungen“ und „Beenden“. Das Startmenü bietet „Start“, „Einstellungen“ und „Beenden“.

Die Einstellungen bieten Tastenbelegung, Hinweisvorlauf und Sprachsteuerung. Eine neue Tastenbelegung gilt erst nach beiden Zuordnungen. Eine doppelte Zuordnung zählt nicht.

Die alte Belegung bleibt bis zum Abschluss wirksam. „Zurück“ beendet eine unvollständige Änderung. Ein Zustandswechsel verbraucht die auslösende Eingabe vollständig.

Pause friert Fahrzeug, Streckenfortschritt und Rennzeit sofort ein. „Weiter“ setzt die Fahrt mit dem vorherigen Tempo fort.

### Sprache

Vosk nutzt zunächst das Modell `vosk-model-small-de-0.15`. Prüfe die aktuelle Bezugsquelle und die Modelllizenz vor dem Download.

| Sprachbefehl | Wirkung |
|---|---|
| „links“ | Die Richtung links vorgeben |
| „rechts“ | Die Richtung rechts vorgeben |
| „Pause“ | Sofort pausieren |
| „weiter“ | Eine pausierte Fahrt fortsetzen |
| „nächstes“ | Den nächsten Menüeintrag markieren |
| „wählen“ | Den markierten Menüeintrag auswählen |

Die Menübefehle ermöglichen auch Start, Einstellungen, Neustart und Beenden. Fahrbefehle wirken nur im passenden Zustand.

Ein erneut gesprochenes Richtungswort erneuert die Lenkabsicht. Es pausiert nicht. Die Pause durch erneuten Tastendruck gehört ausschließlich zur Tastenbedienung.

Das Hilfsprogramm verwendet Vosk und `sounddevice`. Es sendet ausschließlich abgeschlossene Erkennungsergebnisse. Teilweise erkannte Wörter verändern das Spiel nicht.

Unbekannte Wörter lösen keine Aktion aus. Die Oberfläche zeigt den letzten akzeptierten Befehl und den Zustand des Mikrofons.

Godot startet das Hilfsprogramm nach Aktivierung der Sprachsteuerung. Das Hilfsprogramm verbindet sich ausschließlich mit `127.0.0.1`.

Godot verwendet `TCPServer.listen(0, "127.0.0.1")`. Es übergibt den vergebenen Anschluss an das Hilfsprogramm. Die Verbindung blockiert niemals die Fahrzeugberechnung.

Eine Nachricht enthält eine fortlaufende Nummer und einen Befehl als JSON-Zeile. Eine Zeile darf höchstens 1024 Byte enthalten.

Das Hilfsprogramm sendet jede Sekunde ein Lebenszeichen. Nach drei Sekunden ohne Lebenszeichen pausiert eine aktive Fahrt mit Sprachsteuerung.

Die Verbindung meldet Mikrofonfehler ausdrücklich. Eine erneute Verbindung setzt die Fahrt nicht automatisch fort. Beim Neustart verwirft das Spiel alte Sprachbefehle.

Die erste Einrichtung darf Hilfe für Betriebssystemrechte und Mikrofonwahl benötigen. Danach braucht die Spracheingabe keine Tastendrücke während des Spiels.

### Ergebnis und Grenzen

Die Ergebnisanzeige zeigt Fahrzeit, geschaffte Kurven und Anzahl der erneuten Versuche. Pausen zählen nicht zur Fahrzeit. Die Spieler können sofort erneut starten.

Tempowahl, Jev, Gesten, Blicksteuerung, Gegner und Mehrspielerfunktionen gehören zu einem späteren Schritt. Zuerst prüfen wir das Gefühl der eigenen Lenkung.

## Besondere Prüfpunkte

1. Gehaltene oder gleichzeitige Tasten erzeugen keine weiteren Lenkbefehle. Aufgabe 3 prüft dieses Verhalten.
2. Pause und Neustart übernehmen keine alten Befehle. Aufgaben 3 und 4 prüfen die Zustandswechsel.
3. Ein Mikrofonfehler beendet keine Fahrt unbemerkt. Aufgabe 4 prüft die Pause und die Fehlermeldung.
4. Sprachverzögerungen lassen ausreichend Zeit für eine Entscheidung. Aufgabe 6 misst die Verzögerung auf dem Testgerät.
5. Ohne Richtungseingabe verlässt das Auto die Fahrbahn. Aufgaben 2 und 6 vergleichen Fahrten ohne, mit falschen und mit passenden Eingaben.

## Dateien und Zuständigkeiten

Alle folgenden Pfade liegen unter `/Users/stefan/Documents/railsapps/stuntcar`.

| Datei | Zuständigkeit |
|---|---|
| `project.godot`, `scenes/main.tscn` | Projekt und Hauptszene |
| `scripts/track/track_builder.gd` | Strecke, einfache Geometrie und Abschnittsgrenzen |
| `scripts/vehicle/drive_model.gd` | Fahrzeugbewegung, Lenkabsicht, Fahrhilfe und Fahrzeit |
| `scripts/vehicle/car_view.gd` | Fahrzeugform, Fahrlinie und Darstellung |
| `scripts/input/command_router.gd` | Gemeinsame Befehle und Spielzustände |
| `scripts/input/voice_bridge.gd` | Verbindung zum Sprachprogramm |
| `scripts/ui/game_ui.gd` | Menüs, Hinweise, Ergebnis und Einstellungen |
| `scripts/camera/follow_camera.gd` | Ruhige Kameraführung |
| `voice/recognizer.py`, `voice/protocol.py` | Mikrofon, Erkennung und Nachrichten |
| `voice/requirements.txt` | Geprüfte Versionen der Sprachbibliotheken |
| `tests/run_tests.gd`, `tests/test_*.gd` | Automatische Prüfungen der Spielregeln |
| `voice/tests/test_protocol.py` | Automatische Prüfung der Sprachbefehle |
| `docs/prototype-test.md`, `README.md` | Testergebnisse und Startanleitung |

## Aufgabe 1 Eine vollständige Strecke darstellen

**Dateien:** `project.godot`, `scenes/main.tscn`, `scripts/track/track_builder.gd`, `scripts/vehicle/car_view.gd`, `scripts/camera/follow_camera.gd`, `tests/run_tests.gd`, `tests/test_track.gd`.

**Schnittstelle:** `TrackBuilder.build() -> Path3D`; `TrackBuilder.section_at(distance_m: float) -> Dictionary`. Abschnittsdaten enthalten `id`, `start_m`, `end_m`, `turn_sign` und `checkpoint_m`. Rechts verwendet `1`, links `-1`, geradeaus `0`.

- [x] Prüfe die lokale Godot-Version und lege die genaue Version für das Projekt fest.
- [x] Erstelle das Projekt samt Hauptszene und Strecke.
- [x] Erzeuge das Auto, die Stützen und die Markierungen aus Grundkörpern.
- [x] Ergänze die Kamera hinter dem Auto.
- [x] Prüfe Abschnittsgrenzen und Streckenlänge automatisch.
- [x] Prüfe die Fahrbahn und ihre Bodenkollisionen über die gesamte Strecke.

**Ergebnis:** Die Strecke zeigt alle sieben Abschnitte ohne Lücken. Die Kamera bleibt an Übergängen ruhig. Die Gesamtstrecke liegt zwischen 570 und 630 Metern.

## Aufgabe 2 Die grobe Lenkung und die Fahrhilfe berechnen

**Dateien:** `scripts/vehicle/drive_model.gd`, `scripts/vehicle/car_view.gd`, `tests/test_drive.gd`.

**Eingang:** Abschnittsdaten aus Aufgabe 1.

**Schnittstelle:** `DriveModel.step(delta: float, section: Dictionary) -> void`; `request_turn(direction: int) -> void`; `reset(checkpoint_m: float = 0.0) -> void`. Eigenschaften: `speed_mps`, `distance_m`, `elapsed_s`, `active_curve_id`, `retry_count`. Die gemeinsame Befehlsverarbeitung übernimmt später die Pause.

Ermittle `distance_m` aus der Fahrzeugposition. Erhöhe den Streckenfortschritt nicht unabhängig von der tatsächlichen Bewegung. Prüfe das Ziel über einen räumlichen Zielbereich.

- [x] Schreibe Prüfungen für Geradeausfahrt ohne Eingabe und eine grobe Lenkbewegung nach Eingabe.
- [x] Bestätige die fehlenden Funktionen durch einen fehlgeschlagenen Test.
- [x] Ergänze die freie Fahrzeugbewegung samt Bodenprüfung und Fall.
- [x] Ergänze die Fahrhilfe ausschließlich nach einer passenden Richtungseingabe.
- [ ] Prüfe frühe, spätere, falsche und fehlende Eingaben an jeder Kurve.
- [ ] Prüfe zwei aufeinanderfolgende Kurven gleicher Richtung mit nur einer Eingabe.
- [x] Vergleiche vollständige Fahrten ohne Eingaben, mit falschen Eingaben und mit passenden Eingaben.
- [ ] Prüfe dasselbe Fahrmuster bei 30, 60 und 120 dargestellten Bildern pro Sekunde.

**Ergebnis:** Ohne Eingabe fährt das Auto aus der ersten Kurve. Passende Eingaben innerhalb des Anfahrbereichs ermöglichen die vollständige Fahrt. Eine Eingabe gilt niemals für zwei Kurven.

Die Rennzeiten weichen höchstens 0,1 Sekunden voneinander ab, wenn nur die Bildrate wechselt. Prüfe spätere Eingaben zusätzlich bei 0,25 und 0,5 Sekunden nach Kurvenbeginn.

Mindestens die Eingabe nach 0,25 Sekunden muss aus der mittigen Ausgangslage noch helfen. Grenze spätere Rettungen anhand der tatsächlichen Fahrbahnposition ab.

## Aufgabe 3 Den gesamten Ablauf mit zwei Tasten bedienen

**Dateien:** `scripts/input/command_router.gd`, `scripts/ui/game_ui.gd`, `scenes/main.tscn`, `tests/test_commands.gd`.

**Eingang:** `DriveModel` aus Aufgabe 2.

**Schnittstelle:** `CommandRouter.submit(command: StringName, source: StringName) -> void`. Erlaubte Befehle: `left`, `right`, `pause`, `resume`, `next`, `select`. Zustände: `MENU`, `RUNNING`, `PAUSED`, `FALLING`, `RETRY`, `FINISHED`.

- [x] Schreibe Prüfungen für die Zustandstabelle und die Pause durch erneuten Tastendruck.
- [x] Ergänze die gemeinsame Befehlsverarbeitung.
- [x] Ergänze Startmenü, Pausenmenü, erneuten Versuch, Einstellungen und Ergebnisanzeige.
- [x] Ergänze die Tastenbelegung und speichere sie mit Godots `ConfigFile` unter `user://settings.cfg`.
- [x] Prüfe gehaltene Tasten, gleichzeitige Tasten und doppelte Zuordnungen.
- [ ] Spiele Start, Fahrt, Pause, Fortsetzung und Neustart ausschließlich mit A und D durch.

**Ergebnis:** Kein Schritt benötigt eine Maus oder eine dritte Taste. Die Pause verändert weder Fahrzeugposition noch Rennzeit. Ein Neustart setzt auch Lenkabsicht und Eingabestatus zurück.

## Aufgabe 4 Sprache mit derselben Befehlsverarbeitung verbinden

**Dateien:** `scripts/input/voice_bridge.gd`, `voice/recognizer.py`, `voice/protocol.py`, `voice/requirements.txt`, `voice/tests/test_protocol.py`, `tests/test_voice.gd`.

**Eingang:** `CommandRouter.submit()` aus Aufgabe 3.

**Schnittstelle:** `VoiceBridge.start(python_path: String, model_path: String) -> Error`; `stop() -> void`. Signale: `command_received(command: StringName)`, `unavailable(reason: String)`. Python: `normalize_command(text: str) -> str | None`.

- [x] Prüfe die Bibliotheksversionen und die Lizenz des deutschen Sprachmodells.
- [x] Schreibe Prüfungen für alle sechs Wörter und unbekannte Wörter.
- [x] Ergänze das Hilfsprogramm und die örtliche TCP-Verbindung.
- [x] Ergänze den Start des Hilfsprogramms aus der Spieloberfläche.
- [x] Prüfe aufgeteilte Nachrichten, mehrere Nachrichten, doppelte Nummern und überlange Zeilen.
- [ ] Prüfe fehlendes Modell, verweigerten Mikrofonzugriff und einen Verbindungsabbruch.
- [x] Prüfe die Pause nach drei Sekunden ohne Lebenszeichen.
- [x] Prüfe, dass alte Nachrichten nach Pause oder Neustart keine Fahrt auslösen.

**Ergebnis:** Sprachbefehle erreichen dieselbe Befehlsverarbeitung wie die Tasten. Fehler erscheinen als verständlicher Text. Die Tasten bleiben verfügbar.

## Aufgabe 5 Hinweise und Rückmeldung ergänzen

**Dateien:** `scripts/ui/game_ui.gd`, `scripts/camera/follow_camera.gd`, `tests/test_cues.gd`.

**Eingang:** Abstand und Tempo aus `DriveModel`; Abschnittsdaten aus `TrackBuilder`.

**Schnittstelle:** `GameUI.show_command(command: StringName) -> void`; `show_curve_hint(direction: int) -> void`; `show_voice_status(message: String) -> void`.

- [ ] Zeige die letzte Richtungseingabe und die Bedeutung beider Tasten dauerhaft an.
- [x] Ergänze den Kurvenhinweis mit einstellbarem Vorlauf.
- [x] Erzeuge einen einfachen Hinweiston selbst.
- [x] Zeige einen akzeptierten Sprachbefehl für zwei Sekunden an.
- [x] Zeige „Lenkhilfe aktiv“, sobald die passende Eingabe die Hilfe aktiviert.
- [ ] Prüfe Hinweise bei Pause, Fortsetzung und erneutem Versuch.

**Ergebnis:** Die Spieler erkennen ihre Eingabe und deren Wirkung. Ein Kurvenhinweis erscheint höchstens einmal je Kurve und Fahrt.

## Aufgabe 6 Den Prototyp als vollständiges Spiel prüfen

**Dateien:** `tests/test_run.gd`, `docs/prototype-test.md`, `README.md`.

- [x] Führe die automatischen Prüfungen aus.
- [ ] Prüfe drei vollständige Fahrten mit Tasten.
- [ ] Prüfe drei vollständige Fahrten ausschließlich mit Sprache.
- [ ] Prüfe einen Durchlauf ohne Internet nach der Einrichtung.
- [ ] Messe mindestens 20 Äußerungen je Sprachbefehl auf dem Testgerät.
- [ ] Prüfe fünf Minuten Umgebungsgeräusche ohne absichtliche Befehle.
- [ ] Dokumentiere Rechner, Mikrofon, Erkennungsquote und Verzögerung.
- [ ] Dokumentiere fehlende, falsche, frühe und spätere Richtungseingaben anhand der Vergleichsfahrten.
- [x] Erstelle eine kurze Anleitung für Einrichtung, Start und Fehlerbehebung.

**Erste Zielwerte:** Mindestens 95 Prozent richtige Erkennung je Befehl in ruhiger Umgebung. Mindestens 95 Prozent der Befehle wirken spätestens eine Sekunde nach dem Wortende. Umgebungsgeräusche lösen im beschriebenen Test keine Befehle aus.

Diese Werte beschreiben die erste technische Prüfung. Sie belegen noch keine Eignung für unterschiedliche Sprechweisen oder körperliche Einschränkungen.

Danach folgt ein freiwilliger Test mit drei bis fünf Menschen mit unterschiedlichen Eingabemöglichkeiten. Dieser Test gehört zur Bewertung des Spielkonzepts.

Fragen: „Hast du das Auto selbst gelenkt?“ „War die Fahrt spannend?“ „War die Bedienung anstrengend?“ „Hattest du genug Zeit?“

Prüfe besonders, ob eine spätere Korrektur spürbar knapp gelingt. Prüfe auch, ob die Pause mit denselben zwei Tasten verständlich bleibt.

## Prüfaufrufe für die Umsetzung

`godot` bezeichnet die zuvor geprüfte Godot-Datei. Die Umsetzung trägt deren konkreten Pfad in die Startanleitung ein.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/run_tests.gd
python3 -m unittest discover -s voice/tests
```

Der erste Aufruf prüft den Projektimport. Der zweite Aufruf muss alle Spielprüfungen erfolgreich beenden. Der dritte Aufruf muss alle Prüfungen der Sprachbefehle erfolgreich beenden.

Die automatische Prüfung ersetzt keinen sichtbaren Fahrtest und keinen Mikrofontest. Halte diese Ergebnisse getrennt fest.

## Abschluss des ersten Prototyps

Der Prototyp ist technisch fertig, wenn die Aufgaben 1 bis 6 ihre Prüfungen bestehen. Er startet, fährt und endet mit beiden Eingabearten.

Die Bewertung des Spielkonzepts bleibt offen, bis Menschen aus der Zielgruppe die Bedienung und die Spannung geprüft haben.

## Technische Quellen

- [Godot CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html): Eigene Fahrzeugbewegung mit Kollisionen.
- [Godot TCPServer](https://docs.godotengine.org/en/stable/classes/class_tcpserver.html): Verbindung zum örtlichen Sprachprogramm.
- [Godot StreamPeerTCP](https://docs.godotengine.org/en/stable/classes/class_streampeertcp.html): Empfang der Befehlsnachrichten.
- [Vosk](https://alphacephei.com/vosk/): Spracherkennung ohne Internet.
- [Vosk Sprachmodelle](https://alphacephei.com/vosk/models): Bezug und Lizenz des deutschen Sprachmodells.

Stand: 15. Oktober 2026.
