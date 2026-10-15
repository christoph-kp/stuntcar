extends SceneTree

const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model = Drive.new(Track.new())
	var session = Router.new(model)
	session.open_settings()
	session.activate(5)
	check(session.state == "PRACTICE", "Die Einstellungen öffnen die Sprachübung.")
	if session.state != "PRACTICE":
		finish()
		return
	var practice = session.practice
	check(practice.phase == "ready" and practice.expected_word() == "left", "Die Übung beginnt mit einer klaren Vorgabe.")
	practice.start("direct")
	check(practice.receive("left") and practice.correct == 1 and practice.attempted == 1, "Ein einzelnes Wort reicht für einen richtigen Versuch.")
	practice.receive("left")
	practice.receive("left")
	check(practice.correct == 3 and practice.phase == "transition", "Drei schnelle Wiederholungen zählen einzeln.")
	check(not practice.receive("left") and practice.attempted == 3, "Ein altes Wort zählt während des Wortwechsels nicht.")
	practice.step(1.0, true)
	check(practice.expected_word() == "right" and practice.phase == "listening", "Nach drei Versuchen folgt das nächste Wort.")
	practice.receive("left")
	check(practice.wrong == 1 and practice.correct == 3 and practice.attempted == 4, "Ein falscher Befehl senkt die Trefferquote.")
	practice.unrecognized("hello")
	check(practice.missed == 1 and practice.attempted == 5, "Eine fremde Äußerung zählt als nicht erkannt.")
	practice.step(5.0, true)
	check(practice.missed == 2 and practice.attempted == 6, "Ein fehlendes Wort zählt nach Ablauf der Frist.")
	practice.step(1.0, true)
	check(practice.expected_word() == "faster", "Die Übung fragt Beschleunigen nach dem Lenken ab.")
	for i in range(3): practice.receive("faster")
	practice.step(1.0, true)
	for i in range(3): practice.receive("slower")
	check(practice.phase == "done" and practice.attempted == 12 and practice.correct == 9, "Die Runde endet nach zwölf Vorgaben mit einer ehrlichen Quote.")
	check(not practice.receive("left") and practice.correct == 9, "Weitere Wörter verändern ein fertiges Ergebnis nicht.")
	practice.prepare("checked")
	practice.start("checked")
	practice.receive("right")
	check(practice.results.direct.correct == 9 and practice.results.checked.correct == 0 and practice.results.checked.attempted == 1, "Die beiden Modi behalten getrennte Ergebnisse.")
	practice.prepare("direct")
	practice.wait_for_microphone("direct")
	practice.step(20.0, false)
	check(practice.phase == "waiting" and practice.attempted == 0, "Die Ladezeit des Mikrofons zählt nicht als Fehler.")
	var position: Vector3 = model.position
	var speed: float = model.target_speed_mps
	check(not session.submit_voice("left") and not session.submit_voice("faster"), "Die Übung sendet keine Fahrbefehle an die Strecke.")
	check(model.position == position and model.target_speed_mps == speed, "Das Streckenauto bleibt während der Übung unverändert.")
	session.close_practice()
	check(session.state == "SETTINGS" and session.menu_index == 5, "Zurück führt zum Eintrag der Sprachübung.")
	finish()

func finish() -> void:
	print("SPRACHÜBUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
