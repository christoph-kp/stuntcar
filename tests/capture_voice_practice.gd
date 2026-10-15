extends SceneTree
# Die echte Spielszene erhält künstliche Befehle. Das Mikrofon bleibt aus.
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")

func _initialize() -> void:
	call_deferred("run")

func prepare_prompt(scene, attempt: int = 0) -> void:
	scene.session.practice.start("direct")
	scene.session.practice.attempted = attempt
	scene.session.practice.step(0.2, true)
	scene.sync_voice_context()
	scene.voice.last_message_ms = Time.get_ticks_msec()

func prepare_feedback(scene) -> void:
	prepare_prompt(scene)
	scene.voice.consume_bytes((JSON.stringify({"type":"command", "seq":scene.voice.last_seq + 1, "epoch":scene.voice.epoch, "command":"left", "strength":0.9}) + "\n").to_utf8_buffer())
	scene._physics_process(0.3)

func capture(scene, path: String, prepare: Callable, phase: String) -> void:
	# Erst das Fenster stabilisieren, dann den künstlichen Testzustand setzen.
	for retry in range(3):
		for index in range(8): await process_frame
		prepare.call()
		scene._process(0.016)
		await RenderingServer.frame_post_draw
		if scene.session.practice.phase != phase: continue
		root.get_texture().get_image().save_png(path)
		return
	push_error("Die Bildaufnahme verlor ihren Testzustand: " + path)
	quit(1)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-practice-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.voice.stop()
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.control_mode = "keys"
	scene.session.open_settings()
	scene.session.activate(5)
	scene.sync_voice_context()
	scene.ui.practice_panel.compass.set_process(false)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await capture(scene, "res://docs/voice-practice.png", func(): prepare_prompt(scene), "listening")
	await capture(scene, "res://docs/voice-practice-feedback.png", func(): prepare_feedback(scene), "transition")
	# Die weiteren Bilder zeigen ausschließlich künstliche Testzustände.
	for attempt in [3, 6, 9]:
		await capture(scene, "/private/tmp/practice-prompt-%d.png" % attempt, func(): prepare_prompt(scene, attempt), "listening")
	DisplayServer.window_set_size(Vector2i(960, 640))
	await capture(scene, "/private/tmp/stuntcar-practice-small.png", func(): prepare_prompt(scene), "listening")
	await capture(scene, "/private/tmp/practice-result-small.png", func():
		scene.session.practice.attempted = 12
		scene.session.practice.correct = 10
		scene.session.practice.wrong = 1
		scene.session.practice.missed = 1
		scene.session.practice.phase = "done"
		scene.session.practice.store_result()
	, "done")
	scene.queue_free()
	for index in range(3): await process_frame
	quit()
