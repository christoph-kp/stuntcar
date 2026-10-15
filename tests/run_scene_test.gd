extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	require(ResourceLoader.exists("res://scripts/main.gd"), "Die spielbare Hauptszene fehlt")
	if not failures.is_empty():
		quit(1)
		return
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-test-unused.cfg"
	root.add_child(scene)
	scene.session.state = "MENU"
	await physics_frame
	scene.session.sound_enabled = false
	scene.session.press(1)
	var fell := false
	var minimum_height := 12.0
	for i in range(1300):
		await physics_frame
		if scene.session.state == "FALLING":
			fell = true
			minimum_height = minf(minimum_height, scene.car.global_position.y)
		if fell and scene.session.state == "RUNNING":
			break
	require(fell and scene.session.state == "RUNNING", "Ohne Eingabe fällt das Auto und startet ohne Menü erneut")
	require(minimum_height < 11.0, "Der Fall verändert tatsächlich die Fahrzeughöhe")
	scene.session.restart()
	var sent := {}
	for i in range(5000):
		for curve in scene.track.curves:
			if scene.model.distance_m > curve.start_m - 28.0 and not sent.has(curve.id):
				scene.session.press(curve.turn_sign)
				sent[curve.id] = true
		await physics_frame
		if scene.session.state in ["FALLING", "FINISHED"]:
			break
	require(scene.session.state == "FINISHED", "Die echte Spielszene erreicht mit drei Eingaben das Ziel")
	print("SPIELPRÜFUNG: ", scene.session.state, " bei ", scene.model.distance_m, " m; Zeit: ", scene.model.elapsed_s, " s; Fehler: ", failures.size())
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
