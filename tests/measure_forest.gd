extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	root.always_on_top = true
	root.grab_focus()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-forest-performance-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.restart()
	for frame in range(120):
		scene._process(1.0/60.0)
		await process_frame
	var times: Array[float] = []
	var peak_draws := 0
	var peak_triangles := 0
	var sent := {}
	for frame in range(ceili(scene.track.length_m / 14.0 * 60.0) + 300):
		if scene.session.state == "PAUSED": scene.session.activate(0)
		for curve in scene.track.curves:
			if scene.model.distance_m > curve.start_m - 28 and not sent.has(curve.id):
				scene.session.press(curve.turn_sign)
				sent[curve.id] = true
		var before := Time.get_ticks_usec()
		scene._physics_process(1.0/60.0)
		scene._process(1.0/60.0)
		await process_frame
		times.append(float(Time.get_ticks_usec()-before)/1000.0)
		peak_draws = maxi(peak_draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		peak_triangles = maxi(peak_triangles, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		if scene.session.state in ["FINISHED", "FALLING"]: break
	times.sort()
	var total := 0.0
	for t in times: total += t
	var result := {"resolution":"1280x800", "adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(), "frames":times.size(),
		"mean_ms":total/times.size(), "p95_ms":times[int(times.size()*0.95)],
		"fps":1000.0/(total/times.size()), "state":scene.session.state, "distance_m":scene.model.distance_m,
		"peak_draw_calls":peak_draws, "peak_primitives":peak_triangles,
		"note":"Die gesamte Waldstrecke. 120 Bilder Vorlauf. Keine Bildaufnahme während der Messung. Vertikale Synchronisation aktiv."}
	FileAccess.open("res://docs/wald-bildzeiten.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print(JSON.stringify(result))
	var finished: bool = scene.session.state == "FINISHED"
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit(0 if finished else 1)
