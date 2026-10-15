extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(960, 640)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-selection-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	# Exercise the visible recovery state without changing any real track file.
	scene.session.control_mode = "voice"
	scene.voice.fail("Das Mikrofon fehlt.")
	scene.session.routes.clear()
	scene.session.menu_index = 0
	scene.session.catalog_errors.assign(["meine_strecke.json: JSON-Fehler in Zeile 4. Prüfe die Anführungszeichen."])
	for i in range(10):
		scene._process(0.016)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/auswahl-fehlerpruefung.png")
	scene.queue_free()
	await process_frame
	quit()
