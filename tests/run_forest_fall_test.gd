extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-forest-fall-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.session.sound_enabled = false
	await physics_frame
	scene.session.restart()
	var mesh: Mesh = scene.builder.landscape.get_node("ForestTerrain").mesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var fell := false
	var penetrated := false
	for frame in range(1500):
		await physics_frame
		if scene.session.state == "FALLING":
			fell = true
			var pos: Vector3 = scene.car.global_position
			for face in range(0, indices.size(), 3):
				var a := vertices[indices[face]]
				var b := vertices[indices[face+1]]
				var c := vertices[indices[face+2]]
				if pos.x < minf(a.x,minf(b.x,c.x)) or pos.x > maxf(a.x,maxf(b.x,c.x)): continue
				if pos.z < minf(a.z,minf(b.z,c.z)) or pos.z > maxf(a.z,maxf(b.z,c.z)): continue
				var hit = Geometry3D.ray_intersects_triangle(pos + Vector3.UP*100, Vector3.DOWN, a,b,c)
				if hit != null and pos.y < hit.y - 0.1: penetrated = true
		if fell and scene.session.state == "RUNNING": break
	var ok: bool = fell and scene.session.state == "RUNNING" and not penetrated
	print("WALDFALL: Fall=%s, Neustart=%s, Boden durchquert=%s" % [fell, scene.session.state == "RUNNING", penetrated])
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit(0 if ok else 1)
