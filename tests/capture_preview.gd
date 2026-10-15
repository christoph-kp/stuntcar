extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(file)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	for i in range(30):
		await process_frame
	await capture("res://docs/preview-menu.png")
	scene.session.restart()
	for i in range(700):
		await physics_frame
		if scene.model.distance_m >= 86.0:
			break
	scene.session.press(1)
	for i in range(8):
		await process_frame
	await capture("res://docs/preview-drive.png")
	for i in range(180):
		await physics_frame
		if scene.model.distance_m >= 136.0:
			break
	await capture("res://docs/preview-edge.png")
	scene.session.press(1)
	for i in range(40):
		await physics_frame
	await capture("res://docs/preview-correction.png")
	scene.session.pause()
	scene.session.open_settings()
	scene.on_action("rebind")
	for i in range(5):
		await process_frame
	await capture("res://docs/preview-settings.png")
	quit()
