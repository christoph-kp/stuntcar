extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
func _initialize() -> void:
	var folder := "res://tracks"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): folder = args[0]
	if not DirAccess.dir_exists_absolute(folder):
		printerr("Der Streckenordner fehlt: " + folder)
		quit(1)
		return
	var report := Track.scan_catalog(folder)
	for route in report.routes:
		print("OK: %s · %s · %d m" % [route.path.get_file(), route.name, route.length_m])
	for problem in report.errors: printerr(problem)
	if report.routes.is_empty(): printerr("Keine gültige Strecke gefunden.")
	print("%d gültige Strecken. %d Hinweise. Diese Prüfung ersetzt keine Probefahrt." % [report.routes.size(), report.errors.size()])
	quit(0 if not report.routes.is_empty() and report.errors.is_empty() else 1)
