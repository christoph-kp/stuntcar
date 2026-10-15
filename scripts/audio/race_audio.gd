extends Node

signal effect_played(kind: String)

var engine: AudioStreamPlayer
var wind: AudioStreamPlayer
var road: AudioStreamPlayer
var forest: AudioStreamPlayer
var landing: AudioStreamPlayer
var suspension: AudioStreamPlayer
var hint: AudioStreamPlayer
var enabled := false
var was_running := false
var was_airborne := false
var hint_remaining := 0.0
var hint_level := 1.0

func _ready() -> void:
	engine = make_player("Motor", "engine", true)
	wind = make_player("Fahrtwind", "wind", true)
	road = make_player("Reifen", "road", true)
	forest = make_player("Wald", "forest", true)
	landing = make_player("Landung", "landing", false)
	suspension = make_player("Federung", "suspension", false)
	hint = AudioStreamPlayer.new()
	hint.name = "Hinweis"
	hint.stream = make_tone()
	add_child(hint)

func make_player(label: String, file: String, looped: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = label
	var stream: AudioStreamOggVorbis = load("res://assets/audio/%s.ogg" % file).duplicate()
	stream.loop = looped
	player.stream = stream
	player.volume_db = -80
	add_child(player)
	return player

func stop_playback() -> void:
	for player in get_children():
		player.stop()
		player.volume_db = -80
	enabled = false
	hint_remaining = 0.0

func reset() -> void:
	stop_playback()
	was_running = false
	was_airborne = false

func update(model, session, delta: float) -> void:
	var running: bool = session.state == "RUNNING"
	var falling: bool = session.state == "FALLING"
	enabled = session.sound_enabled and (running or falling)
	hint_level = session.hint_volume
	if not enabled:
		stop_playback()
		# Pause freezes motion: retain the edge for a landing on the first resumed step.
		if session.state not in ["PAUSED", "SETTINGS", "AUDIO", "CONTROL"]:
			was_running = running
			was_airborne = model.airborne
		return
	hint_remaining = maxf(0, hint_remaining - delta)
	var duck := -9.0 if hint_remaining > 0 else 0.0
	var voice_gain := -6.0 if session.voice_enabled else 0.0
	var background_gain := duck + voice_gain
	var speed := clampf((model.speed_mps - 14.0) / 32.0, 0, 1)
	var airborne: bool = model.airborne or falling
	var response := 1.0 - exp(-delta * 8.0)
	var pitch := lerpf(0.85, 1.8, speed) + (0.12 if airborne else 0.0)
	engine.pitch_scale = lerpf(engine.pitch_scale, pitch, response)
	wind.pitch_scale = lerpf(0.8, 1.25, speed)
	road.pitch_scale = lerpf(0.8, 1.3, speed)
	set_loop(engine, -9 + speed * 3 + background_gain, session.engine_volume, response)
	set_loop(wind, lerpf(-31, -20, speed) + (5 if airborne else 0) + background_gain, session.environment_volume, response)
	set_loop(road, -26 + speed * 5 + background_gain, 0.0 if airborne else session.engine_volume, response)
	set_loop(forest, -20 + background_gain, session.environment_volume if model.track.scenario == "forest" else 0.0, response)
	# A state edge triggers one impact. Pause, mute and reset cannot create an impact.
	if running and was_running and was_airborne and not model.airborne:
		landing.volume_db = gain_db(-10 + voice_gain, session.engine_volume)
		suspension.volume_db = gain_db(-23 + voice_gain, session.engine_volume)
		if session.engine_volume > 0:
			landing.play()
			suspension.play()
			effect_played.emit("landing")
	# Volume changes apply to effects that are already playing too.
	if session.engine_volume <= 0:
		landing.stop()
		suspension.stop()
	if hint_level <= 0: hint.stop()
	was_running = running
	was_airborne = model.airborne

func set_loop(player: AudioStreamPlayer, level: float, volume: float, response: float) -> void:
	var target := gain_db(level, volume)
	# Zero means immediate silence, including tyre noise at take-off.
	player.volume_db = -80 if volume <= 0 else linear_to_db(lerpf(db_to_linear(player.volume_db), db_to_linear(target), response))
	if volume > 0 and not player.playing: player.play()
	elif volume <= 0: player.stop()

func gain_db(level: float, volume: float) -> float:
	return -80.0 if volume <= 0 else level + linear_to_db(volume)

func play_hint() -> void:
	if not enabled or hint_level <= 0: return
	hint.volume_db = gain_db(-10, hint_level)
	hint.play()
	hint_remaining = 0.55
	# Apply the reduction immediately; the next update eases the recovery.
	for player in [engine, wind, road, forest]:
		player.volume_db = maxf(-80, player.volume_db - 9)
	effect_played.emit("hint")

func make_tone() -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var count := 6600
	bytes.resize(count * 2)
	for i in range(count):
		var phase := float(i) / 22050.0
		var envelope := sin(float(i) / count * PI)
		bytes.encode_s16(i * 2, int(sin(phase * TAU * 660.0) * envelope * 14000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream
