extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func key(scene: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_input(event)

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	check(scene.wheels.size() == 4,"Vier Räder fehlen")
	check(scene.camera.current,"Aktive Kamera fehlt")
	check(scene.car.find_children("*","MeshInstance3D",true,false).size() > 80,"Fahrzeugmodell fehlt")
	check(scene.find_children("Pine_*","MeshInstance3D",true,false).size() == 180,"Kiefern fehlen")
	for wheel in scene.wheels:
		check(wheel.get_child_count() == 1,"Radverbindung fehlt")
		check(wheel.global_position.y > 0.3 and wheel.global_position.y < 0.5,"Rad sitzt falsch")
	var start: Vector3 = scene.car.position
	for i in range(120): scene.step_drive(1.0/60.0,true,false,0.0)
	check(scene.speed > 9.0,"Auto beschleunigt nicht")
	check(scene.car.position.z < start.z-9.0,"Auto fährt nicht vorwärts")
	check(scene.mode == 1,"Fahrkamera startet nicht bei Gas")
	for i in range(120): scene.step_drive(1.0/60.0,false,true,0.0)
	check(is_zero_approx(scene.speed),"Bremse hält das Auto nicht an")
	key(scene,KEY_R)
	check(scene.car.position.is_equal_approx(start),"Rücksetzen setzt die Position nicht zurück")
	for i in range(240): scene.step_drive(1.0/60.0,true,false,1.0)
	check(scene.car.position.x > start.x,"Lenkung bewegt das Auto nicht")
	check(scene.car.position.x <= 2.75,"Auto verlässt die Teststrecke")
	check(absf(scene.wheel_spin) > 1,"Räder drehen sich nicht")
	scene.car.position.z = -104
	scene.step_drive(0.01,false,false,0)
	check(scene.car.position.z == 100,"Streckenende setzt das Auto nicht zurück")
	key(scene,KEY_1)
	check(scene.mode == 0,"Ansicht 1 fehlt")
	key(scene,KEY_2)
	check(scene.mode == 1,"Ansicht 2 fehlt")
	key(scene,KEY_L)
	check(scene.dusk,"Abendlicht fehlt")
	for child in scene.car.get_children():
		if child is SpotLight3D: check(child.visible,"Scheinwerfer bleibt aus")
	key(scene,KEY_L)
	check(not scene.dusk,"Tageslicht fehlt")
	key(scene,KEY_H)
	check(not scene.hud.visible,"Anzeige bleibt sichtbar")
	key(scene,KEY_R)
	check(is_zero_approx(scene.speed),"Geschwindigkeit bleibt nach Rücksetzen bestehen")
	for message in failures: printerr(message)
	print("Qualitätsprobe: %d Prüfungen, %d Fehler" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
