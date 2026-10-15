extends SceneTree

var failures := 0
var checks := 0
var landings := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-audio-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	var audio = scene.get("race_audio")
	check(audio != null, "Der Spielton fehlt.")
	if audio == null:
		scene.free()
		quit(1)
		return
	var model = scene.model
	var session = scene.session
	audio.effect_played.connect(func(kind):
		if kind == "landing": landings += 1)
	audio.update(model, session, 1.0)
	check(not audio.engine.playing, "Im Menü bleibt der Motor aus.")
	session.restart()
	scene._physics_process(1.0/60.0)
	check(audio.engine.playing and audio.wind.playing and audio.forest.playing, "Die Fahrt startet Motor, Wind und Wald.")
	for player in [audio.engine, audio.wind, audio.forest, audio.road, audio.landing, audio.hint]:
		check(player.stream != null and player.stream.get_length() > 0.1, "Jeder Ton braucht eine lesbare Aufnahme.")
	model.speed_mps = 14
	audio.update(model, session, 1.0)
	var low_pitch: float = audio.engine.pitch_scale
	model.speed_mps = 46
	audio.update(model, session, 1.0)
	check(audio.engine.pitch_scale > low_pitch + 0.3, "Mehr Geschwindigkeit erhöht den Motorton.")
	var full_gain: float = audio.engine.volume_db
	audio.play_hint()
	audio.update(model, session, 0.05)
	check(audio.hint.playing and audio.engine.volume_db < full_gain - 3, "Der Hinweis senkt den Motor ab.")
	audio.update(model, session, 1.0)
	session.voice_enabled = true
	audio.update(model, session, 1.0)
	check(audio.engine.volume_db < full_gain - 3, "Die Sprachsteuerung senkt die Fahrgeräusche ab.")
	session.voice_enabled = false
	model.airborne = true
	audio.update(model, session, 1.0)
	check(audio.road.volume_db <= -70, "Im Flug endet das Rollgeräusch.")
	model.airborne = false
	audio.update(model, session, 1.0/60.0)
	audio.update(model, session, 1.0/60.0)
	check(landings == 1 and audio.landing.playing, "Eine Landung spielt genau einen Stoß.")
	model.airborne = true
	audio.update(model, session, 0.1)
	session.pause()
	audio.update(model, session, 0.1)
	check(not audio.engine.playing and not audio.hint.playing and not audio.landing.playing, "Die Pause stoppt alle Töne.")
	session.activate(0)
	audio.update(model, session, 0.1)
	check(landings == 1, "Die Fortsetzung im Flug erzeugt keine Landung.")
	session.pause()
	audio.update(model, session, 0.1)
	session.activate(0)
	model.airborne = false
	audio.update(model, session, 1.0/60.0)
	check(landings == 2, "Eine Landung direkt nach der Pause braucht einen Landeton.")
	model.airborne = true
	audio.update(model, session, 0.1)
	session.restart()
	audio.update(model, session, 0.1)
	check(landings == 2, "Ein Neustart im Flug erzeugt keine Landung.")
	session.sound_enabled = false
	audio.update(model, session, 0.1)
	audio.play_hint()
	for player in audio.get_children():
		check(not player.playing, "Ton aus stoppt auch die Hinweise.")
	session.sound_enabled = true
	session.engine_volume = 0.0
	session.environment_volume = 0.0
	session.hint_volume = 0.5
	audio.update(model, session, 1.0)
	audio.play_hint()
	check(audio.engine.volume_db <= -70 and audio.forest.volume_db <= -70 and audio.hint.playing,
		"Motor und Umgebung lassen sich unabhängig vom Hinweis stummschalten.")
	session.open_settings()
	session.activate(4)
	check(session.state == "AUDIO", "Die Einstellungen öffnen die Lautstärken.")
	check(session.submit_voice("next") and session.submit_voice("select"), "Die Sprachbefehle bedienen die Lautstärken.")
	session.engine_volume = 0.25
	session.environment_volume = 0.5
	session.hint_volume = 0.75
	scene.save_settings()
	var path: String = scene.settings_path
	scene.free()
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.settings_path = path
	root.add_child(restored)
	restored.set_physics_process(false)
	restored.set_process(false)
	check(restored.session.engine_volume == 0.25 and restored.session.environment_volume == 0.5 and restored.session.hint_volume == 0.75,
		"Der nächste Start übernimmt die drei Lautstärken.")
	restored.free()
	DirAccess.remove_absolute(path)
	print("TON: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
