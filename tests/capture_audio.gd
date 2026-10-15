extends SceneTree

var model
var session
var audio
var recorder: AudioEffectRecord
var elapsed := 0.0
var sent := {}
var accelerated := false
var slowed := false
var recorded_landings := 0
var finished := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	model = load("res://scripts/vehicle/drive_model.gd").new(load("res://scripts/track/track_data.gd").new())
	session = load("res://scripts/input/command_router.gd").new(model)
	session.restart()
	model.reset(180)
	audio = load("res://scripts/audio/race_audio.gd").new()
	root.add_child(audio)
	audio.effect_played.connect(func(kind):
		if kind == "landing": recorded_landings += 1)
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)

func _process(delta: float) -> bool:
	if recorder == null or finished: return false
	elapsed += delta
	if elapsed > 4 and not accelerated:
		model.change_speed(1)
		accelerated = true
	if elapsed > 12 and not slowed:
		model.change_speed(-1)
		slowed = true
	var next: Dictionary = model.track.next_curve(model.distance_m)
	if not next.is_empty() and not sent.has(next.id) and model.distance_m >= next.start_m - model.input_window_m():
		model.request_turn(next.turn_sign)
		audio.play_hint()
		sent[next.id] = true
	session.step(delta)
	audio.update(model, session, delta)
	if elapsed >= 18:
		recorder.set_recording_active(false)
		var recording := recorder.get_recording()
		var error := recording.save_to_wav("res://docs/tonprobe.wav")
		print("TONPROBE: %d Bytes, %d Landungen, Fehler %d" % [recording.data.size(), recorded_landings, error])
		finished = true
		var success := recording.data.size() > 44100 and recorded_landings >= 1 and error == OK
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
		audio.free()
		audio = null
		recorder = null
		session = null
		model = null
		call_deferred("finish_capture", 0 if success else 1)
	return false

func finish_capture(code: int) -> void:
	# Allow the audio thread to release its final playback buffers.
	await create_timer(0.2).timeout
	quit(code)
