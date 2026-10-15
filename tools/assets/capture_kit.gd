extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1440,960)
	for id in ["vehicle_studio","track_gallery","stunt_preview","alpine_preview","forest_preview","canyon_preview","coast_preview"]:
		var scene = load("res://assets/stuntcar_kit/examples/"+id+".tscn").instantiate()
		root.add_child(scene)
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var error := img.save_png("res://assets/stuntcar_kit/previews/"+id+".png")
		if error != OK:
			printerr("Bild fehlt: "+id)
			quit(1)
			return
		scene.free()
		await process_frame
	print("Sieben Godot-Bilder gespeichert.")
	quit()
