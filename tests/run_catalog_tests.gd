extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)
func _initialize() -> void:
	var definition = JSON.parse_string(FileAccess.get_file_as_string(Track.DEFAULT_PATH))
	definition.erase("preview")
	var bad: Dictionary = definition.duplicate(true)
	bad["scenario"] = "unbekannt"
	check(not Track.validate_definition(bad).is_empty(), "Eine unbekannte Landschaft braucht eine Fehlermeldung.")
	bad = definition.duplicate(true)
	bad["name"] = "   "
	check(not Track.validate_definition(bad).is_empty(), "Ein Name aus Leerzeichen ist ungültig.")
	var track = Track.new()
	check(track.has_method("scan_catalog"), "Die Dateiprüfung muss Fehler und gültige Strecken getrennt melden.")
	if track.has_method("scan_catalog"):
		var folder := "/tmp/stuntcar-catalog-%d" % OS.get_process_id()
		DirAccess.make_dir_recursive_absolute(folder)
		write_file(folder + "/01_test.json", JSON.stringify(definition))
		write_file(folder + "/02_fehler.json", "{\n  falsches JSON")
		var report: Dictionary = track.scan_catalog(folder)
		check(report.routes.size() == 1 and report.errors.size() == 1, "Eine defekte Datei darf die gültige Strecke nicht verbergen.")
		check("02_fehler.json" in report.errors[0] and "line 1" in report.errors[0], "Der Fehler nennt die Datei und die Zeile.")
		DirAccess.remove_absolute(folder + "/01_test.json")
		report = track.scan_catalog(folder)
		check(report.routes.is_empty(), "Eine entfernte Strecke verschwindet aus der Auswahl.")
		DirAccess.remove_absolute(folder + "/02_fehler.json")
		DirAccess.remove_absolute(folder)
	var missing = Track.new("/tmp/stuntcar-nicht-vorhanden-%d.json" % OS.get_process_id())
	check(not missing.valid and missing.points.size() > 1, "Eine fehlende Startdatei verhindert das Öffnen der Auswahl nicht.")
	print("KATALOG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
func write_file(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()
