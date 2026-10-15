extends RefCounted

const VoiceCalibration = preload("res://scripts/input/voice_calibration.gd")
var calibration = VoiceCalibration.new()

const WORDS := ["left", "right", "faster", "slower"]
const REPEATS := 3
const WAIT_SECONDS := 4.0
const TRANSITION_SECONDS := 0.8
var phase := "ready"
var mode := "direct"
var attempted := 0
var correct := 0
var wrong := 0
var missed := 0
var remaining_s := 0.0
var last_heard := ""
var last_expected := ""
var last_result := ""
var generation := 0
var results := {
	"direct": {"correct": 0, "wrong": 0, "missed": 0, "attempted": 0},
	"checked": {"correct": 0, "wrong": 0, "missed": 0, "attempted": 0}
}

func expected_word() -> String:
	if phase == "done": return ""
	return WORDS[mini(attempted / REPEATS, WORDS.size() - 1)]

func prepare(selected_mode: String) -> void:
	calibration.reset()
	mode = selected_mode if selected_mode in ["direct", "checked"] else "direct"
	phase = "ready"
	attempted = 0
	correct = 0
	wrong = 0
	missed = 0
	remaining_s = 0.0
	last_heard = ""
	last_expected = ""
	last_result = ""
	generation += 1

func start(selected_mode: String) -> void:
	prepare(selected_mode)
	phase = "listening"
	remaining_s = WAIT_SECONDS
	store_result()

func begin_calibration(selected_mode: String) -> void:
	prepare(selected_mode)
	calibration.begin()
	phase = "calibrating"

func capture_level(rms: Variant, peak_rms: Variant, clipped: bool = false, speech_end: bool = false) -> void:
	if phase != "calibrating": return
	var previous: String = calibration.phase
	calibration.receive(rms, peak_rms, clipped, speech_end)
	if calibration.phase != previous: generation += 1

func wait_for_microphone(selected_mode: String) -> void:
	prepare(selected_mode)
	phase = "waiting"

func receive(word: String) -> bool:
	if phase != "listening": return false
	finish_attempt("correct" if word == expected_word() else "wrong", word)
	return true

func unrecognized(heard: String) -> void:
	if phase == "listening": finish_attempt("missed", heard)

func step(delta: float, microphone_ready: bool) -> void:
	if phase == "calibrating":
		if not microphone_ready: return
		var previous: String = calibration.phase
		calibration.step(delta)
		if calibration.phase != previous: generation += 1
		if calibration.phase == "done": phase = "calibrated"
		return
	if not microphone_ready or phase not in ["listening", "transition"]: return
	remaining_s = maxf(0.0, remaining_s - maxf(delta, 0.0))
	if remaining_s > 0.0: return
	if phase == "transition":
		phase = "done" if attempted >= WORDS.size() * REPEATS else "listening"
		remaining_s = 0.0 if phase == "done" else WAIT_SECONDS
		generation += 1
	else:
		unrecognized("")

func finish_attempt(result: String, heard: String) -> void:
	last_expected = expected_word()
	last_result = result
	last_heard = heard.left(70)
	match result:
		"correct": correct += 1
		"wrong": wrong += 1
		"missed": missed += 1
	attempted += 1
	phase = "transition"
	remaining_s = TRANSITION_SECONDS
	generation += 1
	store_result()

func store_result() -> void:
	results[mode] = {"correct": correct, "wrong": wrong, "missed": missed, "attempted": attempted}
