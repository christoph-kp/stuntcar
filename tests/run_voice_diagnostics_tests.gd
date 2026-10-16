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

func packet(scene, data: Dictionary) -> void:
	sequence += 1
	data["seq"] = sequence
	if not data.has("epoch"): data["epoch"] = scene.voice.epoch
	scene.voice.accept_packet(data)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/voice-diagnostic-settings-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.voice.start()
	scene.voice.device_name = "Test microphone"
	scene.session.practice.calibration.load_profile({"version":1,"device":"Test microphone","levels":[1000.0,2000.0,4000.0]})
	var path := "/private/tmp/voice-diagnostic-%d.jsonl" % OS.get_process_id()
	check(scene.has_method("start_voice_diagnostics"), "Der Mikrofontest muss einen Bericht im echten Spiel starten.")
	if not scene.has_method("start_voice_diagnostics"):
		scene.free()
		quit(1)
		return
	check(scene.start_voice_diagnostics(path), "Der Bericht öffnet eine beschreibbare Datei.")
	scene.session.restart()
	scene.sync_voice_context()
	packet(scene, {"type":"feedback","rms":4000.0,"peak_rms":4000.0,"state":"checking","token":"PRIVATE_TEST_VALUE","heard":"PRIVATE_SPEECH"})
	packet(scene, {"type":"command","command":"faster","strength":1.0,"peak_rms":4000.0})
	var before: float = scene.model.target_speed_mps
	scene._physics_process(0.016)
	check(is_equal_approx(scene.model.target_speed_mps - before, 8.0), "Der Bericht ändert die Stärke der Steuerung nicht.")
	packet(scene, {"type":"command","epoch":scene.voice.epoch - 1,"command":"left","peak_rms":4000.0})
	scene.voice.device_name = "Other microphone"
	packet(scene, {"type":"command","command":"left","strength":0.2,"peak_rms":4000.0})
	scene._physics_process(0.016)
	scene.voice.device_name = "Test microphone"
	scene.session.open_settings()
	scene.session.activate(5)
	scene.session.activate(0)
	scene.sync_voice_context()
	for i in range(3):
		packet(scene, {"type":"feedback","rms":1600.0,"peak_rms":1600.0,"state":"unknown" if i == 2 else "checking"})
	scene._physics_process(0.016)
	scene.queue_free()
	for i in range(3): await process_frame
	scene = null
	var content := FileAccess.get_file_as_string(path)
	check(not "PRIVATE_TEST_VALUE" in content and not "PRIVATE_SPEECH" in content, "Der Bericht speichert weder den Zugangscode noch freie Sprache.")
	var rows: Array = []
	for line in content.strip_edges().split("\n"):
		var row = JSON.parse_string(line)
		check(row is Dictionary, "Jede Berichtszeile enthält gültige Daten.")
		if row is Dictionary: rows.append(row)
	var actions := rows.filter(func(row): return row.event == "command_result")
	check(actions.size() == 2, "Ein alter Befehl gelangt nicht in die Auswertung.")
	if actions.size() == 2:
		check(actions[0].bars == 3 and actions[0].profile_reason == "calibrated" and actions[0].accepted, "Der Bericht zeigt die tatsächlich verwendeten drei Balken.")
		check(actions[1].bars == 1 and actions[1].profile_reason == "device_mismatch", "Der Bericht erklärt einen Rückfall auf den Standardpegel.")
	var states := rows.filter(func(row): return row.event == "state")
	check(states.any(func(row): return row.profile.levels == [1000.0,2000.0,4000.0]), "Der Bericht enthält das gespeicherte Profil.")
	check(states.any(func(row): return row.calibration_phase == "transition" and row.calibration_values == [1600.0]), "Der Bericht enthält den gemessenen Kalibrierwert.")
	check(rows[-1].event == "end", "Das Schließen des Spiels schließt den Bericht.")
	DirAccess.remove_absolute(path)
	await process_frame
	print("MIKROFONBERICHT: %d Prüfungen, %d Fehler" % [checks,failures])
	quit(0 if failures == 0 else 1)
