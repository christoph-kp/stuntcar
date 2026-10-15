extends RefCounted
# Drei persönliche Signalpegel. Das bisherige Profil bleibt bis zum Abschluss erhalten.
const MIN_RMS := 180.0
const MAX_RMS := 32768.0
const SAMPLE_COUNT := 5
const PAUSE_SECONDS := 0.8
var phase := "ready"
var stage := 0
var samples: Array[float] = []
var values: Array[float] = []
var error := ""
var remaining_s := 0.0
var live_rms := 0.0
var levels: Array[float] = []
var device := ""
var display_reference := 6000.0
var range_limit := 18000.0
var normal_started := false
var range_changed := false

func reset() -> void:
	phase = "ready"
	stage = 0
	samples.clear()
	values.clear()
	error = ""
	remaining_s = 0.0
	live_rms = 0.0
	display_reference = levels[0] if valid_levels(levels) else 6000.0
	range_limit = display_reference * 3.0
	normal_started = false
	range_changed = false

func begin() -> void:
	reset()
	phase = "listening"

static func valid_signal(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= MAX_RMS

static func valid_levels(candidate: Variant) -> bool:
	if not candidate is Array or candidate.size() != 3: return false
	for value in candidate:
		if not valid_signal(value) or float(value) < MIN_RMS: return false
	return float(candidate[1]) >= float(candidate[0]) * 1.15 and float(candidate[2]) >= float(candidate[1]) * 1.15

func retry(message: String) -> void:
	error = message
	samples.clear()
	phase = "retry"
	remaining_s = PAUSE_SECONDS
	range_limit = display_reference * 3.0
	range_changed = false

func receive(rms: Variant, peak_rms: Variant, clipped: bool = false, speech_end: bool = false) -> void:
	if phase != "listening" or not valid_signal(rms) or not valid_signal(peak_rms): return
	live_rms = float(rms)
	if clipped:
		retry("I18N_CALIBRATION_TOO_LOUD")
		return
	if float(rms) >= MIN_RMS and float(peak_rms) >= float(rms):
		if stage == 0:
			if float(peak_rms) >= range_limit: range_changed = true
			display_reference = maxf(display_reference if normal_started else 0.0, float(peak_rms))
			normal_started = true
		# Der größte Pegel bleibt auch bei einem langen Wort erhalten.
		if samples.size() >= 64:
			samples[0] = maxf(samples[0], float(peak_rms))
		else:
			samples.append(float(peak_rms))
	if not speech_end: return
	if samples.size() < 2:
		retry("I18N_CALIBRATION_REPEAT_WORD")
		return
	var value: float = samples.max()
	live_rms = value
	if stage == 0 and value > MAX_RMS / (1.15 * 1.15):
		retry("I18N_CALIBRATION_TOO_LOUD")
		return
	if stage == 0 and range_changed:
		display_reference = value
		retry("I18N_CALIBRATION_RANGE_ADJUSTED")
		return
	if stage > 0 and value < values[-1] * 1.15:
		error = "I18N_CALIBRATION_MORE"
		samples.clear()
		return
	error = ""
	values.append(value)
	phase = "transition"
	remaining_s = PAUSE_SECONDS

func display_level() -> float:
	if values.is_empty(): return clampf(live_rms / maxf(MIN_RMS, display_reference) / 3.0, 0.0, 1.0)
	if live_rms <= values[0]: return clampf(live_rms / values[0] / 3.0, 0.0, 1.0)
	if values.size() == 1: return clampf(live_rms / values[0] / 3.0, 0.0, 1.0)
	if live_rms <= values[1]: return lerpf(1.0 / 3.0, 2.0 / 3.0, inverse_lerp(values[0], values[1], live_rms))
	if values.size() == 2: return clampf(live_rms / values[1] * 2.0 / 3.0, 0.0, 1.0)
	return clampf(lerpf(2.0 / 3.0, 1.0, inverse_lerp(values[1], values[2], live_rms)), 0.0, 1.0)

func step(delta: float) -> void:
	if phase not in ["transition", "retry"]: return
	remaining_s = maxf(0.0, remaining_s - maxf(delta, 0.0))
	if remaining_s > 0.0: return
	if phase == "retry":
		if stage == 0: normal_started = false
		phase = "listening"
		live_rms = 0.0
		return
	if values.size() == 3:
		phase = "done"
	else:
		stage += 1
		samples.clear()
		live_rms = 0.0
		phase = "listening"

func accept_profile(microphone: String) -> bool:
	if phase != "done" or not valid_levels(values): return false
	levels.assign(values)
	device = microphone.left(60)
	return true

func profile_data() -> Dictionary:
	return {"version":1, "levels":levels.duplicate(), "device":device}

func load_profile(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not valid_levels(data.get("levels")): return false
	if typeof(data.get("device")) != TYPE_STRING: return false
	levels.assign(data.levels)
	device = str(data.device).left(60)
	return true

func strength_for(rms: Variant, fallback: float, microphone: String) -> float:
	if not valid_levels(levels) or not valid_signal(rms) or microphone != device: return fallback
	var signal_level := float(rms)
	if signal_level <= levels[0]: return 0.2 * signal_level / levels[0]
	if signal_level <= levels[1]: return lerpf(0.2, 0.5, inverse_lerp(levels[0], levels[1], signal_level))
	if signal_level <= levels[2]: return lerpf(0.5, 0.9, inverse_lerp(levels[1], levels[2], signal_level))
	return minf(1.0, 0.9 + 0.1 * (signal_level - levels[2]) / levels[2])
