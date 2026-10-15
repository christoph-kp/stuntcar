extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.always_on_top = true
	root.grab_focus()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-stunts-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.restart()
	var sent := {}
	var targets := [45, 125, 235, 275, 307, 450, 585, 625, 660, 800, 900]
	var shot := 0
	var frames_airborne := 0
	var peak := 0.0
	for frame in range(4000):
		if scene.session.state == "PAUSED": scene.session.activate(0)
		for curve in scene.track.curves:
			if scene.model.distance_m > curve.start_m - 28 and not sent.has(curve.id):
				scene.session.press(curve.turn_sign)
				sent[curve.id] = true
		scene._physics_process(1.0/60.0)
		scene._process(1.0/60.0)
		if scene.model.airborne: frames_airborne += 1
		peak = maxf(peak, scene.car.global_position.y)
		await process_frame
		if shot < targets.size() and scene.model.distance_m >= targets[shot]:
			scene.ui.visible = false
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://docs/stunt-%03d.png" % targets[shot])
			if targets[shot] == 275:
				root.get_texture().get_image().save_png("res://tracks/previews/forest.png")
			shot += 1
		if scene.session.state in ["FINISHED", "FALLING"]: break
	print("STUNT-SICHTPRÜFUNG: Zustand=%s, Bilder=%d, Flugzeit=%.2f s, Höhe=%.1f m" % [scene.session.state, shot, frames_airborne / 60.0, peak])
	var ok: bool = scene.session.state == "FINISHED" and shot == targets.size()
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit(0 if ok else 1)
