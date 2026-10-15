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

func send(voice, command: String, seq: int, epoch: int) -> void:
	voice.consume_bytes((JSON.stringify({"type":"command", "command":command, "text":command, "seq":seq, "epoch":epoch}) + "\n").to_utf8_buffer())

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-test-unused.cfg"
	root.add_child(scene)
	scene.session.state = "MENU"
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.restart()
	scene.model.reset(80.0)
	scene.car.place(scene.model)
	scene.sync_voice_context()
	var voice = scene.voice
	voice.enabled = true
	voice.authenticated = true
	voice.is_ready = true
	voice.last_message_ms = Time.get_ticks_msec()
	send(voice, "right", 1, voice.epoch)
	scene._physics_process(1.0/60.0)
	check(scene.model.active_curve_id == 0, "Der Sprachbefehl erreicht das echte Auto")
	for number in range(2, 6):
		send(voice, "right", number, voice.epoch)
		scene._physics_process(1.0/60.0)
	check(scene.get("voice_applied_count") == 5, "Jede Wiederholung erreicht das Auto und den sichtbaren Zähler genau einmal")
	scene._process(0.016)
	check(scene.ui.voice_compass.tip_lit("right"), "Die Pfeilspitze bestätigt die ausgeführten Lenkbefehle")
	send(voice, "slower", 6, voice.epoch)
	scene._physics_process(1.0/60.0)
	check(scene.model.speed_mps < 22.0, "Der Sprachbefehl bremst das echte Auto")
	send(voice, "pause", 7, voice.epoch)
	send(voice, "resume", 8, voice.epoch)
	scene.pending.append(1)
	scene._physics_process(1.0/60.0)
	check(scene.session.state == "PAUSED", "Ein alter Befehl beendet die neue Pause nicht")
	scene.session.activate(0)
	scene.sync_voice_context()
	var before_speed: float = scene.model.target_speed_mps
	send(voice, "faster", 9, voice.epoch)
	send(voice, "faster", 10, voice.epoch)
	scene._physics_process(1.0/60.0)
	check(is_equal_approx(scene.model.target_speed_mps, before_speed + 10.0), "Zwei schnelle Gasbefehle erhöhen beide das Zieltempo")
	check("target" in scene.voice_action_text, "Die Sprachanzeige bestätigt das Zieltempo")
	send(voice, "slower", 11, voice.epoch)
	send(voice, "slower", 12, voice.epoch)
	scene._physics_process(1.0/60.0)
	check(is_equal_approx(scene.model.target_speed_mps, before_speed), "Zwei schnelle Bremsbefehle senken beide das Zieltempo")
	voice.fail("Testfehler")
	check(scene.session.state == "PAUSED", "Ein Mikrofonfehler hält eine laufende Fahrt an")
	scene.session.state = "FALLING"
	voice.fail("Testfehler beim Fall")
	scene._physics_process(2.0)
	check(scene.session.state == "PAUSED", "Ein Mikrofonfehler während des Falls startet keine neue Fahrt")
	scene.queue_free()
	await process_frame
	print("SPRACHE IM SPIEL: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
