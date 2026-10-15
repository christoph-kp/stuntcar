extends RefCounted

const NORMAL := 0.5
const MIN_SIGNAL := 0.06

static func normalize(value: Variant) -> float:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
		return NORMAL
	return clampf(float(value), 0.0, 1.0)

static func bars(value: float) -> int:
	var level := normalize(value)
	if level < MIN_SIGNAL: return 0
	if level < 0.34: return 1
	return 2 if level < 0.67 else 3

static func multiplier(value: float) -> float:
	match bars(maxf(MIN_SIGNAL, normalize(value))):
		1: return 0.4
		3: return 1.6
	return 1.0
