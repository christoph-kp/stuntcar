extends SceneTree

const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
const UI = preload("res://scripts/ui/game_ui.gd")
const Voice = preload("res://scripts/input/voice_bridge.gd")
var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func inspect_text(node: Node) -> void:
	if node is Label or node is Button or node is RichTextLabel or node is Label3D:
		var value: String = node.text
		check(not "I18N_" in value, "Kein Textschlüssel erscheint: " + value)
		var english := true
		for german in ["Deine", "Sprache", "Kurven", "Wähle", "Einstellungen", "Fahrt", "Sekunden", "Sprünge", "Nebelwald"]:
			if german in value: english = false
		check(english, "Kein deutscher Oberflächentext: " + value)
	for child in node.get_children(): inspect_text(child)

func run() -> void:
	check(OS.get_user_data_dir().replace("\\", "/").ends_with("/Godot/app_userdata/Stuntcar · Erste Fahrt"), "Der bisherige Speicherordner bleibt erhalten.")
	check(TranslationServer.get_locale().begins_with("en"), "Das Spiel startet auf Englisch.")
	check(tr("I18N_MENU_START") == "Start drive", "Godot lädt den englischen Textkatalog.")
	var track = Track.new()
	check(track.track_name == "First Drive", "Der Streckenname erscheint auf Englisch.")
	check(not "TRACK_" in track.description, "Die Streckenbeschreibung löst ihren Schlüssel auf.")
	check(Track.validate_definition({}) == "A track name or description is missing.", "Die Streckenprüfung liefert eine englische Meldung.")
	var custom_path := "/private/tmp/stuntcar-i18n-custom.json"
	var custom: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Track.DEFAULT_PATH))
	custom.name = "My custom route"
	custom.description = "A route from a player."
	FileAccess.open(custom_path, FileAccess.WRITE).store_string(JSON.stringify(custom))
	check(Track.new(custom_path).track_name == "My custom route", "Eigene Streckennamen bleiben lesbar.")
	DirAccess.remove_absolute(custom_path)
	var model = Drive.new(track)
	var session = Router.new(model)
	var ui = UI.new()
	root.add_child(ui)
	session.open_tracks()
	for state in ["TRACKS", "MENU", "CONTROL", "SETTINGS", "AUDIO", "PAUSED", "FINISHED", "RUNNING", "FALLING"]:
		session.state = state
		session.menu_index = 0
		ui.render(session)
		await process_frame
		inspect_text(ui)
	session.state = "SETTINGS"
	check(session.entries()[0] == "Hint: 5 seconds", "Die Übersetzung setzt die Zahl richtig ein.")
	session.state = "AUDIO"
	check(session.entries()[0] == "Engine: 75 %", "Die Übersetzung zeigt ein Prozentzeichen.")
	model.change_speed(1)
	check(model.speed_feedback == "Faster: target 97 km/h", "Die Tempoanzeige verwendet einen vollständigen übersetzten Satz.")
	var voice = Voice.new()
	check(voice.status_text == "Voice off", "Die Sprachsteuerung startet mit englischem Text.")
	voice.enabled = true
	voice.authenticated = true
	voice.accept_packet({"type": "error", "seq": 1, "message": "I18N_VOICE_MODEL_MISSING"})
	check(voice.status_text == "The speech model is missing. Run the voice setup.", "Die Oberfläche übersetzt Fehler des Sprachprogramms.")
	voice.enabled = true
	voice.authenticated = true
	voice.accept_packet({"type": "error", "seq": 2, "message": "unbekannter interner Fehler"})
	check(voice.status_text == "The microphone is not available. Check its permission and input device.", "Unbekannte interne Fehler ergeben eine verständliche englische Meldung.")
	voice.free()
	ui.queue_free()
	await process_frame
	print("ÜBERSETZUNGEN: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
