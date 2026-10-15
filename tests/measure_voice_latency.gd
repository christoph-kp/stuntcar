extends SceneTree

var scene
var applied: Array[float] = []
var started := 0
var seen := 0
var source_report := "/private/tmp/stuntcar-replay-source.json"
var output_report := "/private/tmp/stuntcar-replay-result.json"
var captured := false
var fixture := "res://voice/tests/audio/continuous/left-five.wav"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): fixture = args[0]
	scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-voice-measure-unused.cfg"
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.session.restart()
	scene.session.sound_enabled = false
	scene.session.voice_enabled = true
	scene.model.reset(280.0)
	scene.car.place(scene.model)
	scene.sync_voice_context()
	var voice = scene.voice
	voice.enabled = true
	voice.started_ms = Time.get_ticks_msec()
	voice.last_message_ms = voice.started_ms
	voice.token = "synthetic-test-only"
	if voice.server.listen(0, "127.0.0.1") != OK:
		quit(1)
		return
	voice.child_pid = OS.create_process(ProjectSettings.globalize_path("res://.tools/voice-env/bin/python"), PackedStringArray([
		ProjectSettings.globalize_path("res://voice/tests/replay_microphone.py"),
		"--port", str(voice.server.get_local_port()), "--token", voice.token,
		"--fixture", ProjectSettings.globalize_path(fixture), "--report", source_report]))
	started = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 10000:
		await process_frame
		# Keep the test in the driving state even if another desktop window takes focus.
		scene.session.state = "RUNNING"
		scene.model.reset(280.0)
		scene.car.place(scene.model)
		scene._physics_process(1.0 / 60.0)
		while seen < scene.voice_applied_count:
			applied.append(Time.get_unix_time_from_system())
			seen += 1
		if not captured and seen >= 5 and DisplayServer.get_name() != "headless":
			captured = true
			scene._process(0.016)
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://docs/preview-voice-stream.png")
		if not voice.enabled: break
	var source = JSON.parse_string(FileAccess.get_file_as_string(source_report))
	var delays: Array[float] = []
	for i in range(mini(applied.size(), source.words.size())):
		delays.append(snappedf((applied[i] - float(source.start_unix) - float(source.words[i].end)) * 1000.0, 1.0))
	var report := {"fixture":fixture, "expected_words":source.words.size(), "applied":applied.size(), "delay_after_estimated_word_end_ms":delays, "action":scene.voice_action_text, "state":scene.session.state, "voice_status":voice.status_text}
	FileAccess.open(output_report, FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("SPRACHMESSUNG: ", JSON.stringify(report))
	var ok: bool = applied.size() == source.words.size() and applied.size() >= 5
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
