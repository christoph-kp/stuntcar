extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-preview.cfg"
	root.add_child(scene)
	scene.set_physics_process(false)
	for i in range(15): await process_frame
	await capture("preview-control.png")
	scene.session.activate(0)
	scene.session.open_tracks()
	for i in range(4): await process_frame
	await capture("preview-tracks.png")
	scene.select_track("res://tracks/02_hoehenfahrt.json")
	scene.session.restart()
	for distance in [260.0, 390.0, 416.0, 435.0, 890.0]:
		scene.model.reset(distance)
		scene.model.step(0.01)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		for i in range(12): await process_frame
		await capture("preview-height-%d.png" % int(distance))
	scene.select_track("res://tracks/03_sprungstrecke.json")
	scene.session.restart()
	scene.model.reset(935.0)
	scene.model.step(0.01)
	scene.car.place(scene.model)
	scene.camera.initialized = false
	for i in range(12): await process_frame
	await capture("preview-jump.png")
	DirAccess.remove_absolute("/tmp/stuntcar-preview.cfg")
	scene.queue_free()
	await process_frame
	quit()
