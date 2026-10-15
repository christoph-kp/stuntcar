extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-audio-ui-unused.cfg"
	root.add_child(scene)
	scene.set_physics_process(false)
	scene._process(0.1)
	scene.set_process(false)
	scene.session.control_mode = "keys"
	scene.session.state = "SETTINGS"
	scene.ui.render(scene.session)
	for i in range(12): await process_frame
	if scene.ui.menu_panel.get_global_rect().end.y > 676:
		printerr("Das Einstellungsmenü überdeckt die Tastenhilfe.")
		quit(1)
		return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/ton-einstellungen.png")
	scene.session.activate(4)
	scene.ui.render(scene.session)
	for i in range(12): await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://docs/ton-menue.png")
	print("TONMENÜ: Bilder gespeichert")
	scene.free()
	quit()
