extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-forest-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	for distance in [45, 125, 220, 300, 465, 555]:
		scene.model.reset(distance)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		for frame in range(35):
			scene.session.state = "RUNNING"
			scene._process(1.0/60.0)
			await process_frame
		scene.ui.visible = false
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/wald-%03d.png" % distance)
		if distance == 45:
			root.get_texture().get_image().save_png("res://tracks/previews/forest.png")
			scene.ui.visible = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/wald-spiel.png")
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit()
