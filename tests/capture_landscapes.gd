extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	root.size = Vector2i(1280, 800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-landscape-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://tracks/previews")
	var routes: Array = scene.track.catalog()
	for route in routes:
		scene.select_track(route.path)
		scene.model.reset(65)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		for i in range(45):
			scene.session.state = "RUNNING"
			scene._process(1.0 / 60.0)
			await process_frame
		scene.ui.visible = false
		await capture("res://tracks/previews/" + route.scenario + ".png")
		scene.ui.visible = true
		await capture("res://docs/fahrt-" + route.scenario + ".png")
	scene.session.open_tracks()
	scene.session.menu_index = 0
	for i in range(5):
		scene._process(0.016)
		await process_frame
	await capture("res://docs/streckenauswahl.png")
	root.size = Vector2i(960, 640)
	for i in range(5):
		scene._process(0.016)
		await process_frame
	await capture("res://docs/streckenauswahl-klein.png")
	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	quit()
