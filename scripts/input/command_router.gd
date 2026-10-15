extends RefCounted

signal action_requested(action: String)
var model
var state := "MENU"
var menu_index := 0
var previous_state := "MENU"
var last_key := 0
var remembered_curve := -1
var fall_time := 0.0
var retry_count := 0
var checkpoint_m := 0.0
var total_time := 0.0
var sound_enabled := true
var voice_enabled := false
var paused_from := "RUNNING"
var control_return := "MENU"
var control_mode := "keys"
var routes: Array[Dictionary] = []
var catalog_errors: Array[String] = []

func submit_voice(command: String) -> bool:
	match command:
		"left", "right":
			if state != "RUNNING": return false
			press(-1 if command == "left" else 1)
		"faster", "slower":
			if state != "RUNNING": return false
			model.change_speed(1 if command == "faster" else -1)
		"pause":
			if state != "RUNNING": return false
			pause()
		"resume":
			if state != "PAUSED": return false
			activate(0)
		"start":
			if state not in ["MENU", "FINISHED"]: return false
			restart()
		"next", "select":
			if state not in ["MENU", "PAUSED", "FINISHED", "SETTINGS", "CONTROL", "TRACKS"]: return false
			press(-1 if command == "next" else 1)
		_: return false
	return true

func _init(drive_model) -> void:
	model = drive_model

func entries() -> Array[String]:
	var voice_entry := "Steuerung: Sprache + Tasten" if control_mode == "voice" else "Steuerung: Zwei Tasten"
	match state:
		"MENU": return ["Fahrt starten", "Strecke wählen", "Einstellungen", "Beenden"]
		"PAUSED": return ["Weiterfahren", "Neu starten", "Einstellungen", voice_entry, "Beenden"]
		"FINISHED": return ["Noch einmal fahren", "Zur Übersicht", "Strecke wählen", "Beenden"]
		"SETTINGS": return ["Hinweis: %d Sekunden" % int(model.hint_seconds), "Ton: " + ("Ein" if sound_enabled else "Aus"), "Tasten ändern", voice_entry, "Zurück"]
		"CONTROL": return ["Zwei Tasten", "Sprache + Tasten"]
		"TRACKS":
			var result: Array[String] = []
			for route in routes: result.append(route.name)
			result.append("Einstellungen")
			result.append("Beenden")
			return result
	return []

func press(direction: int) -> void:
	if state == "RUNNING":
		last_key = direction
		model.request_turn(direction)
		remembered_curve = model.active_curve_id
		return
	var options := entries()
	if options.is_empty():
		return
	if direction == -1:
		menu_index = (menu_index + 1) % options.size()
	else:
		activate(menu_index)

func activate(index: int) -> void:
	if index < 0 or index >= entries().size():
		return
	match state:
		"MENU":
			if index == 0: restart()
			elif index == 1: open_tracks()
			elif index == 2: open_settings()
			else: action_requested.emit("quit")
		"PAUSED":
			if index == 0:
				state = paused_from
				last_key = 0
			elif index == 1: restart()
			elif index == 2: open_settings()
			elif index == 3: open_controls()
			else: action_requested.emit("quit")
		"FINISHED":
			if index == 0: restart()
			elif index == 1: go_to_menu()
			elif index == 2: open_tracks()
			else: action_requested.emit("quit")
		"SETTINGS":
			if index == 0:
				var values := [3.0, 5.0, 8.0]
				model.hint_seconds = values[(values.find(model.hint_seconds) + 1) % 3]
				action_requested.emit("save_settings")
			elif index == 1:
				sound_enabled = not sound_enabled
				action_requested.emit("save_settings")
			elif index == 2: action_requested.emit("rebind")
			elif index == 3: open_controls()
			else:
				state = previous_state
				menu_index = 0

		"CONTROL":
			control_mode = "keys" if index == 0 else "voice"
			state = control_return
			menu_index = 0
			action_requested.emit("control_" + control_mode)
		"TRACKS":
			if index < routes.size():
				state = "MENU"
				menu_index = 0
				action_requested.emit("track:" + routes[index].path)
				if state == "TRACKS": return
				if control_mode.is_empty():
					control_return = "MENU"
					state = "CONTROL"
			elif index == routes.size(): open_settings()
			else: action_requested.emit("quit")

func open_controls() -> void:
	control_return = state
	state = "CONTROL"
	menu_index = 0 if control_mode == "keys" else 1

func open_tracks() -> void:
	var report: Dictionary = model.track.scan_catalog()
	routes.assign(report.routes)
	catalog_errors.assign(report.errors)
	state = "TRACKS"
	menu_index = 0
	for i in range(routes.size()):
		if routes[i].path == model.track.source_path: menu_index = i


func restart() -> void:
	model.reset(5.0)
	state = "RUNNING"
	menu_index = 0
	last_key = 0
	remembered_curve = -1
	retry_count = 0
	checkpoint_m = 5.0
	total_time = 0.0
	action_requested.emit("reset_car")

func go_to_menu() -> void:
	model.reset(5.0)
	state = "MENU"
	menu_index = 0
	last_key = 0
	action_requested.emit("reset_car")

func open_settings() -> void:
	previous_state = state
	state = "SETTINGS"
	menu_index = 0

func pause() -> void:
	if state in ["RUNNING", "FALLING"]:
		paused_from = state
		state = "PAUSED"
		menu_index = 0
		last_key = 0

func step(delta: float) -> void:
	if state == "RUNNING":
		model.step(delta)
		if remembered_curve >= 0 and model.active_curve_id == -1:
			last_key = 0
			remembered_curve = -1
		for curve in model.track.curves:
			if model.distance_m >= curve.checkpoint_m:
				checkpoint_m = curve.checkpoint_m
		if model.off_road:
			state = "FALLING"
			fall_time = 0.0
			retry_count += 1
		elif model.finished:
			state = "FINISHED"
			menu_index = 0
	elif state == "FALLING":
		fall_time += delta
		if fall_time >= 1.1:
			total_time += model.elapsed_s
			model.reset(checkpoint_m)
			state = "RUNNING"
			menu_index = 0
			last_key = 0
			remembered_curve = -1
			action_requested.emit("reset_car")
