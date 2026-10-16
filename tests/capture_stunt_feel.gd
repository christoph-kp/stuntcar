extends SceneTree
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")
func _initialize() -> void: call_deferred("run")
func command(scene, word: String) -> void:
	scene.ui.voice_compass.clear()
	scene.sync_voice_context()
	scene.voice.accept_packet({"type":"command","seq":scene.voice.last_seq+1,"epoch":scene.voice.epoch,"command":word,"strength":0.9})
	scene._physics_process(1.0/60.0)
func capture(scene, path: String) -> void:
	scene._process(0.1)
	for i in range(16): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stunt-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.voice_enabled = true
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.voice.start()
	scene.ui.voice_compass.set_process(false)
	DisplayServer.window_set_size(Vector2i(1280,800))
	scene.session.restart()
	scene.model.reset(20.0)
	scene.car.place(scene.model)
	command(scene,"faster")
	for i in range(30): scene._physics_process(1.0/60.0)
	await capture(scene,"res://docs/stunt-boost.png")
	scene.session.restart()
	var curve: Dictionary = scene.track.curves[0]
	scene.model.reset(curve.start_m + 15.0)
	scene.model.speed_mps = 40.0
	scene.model.target_speed_mps = 40.0
	scene.car.place(scene.model)
	scene.camera.initialized = false
	command(scene,"right" if curve.turn_sign > 0 else "left")
	for i in range(16): scene._physics_process(1.0/60.0)
	await capture(scene,"res://docs/stunt-drift.png")
	scene.session.restart()
	scene.model.reset(45.0)
	scene.model.speed_mps = 40.0
	scene.model.target_speed_mps = 40.0
	scene.car.place(scene.model)
	scene.camera.initialized = false
	command(scene,"slower")
	for i in range(7): scene._physics_process(1.0/60.0)
	await capture(scene,"res://docs/stunt-brake.png")
	scene.queue_free()
	for i in range(3): await process_frame
	quit()
