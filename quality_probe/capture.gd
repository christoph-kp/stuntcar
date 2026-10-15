extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func settle(frames: int = 50) -> void:
	for i in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw

func capture(filename: String) -> void:
	await settle()
	var result := root.get_texture().get_image().save_png("res://captures/"+filename+".png")
	assert(result == OK,"Screenshot failed")

func run() -> void:
	root.size = Vector2i(1600,1000)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await settle(100)
	await capture("01-auto-tag")
	scene.hud.visible = false
	await capture("02-auto-detail")
	scene.hud.visible = true
	scene.set_camera(1)
	await capture("03-fahrkamera")
	scene.set_camera(0)
	scene.toggle_light()
	await capture("04-abendlicht")
	var times: Array[float] = []
	for frame in range(180):
		var before := Time.get_ticks_usec()
		await process_frame
		times.append(float(Time.get_ticks_usec()-before)/1000.0)
	times.sort()
	var total := 0.0
	for t in times:
		total += t
	var metrics := {
		"frames": times.size(),
		"resolution": "1600x1000",
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"mean_frame_ms": total/times.size(),
		"median_frame_ms": times[times.size()/2],
		"p95_frame_ms": times[int(times.size()*0.95)],
		"observed_fps": 1000.0/(total/times.size()),
		"note": "Static dusk view, VSync enabled. No whole-game performance claim."
	}
	var file := FileAccess.open("res://captures/metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	print(JSON.stringify(metrics))
	quit()
