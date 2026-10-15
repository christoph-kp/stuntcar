extends SceneTree
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")
var checks := 0
var failures := 0
var sequence := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func packet(scene, values: Dictionary) -> void:
	sequence += 1
	var data := {"seq":sequence, "epoch":scene.voice.epoch}
	data.merge(values, true)
	scene.voice.consume_bytes((JSON.stringify(data) + "\n").to_utf8_buffer())

func command(scene, word: String) -> void:
	packet(scene, {"type":"command", "command":word, "strength":0.9})
	scene._physics_process(0.016)
	scene._process(0.016)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-practice-scene-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.voice.stop()
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.voice.unavailable.connect(scene.on_voice_unavailable)
	scene.control_mode = "keys"
	scene.session.control_mode = "keys"
	scene.session.open_settings()
	scene.session.activate(5)
	scene.sync_voice_context()
	scene._process(0.016)
	check(scene.ui.practice_panel.visible and not scene.ui.hud.visible and not scene.ui.menu_panel.visible, "Die Sprachübung ersetzt die Fahranzeige.")
	check(scene.voice.starts == 1 and scene.voice.recognition_mode == "direct", "Die Übung startet den gewählten einzelnen Erkenner.")
	var position: Vector3 = scene.model.position
	var target: float = scene.model.target_speed_mps
	scene.ui.practice_panel.selected.emit(0)
	scene._physics_process(0.016)
	command(scene, "left")
	check(scene.session.practice.correct == 1 and scene.session.practice.attempted == 1, "Ein einziges gesprochenes Wort zählt in der echten Spielszene.")
	check(scene.ui.practice_panel.compass.tip_lit("left"), "Die Spitze des linken Pfeils bestätigt das Wort.")
	check("LEFT" in scene.ui.practice_panel.prompt.text and "1 / 1" in scene.ui.practice_panel.score.text, "Die Übung zeigt das Sollwort und den richtigen Zähler.")
	command(scene, "right")
	check(scene.session.practice.wrong == 1 and scene.session.practice.correct == 1, "Ein falsches Wort erhöht die Trefferzahl nicht.")
	packet(scene, {"type":"feedback", "state":"unknown", "heard":"hello there", "level":0.4})
	packet(scene, {"type":"feedback", "state":"listening", "heard":"", "level":0.0})
	scene._physics_process(0.016)
	scene._process(0.016)
	check("Not recognized as a command" in scene.ui.practice_panel.feedback.text, "Eine fremde Äußerung zeigt keine falsche Zeitüberschreitung.")
	check(scene.session.practice.missed == 1 and scene.session.practice.attempted == 3, "Eine fremde Äußerung zählt einmal als nicht erkannt.")
	scene._physics_process(0.016)
	check(scene.session.practice.attempted == 3, "Dieselbe Rückmeldung zählt nicht in mehreren Bildern erneut.")
	check(scene.model.position == position and scene.model.target_speed_mps == target, "Die Übung lenkt und beschleunigt das Streckenauto nicht.")
	scene.ui.practice_panel.selected.emit(1)
	scene.sync_voice_context()
	check(scene.session.voice_mode == "checked" and scene.voice.recognition_mode == "checked" and scene.voice.starts == 2, "Der Moduswechsel startet die Gegenprüfung neu.")
	check(scene.session.practice.phase == "ready" and scene.session.practice.attempted == 0, "Ein Moduswechsel übernimmt keine alten Versuche.")
	check(scene.session.practice.results.direct.attempted == 3, "Der Vergleich behält das Ergebnis des ersten Modus.")
	var old_epoch: int = scene.voice.epoch
	scene.ui.practice_panel.selected.emit(0)
	scene._physics_process(0.016)
	packet(scene, {"type":"command", "epoch":old_epoch, "command":"left"})
	scene._physics_process(0.016)
	check(scene.session.practice.attempted == 0, "Ein alter Befehl zählt nach einem neuen Start nicht.")
	command(scene, "left")
	command(scene, "left")
	command(scene, "left")
	check(scene.ui.practice_panel.compass.tip_lit("left"), "Auch der dritte Treffer bestätigt die Pfeilspitze.")
	check(scene.session.practice.correct == 3 and scene.session.practice.phase == "transition", "Auch die Gegenprüfung braucht pro Treffer nur eine Äußerung.")
	scene._physics_process(1.0)
	check(scene.session.practice.expected_word() == "right", "Die Spielszene setzt die Wortfolge fort.")
	command(scene, "right")
	command(scene, "right")
	command(scene, "right")
	scene._physics_process(1.0)
	command(scene, "faster")
	command(scene, "faster")
	command(scene, "faster")
	scene._physics_process(1.0)
	command(scene, "slower")
	command(scene, "slower")
	command(scene, "slower")
	check(scene.session.practice.phase == "done" and scene.session.practice.correct == 12, "Die echte Spielszene beendet eine fehlerfreie Runde mit zwölf Treffern.")
	check("100" in scene.ui.practice_panel.score.text, "Die fertige Runde zeigt hundert Prozent.")
	scene.voice.fail(scene.tr("I18N_VOICE_NO_AUDIO"))
	scene._process(0.016)
	check(scene.session.state == "PRACTICE" and scene.session.practice.phase == "ready", "Ein Mikrofonfehler lässt die Übungsseite bedienbar.")
	scene.ui.practice_panel.selected.emit(0)
	scene._physics_process(0.016)
	check(scene.voice.enabled and scene.session.voice_enabled and scene.session.practice.phase == "listening", "Start kann das Mikrofon nach einem Fehler erneut einschalten.")
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.session.practice.phase == "ready", "Ein Fensterwechsel beendet den laufenden Versuch ohne falsche Treffer.")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	scene._input(event)
	scene._physics_process(0.016)
	check(scene.session.state == "SETTINGS" and not scene.voice.enabled, "Escape verlässt die Übung und beendet das nur dafür gestartete Mikrofon.")
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.settings_path = scene.settings_path
	root.add_child(restored)
	restored.set_process(false)
	restored.set_physics_process(false)
	check(restored.session.voice_mode == "checked", "Die Auswahl des Erkennungsverfahrens bleibt nach dem Neustart erhalten.")
	restored.free()
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	print("SPRACHÜBUNG IM SPIEL: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
