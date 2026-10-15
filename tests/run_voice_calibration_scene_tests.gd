extends SceneTree
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")
var checks := 0
var failures := 0
var sequence := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func packet(scene, values: Dictionary) -> void:
	sequence += 1
	var data := {"seq":sequence, "epoch":scene.voice.epoch}
	data.merge(values, true)
	scene.voice.accept_packet(data)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-calibration-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.control_mode = "keys"
	scene.session.sound_enabled = false
	scene.session.open_settings()
	scene.session.activate(5)
	scene.voice.device_name = "Test microphone"
	scene.ui.practice_panel.selected.emit(0)
	scene._physics_process(0.016)
	scene._process(0.016)
	check(scene.session.practice.phase == "calibrating", "Die Lautstärke kommt vor den Wörtern.")
	if scene.session.practice.phase == "calibrating":
		check(scene.ui.practice_panel.meter.visible and not scene.ui.practice_panel.compass.visible and not scene.ui.practice_panel.prompt.visible, "Die Kalibrierung zeigt nur den Pegel statt der Wortübung.")
		check("normal voice" in scene.ui.practice_panel.calibration_instruction.text and scene.ui.practice_panel.calibration_prompt.text == "okay", "Die erste Aufforderung verlangt normales Sprechen.")
		for index in range(5): packet(scene, {"type":"feedback", "rms":20000.0, "peak_rms":20000.0, "level":1.0, "state":"unknown" if index == 4 else "checking"})
		scene._physics_process(0.016)
		scene._process(0.016)
		check(scene.session.practice.calibration.phase == "retry" and scene.session.practice.calibration.values.is_empty(), "Ein voller erster Normalpegel fordert im Spiel eine Wiederholung.")
		check(scene.ui.practice_panel.meter.lit_bars() == 4 and "Sensitivity adjusted" in scene.ui.practice_panel.calibration_instruction.text, "Die Anpassung senkt den sichtbaren Normalpegel auf vier Balken.")
		scene.ui.practice_panel.selected.emit(0)
		scene.sync_voice_context()
		packet(scene, {"type":"feedback", "rms":5000.0, "peak_rms":6000.0, "clipped":true, "level":1.0, "state":"checking"})
		scene._physics_process(0.016)
		scene._process(0.016)
		check(scene.session.practice.calibration.phase == "retry" and "too loud" in scene.ui.practice_panel.calibration_instruction.text, "Der übersteuerte Eingang zeigt einen klaren Hinweis zum Wiederholen.")
		scene.ui.practice_panel.selected.emit(0)
		scene.sync_voice_context()
		var target: float = scene.model.target_speed_mps
		for value in [4000.0, 8000.0, 16000.0]:
			packet(scene, {"type":"command", "command":"faster", "strength":1.0, "peak_rms":16000.0})
			for index in range(5): packet(scene, {"type":"feedback", "rms":value, "peak_rms":value, "level":1.0, "state":"unknown" if index == 4 else "checking"})
			scene._physics_process(0.016)
			scene._process(0.016)
			check(scene.ui.practice_panel.meter.lit_bars() == [4000.0, 8000.0, 16000.0].find(value) * 4 + 4, "Die Bestätigung zeigt genau die gemessene persönliche Stufe.")
			check(scene.session.practice.calibration.phase == "transition", "Ein persönlicher Pegel bestätigt genau eine Stufe.")
			check(scene.session.practice.attempted == 0 and scene.model.target_speed_mps == target, "Die Kalibrierung zählt keine Wörter und steuert das Auto nicht.")
			scene._physics_process(1.0)
			scene._process(0.016)
		check(not scene.ui.practice_panel.meter.visible and scene.ui.practice_panel.prompt.visible, "Nach den Pegeln erscheint das Wort direkt am Pfeil.")
		check(scene.session.practice.phase == "listening", "Nach den drei Pegeln beginnt automatisch die Wortübung.")
		check(scene.session.practice.calibration.levels == [4000.0, 8000.0, 16000.0], "Das Spiel behält die ungekürzten persönlichen Pegel.")
		packet(scene, {"type":"command", "command":"left", "strength":1.0, "peak_rms":4000.0})
		scene._physics_process(0.016)
		check(scene.session.practice.correct == 1 and scene.ui.practice_panel.compass.lit_bars("left") == 1, "Ein normaler persönlicher Pegel zeigt in der Wortübung einen Balken.")
		scene.session.close_practice()
		scene.session.restart()
		scene.sync_voice_context()
		scene.voice.start()
		scene.voice.device_name = "Test microphone"
		for pair in [[4000.0, 2.0, 1], [8000.0, 5.0, 2], [16000.0, 8.0, 3]]:
			var before: float = scene.model.target_speed_mps
			packet(scene, {"type":"command", "command":"faster", "strength":1.0, "peak_rms":pair[0]})
			scene._physics_process(0.016)
			check(is_equal_approx(scene.model.target_speed_mps - before, pair[1]), "Das echte Auto nutzt die persönliche Steuerstufe.")
			check(scene.ui.voice_compass.lit_bars("faster") == pair[2], "Die Anzeige bestätigt dieselbe persönliche Stufe.")
		var restored = load("res://scenes/main.tscn").instantiate()
		restored.settings_path = scene.settings_path
		root.add_child(restored)
		restored.set_process(false)
		restored.set_physics_process(false)
		check(restored.session.practice.calibration.levels == [4000.0, 8000.0, 16000.0], "Der Neustart lädt das persönliche Profil.")
		restored.free()
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	await process_frame
	print("KALIBRIERUNG IM SPIEL: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
