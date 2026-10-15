extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func inspect(node: Node) -> void:
	if node is Label or node is Button or node is RichTextLabel or node is Label3D:
		var value: String = node.text
		for forbidden in ["I18N_", "Deine", "Sprache", "Kurven", "Wähle", "Einstellungen", "Fahrt", "Sekunden", "Sprünge", "LINKS", "RECHTS", "ZIEL", "LANDUNG"]:
			if forbidden in value:
				failures += 1
				push_error("Nicht übersetzter Text: " + value)
	for child in node.get_children(): inspect(child)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-english-ui-unused.cfg"
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.session.control_mode = "keys"
	for state in ["TRACKS", "MENU", "CONTROL", "SETTINGS", "AUDIO", "PAUSED", "FINISHED", "RUNNING"]:
		scene.session.state = state
		scene.session.menu_index = 0
		scene._process(0.016)
		for i in range(6): await process_frame
		inspect(scene)
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://docs/english-" + state.to_lower() + ".png")
	print("ENGLISCHE SPIELSZENE: %d Textfehler" % failures)
	scene.free()
	quit(0 if failures == 0 else 1)
