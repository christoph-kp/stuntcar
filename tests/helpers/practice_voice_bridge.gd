extends "res://scripts/input/voice_bridge.gd"
# Only the external microphone process is replaced. The protocol stays real.
var ready_on_start := true
var starts := 0

func start(mode: String = "direct") -> void:
	stop()
	starts += 1
	recognition_mode = mode
	enabled = true
	authenticated = true
	is_ready = ready_on_start
	started_ms = Time.get_ticks_msec()
	last_message_ms = started_ms
	status_text = tr("I18N_VOICE_READY") if is_ready else tr("I18N_VOICE_STARTING")
