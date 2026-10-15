extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	var track = load("res://scripts/track/track_data.gd").new()
	var terrain = load("res://scripts/track/forest_terrain.gd").new(track)
	check(track.valid, "Die Stuntstrecke ist gültig.")
	check(track.jumps.size() >= 2, "Die Waldstrecke braucht zwei große Sprünge.")
	for curve in track.curves:
		check(curve.bank_degrees >= 35, "Die Waldkurven brauchen eine deutliche Neigung.")
	for jump in track.jumps:
		check((jump.end_m - jump.start_m) / 22.0 >= 2.0, "Der Flug dauert beim normalen Tempo mindestens zwei Sekunden.")
		var mid: float = (jump.start_m + jump.end_m) * 0.5
		var frame: Dictionary = track.sample(mid)
		check(track.flight_height(mid) > 50, "Der Sprung führt deutlich über die Baumkronen.")
		check(track.flight_height(mid) - terrain.height_at(frame.position.x, frame.position.z) > 35,
			"Der Waldboden steigt unter dem Sprung nicht mit an.")
		check(track.pitch_at(jump.start_m - 1) > deg_to_rad(20), "Die Rampe zeigt am Absprung sichtbar nach oben.")
		check(track.pitch_at(jump.end_m + 1) < deg_to_rad(-15), "Die Landefläche fällt in Flugrichtung ab.")
		var drive = load("res://scripts/vehicle/drive_model.gd").new(track)
		drive.reset(jump.end_m + 0.1)
		var next: Dictionary = track.next_curve(drive.distance_m)
		drive.request_turn(next.turn_sign)
		check(drive.active_curve_id == next.id, "Eine Eingabe zum Kurvenhinweis nach der Landung zählt für die nächste Kurve.")
	for speed in [22.0, 28.0]:
		for hint in [5.0, 8.0]:
			var drive = load("res://scripts/vehicle/drive_model.gd").new(track)
			drive.speed_mps = speed
			drive.target_speed_mps = speed
			drive.hint_seconds = hint
			var sent := {}
			for frame in range(5000):
				var next: Dictionary = track.next_curve(drive.distance_m)
				if not next.is_empty() and not sent.has(next.id) and drive.distance_m >= next.start_m - drive.input_window_m():
					drive.request_turn(next.turn_sign)
					sent[next.id] = true
				drive.step(1.0/60.0)
				if drive.off_road or drive.finished: break
			check(drive.finished, "Sofortige Eingaben zum Hinweis führen bis ins Ziel: %d m/s, %d s Vorlauf." % [speed, hint])
	print("STUNTSTRECKE: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
