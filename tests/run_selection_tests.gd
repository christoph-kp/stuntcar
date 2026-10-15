extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	check(scene.get("settings_path") != null, "Einstellungen und erste Steuerungswahl fehlen")
	if scene.get("settings_path") == null:
		scene.free()
		quit(1)
		return
	var path := "/tmp/stuntcar-selection-%d.cfg" % OS.get_process_id()
	scene.settings_path = path
	root.add_child(scene)
	scene.set_physics_process(false)
	check(scene.session.state == "TRACKS", "Der erste Start zeigt zuerst die Strecken")
	scene.session.activate(0)
	check(scene.session.state == "CONTROL", "Erst nach der Strecke folgt die erste Steuerungswahl")
	scene.session.activate(0)
	check(scene.session.state == "MENU" and scene.control_mode == "keys", "Tastenwahl führt zum Startmenü")
	scene.session.open_tracks()
	scene.session.submit_voice("next")
	scene.session.submit_voice("select")
	check(scene.track.track_name == "Höhenfahrt" and scene.model.track == scene.track, "Sprachmenü wechselt Strecke und Fahrmodell gemeinsam")
	scene.session.restart()
	check(scene.model.distance_m == 5 and not scene.model.airborne, "Streckenstart verwirft alte Flugbewegung")
	scene.session.pause()
	scene.session.open_settings()
	scene.session.open_controls()
	scene.ui.left_name = "J"
	scene.ui.right_name = "L"
	scene.ui.render(scene.session)
	check("J" in scene.ui.menu_footer.text and "L" in scene.ui.menu_footer.text, "Steuerungswahl zeigt die eigenen Tasten")
	scene.session.activate(0)
	check(scene.session.state == "SETTINGS", "Steuerungswahl kehrt zu den Einstellungen zurück")
	scene.save_settings()
	scene.queue_free()
	await process_frame
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.settings_path = path
	root.add_child(restored)
	restored.set_physics_process(false)
	check(restored.session.state == "TRACKS" and restored.control_mode == "keys", "Der zweite Start übernimmt die Steuerungswahl")
	check(restored.track.track_name == "Höhenfahrt", "Der zweite Start übernimmt die Strecke")
	var missing_route := {"path": "/tmp/stuntcar-entfernt.json", "name": "Entfernt"}
	restored.session.routes.append(missing_route)
	restored.session.activate(restored.session.routes.size() - 1)
	check(restored.session.state == "TRACKS", "Eine inzwischen entfernte Datei darf keine alte Strecke starten")
	check(not restored.session.catalog_errors.is_empty(), "Eine inzwischen entfernte Datei braucht eine Meldung")
	restored.session.control_mode = "voice"
	restored.session.voice_enabled = false
	restored.ui.voice_text = "Das Mikrofon fehlt."
	restored.ui.render(restored.session)
	var feedback = restored.ui.track_selection.get("voice_status")
	check(feedback != null and feedback.visible and "Mikrofon" in feedback.text, "Die Streckenauswahl zeigt einen Mikrofonfehler auch nach dem Abschalten der Sprache")
	restored.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("AUSWAHL: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
