extends SceneTree
const Calibration = preload("res://scripts/input/voice_calibration.gd")
const Strength = preload("res://scripts/input/voice_strength.gd")
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func sample(cal, raw: float) -> void:
	for index in range(5): cal.receive(raw, raw)

func run() -> void:
	var cal = Calibration.new()
	cal.begin()
	for index in range(20): cal.receive(0.0, 0.0)
	check(cal.stage == 0 and cal.samples.is_empty(), "Stille speichert keine Lautstärke.")
	sample(cal, 4000.0)
	check(cal.phase == "transition" and cal.values.size() == 1, "Der ungekürzte normale Pegel zählt als erste Stufe.")
	cal.receive(20000, 20000)
	check(cal.values.size() == 1, "Die kurze Pause nimmt keinen weiteren Pegel an.")
	cal.step(1.0)
	sample(cal, 4100.0)
	check(cal.stage == 1 and cal.phase == "listening" and not cal.error.is_empty(), "Fast gleiche Pegel führen zu einer neuen Aufforderung.")
	sample(cal, 8000.0)
	cal.step(1.0)
	sample(cal, 16000.0)
	cal.step(1.0)
	check(cal.phase == "done", "Drei unterscheidbare Stufen schließen die Kalibrierung ab.")
	check(cal.accept_profile("Test microphone"), "Die vollständige Kalibrierung speichert das persönliche Profil.")
	for pair in [[4000.0, 1], [8000.0, 2], [16000.0, 3]]:
		check(Strength.bars(cal.strength_for(pair[0], 0.5, "Test microphone")) == pair[1], "Die drei persönlichen Pegel ergeben unterschiedliche Steuerstufen.")
	check(cal.strength_for(0.0, 0.5, "Test microphone") == 0.0, "Stille bleibt nach der Kalibrierung bei null.")
	check(cal.strength_for(16000.0, 0.2, "Other microphone") == 0.2, "Ein anderes Mikrofon verwendet kein fremdes Profil.")
	var restored = Calibration.new()
	check(restored.load_profile(cal.profile_data()), "Die gespeicherten Daten lassen sich wieder laden.")
	check(Strength.bars(restored.strength_for(8000, 0.2, "Test microphone")) == 2, "Das geladene Profil behält die persönliche normale Steuerstufe.")
	var before: Dictionary = cal.profile_data()
	cal.begin()
	sample(cal, 1000.0)
	check(cal.profile_data() == before, "Eine abgebrochene Kalibrierung verändert das bisherige Profil nicht.")
	for invalid in [[0, 0, 0], [1000, 900, 4000], [1000, NAN, 4000], [1000, 1100, 1200], [1000, 2000], [1000, 2000, 40000]]:
		check(not restored.load_profile({"version":1,"levels":invalid,"device":"Test microphone"}), "Ungültige gespeicherte Pegel verändern das Profil nicht.")
	print("LAUTSTÄRKE-KALIBRIERUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
