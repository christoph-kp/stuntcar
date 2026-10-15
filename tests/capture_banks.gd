extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + file)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-bank-preview.cfg"
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.select_track("res://tracks/02_hoehenfahrt.json")
	scene.session.restart()
	for pair in [[580.0, 22.0], [290.0, 42.0]]:
		scene.model.reset(pair[0])
		scene.model.speed_mps = pair[1]
		scene.model.target_speed_mps = pair[1]
		scene.model.request_turn(scene.track.section_at(pair[0]).turn_sign)
		scene.model.step(0.01)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		for i in range(40):
			scene.session.state = "RUNNING"
			scene._process(1.0/60.0)
			await process_frame
		await capture("preview-bank-%d.png" % int(pair[0]))
	scene.model.reset(80)
	scene.car.place(scene.model)
	scene.session.state = "RUNNING"
	scene.session.submit_voice("faster")
	scene.session.state = "RUNNING"
	scene.session.submit_voice("faster")
	scene.camera.initialized = false
	for i in range(30):
		scene.session.state = "RUNNING"
		scene._process(1.0/60.0)
		await process_frame
	await capture("preview-speed.png")
	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	quit()
