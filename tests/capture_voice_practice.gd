extends SceneTree
# Zeigt die echte Spielszene mit künstlichen Testbefehlen, ohne Mikrofonzugriff.
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")

func _initialize() -> void:
	call_deferred("run")

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
	scene.ui.practice_panel.selected.emit(0)
	scene._physics_process(0.016)
	scene.voice.consume_bytes((JSON.stringify({"type":"command", "seq":1, "epoch":scene.voice.epoch, "command":"left", "strength":0.9}) + "\n").to_utf8_buffer())
	scene._physics_process(0.016)
	scene._process(0.016)
	scene.ui.practice_panel.compass.set_process(false)
	for size in [Vector2i(1280, 800), Vector2i(960, 640)]:
		DisplayServer.window_set_size(size)
		for index in range(8): await process_frame
		scene.ui.practice_panel.compass.confirm("left", 0.9)
		await RenderingServer.frame_post_draw
		var path := "res://docs/voice-practice.png" if size.x == 1280 else "/private/tmp/stuntcar-practice-small.png"
		root.get_texture().get_image().save_png(path)
	scene.queue_free()
	for index in range(3): await process_frame
	quit()
