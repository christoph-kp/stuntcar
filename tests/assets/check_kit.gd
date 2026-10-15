extends SceneTree

var failures: Array[String] = []
var checked := 0

func check(value: bool, message: String) -> void:
	checked += 1
	if not value: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var manifest_path := "res://assets/stuntcar_kit/catalog.json"
	check(FileAccess.file_exists(manifest_path), "Das Dateiverzeichnis fehlt.")
	if not failures.is_empty():
		finish()
		return
	var catalog = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	for item in catalog.assets:
		var packed = load("res://assets/stuntcar_kit/" + item.path)
		check(packed is PackedScene, "Szene fehlt: " + item.path)
		if not packed is PackedScene: continue
		var scene = packed.instantiate()
		root.add_child(scene)
		var meshes = scene.find_children("*", "MeshInstance3D", true, false)
		if item.category == "weather":
			var emitters = scene.find_children("*", "CPUParticles3D", true, false)
			check(emitters.size() == 1 and emitters[0].mesh != null, "Wetter fehlt: " + item.path)
		else:
			check(not meshes.is_empty(), "Keine Geometrie: " + item.path)
		for mesh in meshes:
			check(mesh.mesh != null and mesh.mesh.get_aabb().size.length() > 0.01, "Leere Geometrie: " + item.path)
			for surface in range(mesh.mesh.get_surface_count()):
				var material = mesh.get_active_material(surface)
				check(material != null, "Material fehlt: " + item.path)
				if material != null:
					check(material.resource_path.begins_with("res://assets/stuntcar_kit/materials/"), "Material ist nicht mit der gemeinsamen Datei verbunden: " + item.path)
		if item.category == "track":
			var entry = scene.get_node_or_null("Entry")
			var end = scene.get_node_or_null("Exit")
			check(entry != null and end != null, "Anschluss fehlt: " + item.path)
			check(entry.position.length() < 0.001, "Anfang liegt nicht am Ursprung: " + item.path)
			check(entry.basis.x.dot(Vector3.RIGHT) > 0.999, "Falsche Anfangsrichtung: " + item.path)
			check(scene.get_node_or_null("RoadCollision/Shape") != null, "Fahrbahnkollision fehlt: " + item.path)
			var points: PackedVector3Array = scene.get_meta("centerline")
			var ups: PackedVector3Array = scene.get_meta("up_vectors")
			check(points[0].distance_to(entry.position) < 0.001 and points[-1].distance_to(end.position) < 0.001, "Anschluss passt nicht zur Fahrbahn: " + item.path)
			var next = load("res://assets/stuntcar_kit/track/straight_24.tscn").instantiate()
			root.add_child(next)
			next.transform = scene.transform * end.transform * next.get_node("Entry").transform.affine_inverse()
			check(next.get_node("Entry").global_transform.is_equal_approx(end.global_transform), "Anschlüsse passen nicht zusammen: " + item.path)
			for side in [-3.0,3.0]:
				var current_edge: Vector3 = end.global_transform * Vector3(side,0,0)
				var next_edge: Vector3 = next.get_node("Entry").global_transform * Vector3(side,0,0)
				check(current_edge.distance_to(next_edge) < 0.001, "Fahrbahnkante hat einen Versatz: " + item.path)
			next.free()
			for i in range(1, points.size()):
				check(points[i].distance_to(points[i-1]) < 1.05, "Zu großer Abstand in der Fahrbahn: " + item.path)
				check(absf(ups[i].length() - 1.0) < 0.001, "Ungültige Oberseite: " + item.path)
			if "loop" in item.path:
				var top := 0
				for i in range(points.size()):
					if points[i].y > points[top].y: top = i
				check(ups[top].dot(Vector3.DOWN) > 0.99, "Looping-Oberseite zeigt nicht nach innen.")
				check(absf(end.position.x) > 6.5, "Looping hat keine seitliche Ausfahrt.")
				await physics_frame
				var query := PhysicsRayQueryParameters3D.create(points[top] + ups[top] * 2.0, points[top] - ups[top] * 1.0)
				var hit = root.get_world_3d().direct_space_state.intersect_ray(query)
				check(not hit.is_empty(), "Looping-Kollision von innen fehlt.")
				if not hit.is_empty(): check(hit.normal.dot(ups[top]) > 0.99, "Looping-Kollision zeigt zur falschen Seite.")
			if "bank" in item.path:
				check(ups[0].dot(Vector3.UP) > 0.999 and ups[-1].dot(Vector3.UP) > 0.999, "Steilkurve endet nicht eben.")
				var middle := points.size()/2
				var tangent := (points[middle+1]-points[middle-1]).normalized()
				var inward := tangent.cross(Vector3.UP).normalized() * (-1.0 if "left" in item.path else 1.0)
				check(ups[middle].dot(inward) > 0.69, "Steilkurve neigt sich nach außen.")
		if item.category == "vehicle":
			for wheel in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
				check(scene.get_node_or_null(wheel) != null, "Rad fehlt: " + wheel)
			check(scene.get_node_or_null("HeadlightLeft") != null, "Scheinwerfer fehlt.")
		if item.id == "bridge_support_8":
			for mesh in meshes:
				var bounds: AABB = mesh.transform * mesh.mesh.get_aabb()
				check(bounds.end.y < -0.38, "Die Brückenstütze reicht in die Fahrbahndecke.")
		scene.free()
	finish()

func finish() -> void:
	for message in failures: printerr(message)
	print("Asset-Prüfung: %d Prüfungen, %d Fehler." % [checked, failures.size()])
	quit(0 if failures.is_empty() else 1)
