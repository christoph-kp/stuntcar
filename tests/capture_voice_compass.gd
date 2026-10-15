extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-compass-capture-unused.cfg"
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.voice_enabled = true
	scene.session.restart()
	scene.model.reset(280.0)
	scene.car.place(scene.model)
	scene.camera.follow(scene.car, scene.model.heading, 10.0, false, scene.model.pitch)
	scene.voice.status_text = scene.tr("I18N_VOICE_READY")
	scene._process(0.016)
	var compass = scene.ui.voice_compass
	compass.set_process(false)
	for item in [["left", 0.2, "quiet"], ["left", 0.5, "normal"], ["left", 0.95, "loud"], ["faster", 0.95, "faster"], ["slower", 0.5, "brake"], ["right", 0.5, "right"], ["", 0.0, "idle"]]:
		compass.clear()
		compass.set_input(item[0], item[1])
		compass.confirm(item[0], item[1])
		for i in range(4): await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://docs/voice-compass-" + item[2] + ".png")
	DisplayServer.window_set_size(Vector2i(960, 640))
	compass.clear()
	compass.set_input("left", 0.95)
	compass.confirm("left", 0.95)
	for i in range(6): await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/voice-compass-small.png")
	print("Pfeilkreuz: acht Ansichten aus der echten Spielszene gespeichert.")
	scene.free()
	quit()
