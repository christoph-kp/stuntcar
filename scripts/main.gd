extends Node3D

const TrackData = preload("res://scripts/track/track_data.gd")
const TrackBuilder = preload("res://scripts/track/track_builder.gd")
const DriveModel = preload("res://scripts/vehicle/drive_model.gd")
const CommandRouter = preload("res://scripts/input/command_router.gd")
const CarView = preload("res://scripts/vehicle/car_view.gd")
const FollowCamera = preload("res://scripts/camera/follow_camera.gd")
const GameUI = preload("res://scripts/ui/game_ui.gd")
const RaceAudio = preload("res://scripts/audio/race_audio.gd")
const VoiceBridge = preload("res://scripts/input/voice_bridge.gd")
const VoiceStrength = preload("res://scripts/input/voice_strength.gd")

var track
var builder: Node3D
var control_mode := ""
var settings_path := "user://settings.cfg"
var model
var session
var car: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var sound: AudioStreamPlayer
var race_audio
var key_left := KEY_A
var key_right := KEY_D
var pending: Array[int] = []
var held: Dictionary = {}
var binding_stage := 0
var candidate_key := 0
var bind_timeout := 0.0
var hinted_ids: Dictionary = {}
var previous_state := "MENU"
var voice
var voice_context := ""
var voice_applied_count := 0
var voice_action_text := tr("I18N_VOICE_NO_ACTION")

func _ready() -> void:
	track = TrackData.new()
	model = DriveModel.new(track)
	model.reset(5.0)
	session = CommandRouter.new(model)
	session.action_requested.connect(on_action)
	load_settings()
	builder = TrackBuilder.new()
	add_child(builder)
	builder.build(track)
	car = CarView.new()
	add_child(car)
	car.place(model)
	camera = FollowCamera.new()
	camera.far = 1800
	add_child(camera)
	camera.current = true
	ui = GameUI.new()
	add_child(ui)
	ui.menu_selected.connect(func(index): session.activate(index))
	update_key_names()
	race_audio = RaceAudio.new()
	add_child(race_audio)
	sound = race_audio.hint
	voice = VoiceBridge.new()
	add_child(voice)
	voice.unavailable.connect(on_voice_unavailable)
	sync_voice_context()
	session.control_mode = control_mode
	session.open_tracks()
	if control_mode == "voice":
		session.voice_enabled = true
		voice.start()
	sync_voice_context()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not event.pressed:
		held.erase(code)
		return
	if event.echo or held.has(code):
		return
	held[code] = true
	if binding_stage > 0:
		capture_binding(code)
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ESCAPE:
		pending.clear()
		session.pause()
	elif code == key_left:
		pending.append(-1)
	elif code == key_right:
		pending.append(1)
	else:
		return
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if session == null:
		return
	sync_voice_context()
	if voice != null:
		voice.poll()
		for packet in voice.take_commands():
			if packet.epoch != voice.epoch or binding_stage > 0: continue
			var word := str(packet.get("text", packet.command)).left(40)
			var strength := VoiceStrength.normalize(packet.get("strength", VoiceStrength.NORMAL))
			if session.submit_voice(packet.command, strength):
				voice_applied_count += 1
				voice_action_text = tr("I18N_VOICE_ACTION") % [word, voice_applied_count]
				if packet.command in ["faster", "slower"]:
					voice_action_text += "\n" + model.speed_feedback
				if session.state == "RUNNING":
					ui.voice_compass.confirm(packet.command, strength)
				sync_voice_context()
			else:
				voice_action_text = tr("I18N_VOICE_NO_EFFECT") % word
	var both := (held.has(key_left) and held.has(key_right)) or (pending.has(-1) and pending.has(1))
	if not both and not pending.is_empty():
		session.press(pending[0])
	pending.clear()
	if binding_stage > 0:
		bind_timeout -= delta
		if bind_timeout <= 0:
			binding_stage = 0
	var was_running: bool = session.state == "RUNNING"
	session.step(delta)
	if was_running:
		car.drive(model, delta)
	elif session.state == "FALLING":
		car.fall(delta)
	race_audio.update(model, session, delta)
	if session.state == "RUNNING":
		var curve: Dictionary = track.next_curve(model.distance_m)
		if not curve.is_empty() and model.distance_m >= curve.start_m - model.input_window_m() and not hinted_ids.has(curve.id):
			hinted_ids[curve.id] = true
			if session.sound_enabled:
				race_audio.play_hint()
	previous_state = session.state
	sync_voice_context()

func sync_voice_context() -> void:
	if voice == null: return
	var context := "%s:%d" % [session.state, binding_stage]
	if context != voice_context:
		voice_context = context
		pending.clear()
		voice.invalidate()
		ui.voice_compass.clear()

func on_voice_unavailable(_message: String) -> void:
	session.voice_enabled = false
	session.pause()
	pending.clear()

