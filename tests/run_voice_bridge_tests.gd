extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func packet(bridge, data: Dictionary) -> void:
	bridge.consume_bytes((JSON.stringify(data) + "\n").to_utf8_buffer())

func make_bridge():
	var bridge = load("res://scripts/input/voice_bridge.gd").new()
	bridge.enabled = true
	bridge.token = "test-token"
	bridge.status_text = "Startet"
	packet(bridge, {"type":"hello", "seq":1, "token":"test-token"})
	packet(bridge, {"type":"ready", "seq":2, "device":"Testmikrofon"})
	return bridge

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/input/voice_bridge.gd"):
		check(false, "Die Sprachverbindung fehlt")
		quit(1)
		return
	var bridge = make_bridge()
	check(bridge.is_ready, "Die bestätigte Verbindung wird bereit")
	var line: String = JSON.stringify({"type":"command", "seq":3, "epoch":bridge.epoch, "command":"left", "text":"links"}) + "\n"
	bridge.consume_bytes(line.substr(0, 15).to_utf8_buffer())
	check(bridge.take_commands().is_empty(), "Eine halbe Nachricht lenkt nicht")
	bridge.consume_bytes(line.substr(15).to_utf8_buffer())
	check(bridge.take_commands().size() == 1, "Die vollständige Nachricht lenkt genau einmal")
	bridge.consume_bytes(line.to_utf8_buffer())
	check(bridge.take_commands().is_empty(), "Doppelte Nummern lenken nicht erneut")
	var old_epoch: int = bridge.epoch
	bridge.invalidate()
	packet(bridge, {"type":"command", "seq":4, "epoch":old_epoch, "command":"right", "text":"rechts"})
	check(bridge.take_commands().is_empty(), "Alte Befehle wirken nach einem Zustandswechsel nicht")
	packet(bridge, {"type":"command", "seq":5, "epoch":bridge.epoch, "command":"unknown"})
	check(bridge.take_commands().is_empty(), "Unbekannte Befehle wirken nicht")
	packet(bridge, {"type":"feedback", "seq":6, "epoch":bridge.epoch, "heard":"links links", "level":0.6, "state":"checking"})
	check(bridge.get("heard_text") == "links links" and bridge.get("input_level") == 0.6, "Die Anzeige erhält Wörter und Mikrofonpegel")
	check(bridge.take_commands().is_empty(), "Eine Wortvorschau lenkt das Auto nicht")
	bridge.invalidate()
	packet(bridge, {"type":"feedback", "seq":7, "epoch":bridge.epoch - 1, "heard":"rechts", "level":1.0})
	check(bridge.get("heard_text") == "", "Alte Wörter erscheinen nach einem Zustandswechsel nicht erneut")
	bridge.last_message_ms = Time.get_ticks_msec() - 3100
	bridge.poll()
	check(not bridge.is_ready and not bridge.enabled, "Eine ausgefallene Verbindung meldet einen Fehler")
	bridge.free()
	var meter = make_bridge()
	packet(meter, {"type":"feedback", "seq":3, "epoch":meter.epoch, "level":0.9, "direction":"left"})
	check(meter.input_direction == "left" and meter.input_level == 0.9, "Der Pegel gehört zur erkannten Richtung.")
	packet(meter, {"type":"feedback", "seq":4, "epoch":meter.epoch, "level":"invalid", "direction":"right"})
	check(meter.input_level == 0.0 and meter.input_direction == "", "Ein ungültiger Pegel übernimmt keinen alten hohen Wert.")
	packet(meter, {"type":"command", "seq":5, "epoch":meter.epoch, "command":"left", "strength":"invalid"})
	check(is_equal_approx(meter.take_commands()[0].strength, 0.5), "Eine ungültige Stärke nutzt die bisherige normale Wirkung.")
	packet(meter, {"type":"command", "seq":6, "epoch":meter.epoch, "command":"right", "strength":10.0})
	check(meter.take_commands()[0].strength == 1.0, "Die Stärke überschreitet den höchsten Anzeigewert nicht.")
	packet(meter, {"type":"feedback", "seq":7, "epoch":meter.epoch, "level":1.0, "direction":"faster"})
	meter.invalidate()
	check(meter.input_direction == "" and meter.input_level == 0.0, "Ein neuer Spielzustand verwirft den alten Pegel.")
	packet(meter, {"type":"feedback", "seq":8, "epoch":meter.epoch, "level":1.0, "direction":"faster"})
	meter.level_ms = Time.get_ticks_msec() - 400
	meter.poll()
	check(meter.input_direction == "" and meter.input_level == 0.0, "Eine unterbrochene Pegelübertragung lässt keinen Pfeil hängen.")
	meter.free()
	var oversized = make_bridge()
	oversized.consume_bytes("x".repeat(1025).to_utf8_buffer())
	check(not oversized.enabled, "Eine zu lange Zeile beendet die fehlerhafte Verbindung")
	oversized.free()
	var unauth = load("res://scripts/input/voice_bridge.gd").new()
	unauth.enabled = true
	unauth.token = "correct"
	packet(unauth, {"type":"hello", "seq":1, "token":"wrong"})
	check(not unauth.is_ready, "Ein fremdes Programm kann keine Sprachbefehle einspeisen")
	unauth.free()
	print("SPRACHVERBINDUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
