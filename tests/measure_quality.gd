extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stunt-quality-performance-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	var results := []
	for route in scene.track.catalog():
		scene.select_track(route.path)
		scene.session.restart()
		scene.model.reset(50)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		var sent := {}
		var focus_pauses := 0
		var times: Array[float] = []
		for frame in range(300):
			# Keep this automated playback moving if macOS changes window focus.
			# Normal gameplay still pauses on focus loss.
			if scene.session.state == "PAUSED":
				scene.session.activate(0)
				focus_pauses += 1
			for curve in scene.track.curves:
				if scene.model.distance_m > curve.start_m - 28 and not sent.has(curve.id):
					scene.session.press(curve.turn_sign)
					sent[curve.id] = true
			var before := Time.get_ticks_usec()
			scene._physics_process(1.0/60.0)
			scene._process(1.0/60.0)
			await process_frame
			if frame >= 120: times.append(float(Time.get_ticks_usec()-before)/1000.0)
			if frame == 240:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/qualitaet-kurve-"+route.scenario+".png")
		times.sort()
		var total := 0.0
		for t in times: total += t
		var result := {"scenario":route.scenario,"frames":times.size(),"mean_ms":total/times.size(),"p95_ms":times[int(times.size()*0.95)],"fps":1000.0/(total/times.size()),"state":scene.session.state,"focus_pauses_resumed":focus_pauses}
		results.append(result)
		print(JSON.stringify(result))
	var file := FileAccess.open("res://docs/qualitaet-bildzeiten.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"resolution":"1280x800","adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"note":"Kurze Fahrt durch die erste Kurve je Strecke. 120 Bilder Vorlauf, dann 180 Messbilder. Vertikale Synchronisation aktiv. Einzelne Aufnahme während der Messung.","routes":results},"\t")+"\n")
	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	quit()
