extends SceneTree

# A controlled sound demonstration. These inputs exercise the production mixer;
# they do not change the track, steering or the game's movement model.
var model
var session
var audio
var recorder: AudioEffectRecord
var elapsed := 0.0
var started_ms := 0
var done := false
var phases := [
	[0.0, "Gleichmäßige Fahrt"], [2.0, "Gasgeben und Hochschalten"],
	[6.0, "Hohes Tempo"], [8.0, "Gaswegnehmen und Zurückschalten"],
	[11.0, "Gleichmäßige Fahrt"], [12.0, "Rampe"],
	[14.0, "Sprung"], [16.0, "Landung"], [18.0, "Gaswegnehmen"]]
var markers: Array[Dictionary] = []
var previous_phase := -1
var previous_gear := 0
var shifts := 0
var landings := 0
var minimum_rpm := 10000.0
var maximum_rpm := 0.0

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	model = load("res://scripts/vehicle/drive_model.gd").new(load("res://scripts/track/track_data.gd").new())
	session = load("res://scripts/input/command_router.gd").new(model)
	session.restart()
	model.speed_mps = 14
	model.target_speed_mps = 14
	session.environment_volume = 0.0
	session.hint_volume = 0.0
	audio = load("res://scripts/audio/race_audio.gd").new()
	root.add_child(audio)
	audio.effect_played.connect(func(kind):
		if kind == "landing": landings += 1)
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	started_ms = Time.get_ticks_msec()

func _process(delta: float) -> bool:
	if recorder == null or done: return false
	elapsed = (Time.get_ticks_msec() - started_ms) / 1000.0
	var phase := 0
	for i in range(phases.size()):
		if elapsed >= phases[i][0]: phase = i
	if phase != previous_phase:
		markers.append({"time_s": elapsed, "phase": phases[phase][1]})
		previous_phase = phase
	model.target_speed_mps = 14 if elapsed < 2 or elapsed >= 18 else (46 if elapsed < 8 else 22)
	model.speed_mps = move_toward(model.speed_mps, model.target_speed_mps, delta * (10 if model.target_speed_mps > model.speed_mps else 18))
	model.airborne = elapsed >= 14 and elapsed < 16
	model.pitch = deg_to_rad(25) if elapsed >= 12 and elapsed < 14 else 0.0
	audio.update(model, session, delta)
	minimum_rpm = minf(minimum_rpm, audio.motor.rpm)
	maximum_rpm = maxf(maximum_rpm, audio.motor.rpm)
	if previous_gear > 0 and audio.motor.gear != previous_gear:
		shifts += 1
		markers.append({"time_s": elapsed, "gear": audio.motor.gear, "rpm": audio.motor.rpm})
	previous_gear = audio.motor.gear
	if elapsed >= 21:
		done = true
		recorder.set_recording_active(false)
		var recording := recorder.get_recording()
		var error := recording.save_to_wav("res://docs/motor-dynamisch.wav")
		var file := FileAccess.open("res://docs/motor-dynamisch-ablauf.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"phases": markers, "shifts": shifts, "landings": landings,
			"minimum_rpm": minimum_rpm, "maximum_rpm": maximum_rpm}, "\t") + "\n")
		file.close()
		print("DYNAMISCHER MOTOR: %d Gangwechsel, %d Landung, %.0f–%.0f U/min, %d Bytes" % [shifts, landings, minimum_rpm, maximum_rpm, recording.data.size()])
		var success := error == OK and shifts >= 2 and landings == 1 and maximum_rpm - minimum_rpm > 1500
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
		audio.free()
		audio = null
		recorder = null
		session = null
		model = null
		call_deferred("finish", 0 if success else 1)
	return false

func finish(code: int) -> void:
	await create_timer(0.2).timeout
	quit(code)