func _process(delta: float) -> void:
	if session == null:
		return
	if is_instance_valid(builder.landscape): builder.landscape.follow(car.global_position)
	camera.follow(car, model.heading, delta, session.state in ["MENU", "CONTROL", "TRACKS"], model.pitch, model.speed_mps)
	var message := ""
	if binding_stage == 1:
		message = tr("I18N_KEY_BIND_LEFT")
	elif binding_stage == 2:
		message = tr("I18N_KEY_BIND_RIGHT")
	if binding_stage > 0:
		message += tr("I18N_KEY_BIND_TIMEOUT") % ceili(bind_timeout)
	ui.voice_text = voice.status_text if voice != null else tr("I18N_VOICE_OFF")
	ui.voice_visible = session.voice_enabled
	ui.voice_compass.set_input(voice.input_direction, voice.input_level)
	ui.render(session, message)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and session != null:
		session.pause()
		held.clear()
		pending.clear()

func on_action(action: String) -> void:
	if action.begins_with("track:"):
		select_track(action.trim_prefix("track:"))
		return
	match action:
		"control_keys", "control_voice":
			control_mode = "voice" if action == "control_voice" else "keys"
			session.control_mode = control_mode
			session.voice_enabled = control_mode == "voice"
			pending.clear()
			voice_applied_count = 0
			voice_action_text = tr("I18N_VOICE_NO_ACTION")
			if session.voice_enabled: voice.start()
			else: voice.stop()
			save_settings()
		"quit": get_tree().quit()
		"reset_car":
			if race_audio != null: race_audio.reset()
			if voice != null: voice.invalidate()
			if is_instance_valid(car):
				car.place(model)
			if is_instance_valid(camera):
				camera.initialized = false
			hinted_ids.clear()
			pending.clear()
		"save_settings": save_settings()
		"rebind":
			binding_stage = 1
			bind_timeout = 30.0

func select_track(path: String) -> void:
	var replacement = TrackData.new(path)
	if not replacement.valid:
		session.open_tracks()
		session.catalog_errors.append(path.get_file() + ": " + replacement.validation_error)
		return
	track = replacement
	model.track = track
	model.reset(5.0)
	if is_instance_valid(builder):
		remove_child(builder)
		builder.free()
	builder = TrackBuilder.new()
	add_child(builder)
	builder.build(track)
	session.go_to_menu()
	held.clear()
	pending.clear()
	save_settings()


func capture_binding(code: int) -> void:
	if code == KEY_ESCAPE:
		binding_stage = 0
		return
	if binding_stage == 1:
		candidate_key = code
		binding_stage = 2
		bind_timeout = 30.0
	elif code != candidate_key:
		key_left = candidate_key
		key_right = code
		binding_stage = 0
		save_settings()
		update_key_names()

func update_key_names() -> void:
	ui.left_name = OS.get_keycode_string(key_left)
	ui.right_name = OS.get_keycode_string(key_right)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "mode", control_mode)
	config.set_value("game", "track", track.source_path)
	config.set_value("input", "left", key_left)
	config.set_value("input", "right", key_right)
	config.set_value("game", "hint_seconds", model.hint_seconds)
	config.set_value("game", "sound", session.sound_enabled)
	for key in ["engine_volume", "environment_volume", "hint_volume"]:
		config.set_value("audio", key, session.get(key))
	var error := config.save(settings_path)
	if error != OK:
		push_warning(tr("I18N_SETTINGS_SAVE_FAILED"))

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var mode = config.get_value("input", "mode", "")
	if mode in ["keys", "voice"]:
		control_mode = mode
		session.control_mode = mode
	var selected = config.get_value("game", "track", TrackData.DEFAULT_PATH)
	for route in TrackData.catalog():
		if route.path == selected:
			track = TrackData.new(selected)
			model.track = track
			model.reset(5.0)
			break
	var left = config.get_value("input", "left", KEY_A)
	var right = config.get_value("input", "right", KEY_D)
	if typeof(left) == TYPE_INT and typeof(right) == TYPE_INT and left != right and left > 0 and right > 0 and left != KEY_ESCAPE and right != KEY_ESCAPE:
		key_left = left
		key_right = right
	var seconds = config.get_value("game", "hint_seconds", 5.0)
	if seconds in [3.0, 5.0, 8.0]:
		model.hint_seconds = seconds
	var enabled = config.get_value("game", "sound", true)
	if typeof(enabled) == TYPE_BOOL:
		session.sound_enabled = enabled

	for key in ["engine_volume", "environment_volume", "hint_volume"]:
		var volume = config.get_value("audio", key, session.get(key))
		if (typeof(volume) == TYPE_FLOAT or typeof(volume) == TYPE_INT) and is_finite(float(volume)):
			session.set(key, clampf(float(volume), 0.0, 1.0))
