extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func run() -> void:
	var assets = load("res://scripts/forest_assets.gd")
	for species in ["pine_tree_01", "fir_tree_01"]:
		for variant in range(3):
			for detail in ["near", "far"]:
				var mesh: Mesh = assets.tree_mesh(species, variant, detail)
				var textured := 0
				for surface in range(mesh.get_surface_count()):
					var material = mesh.surface_get_material(surface)
					if material is StandardMaterial3D and material.albedo_texture != null:
						textured += 1
						var arrays = mesh.surface_get_arrays(surface)
						check(arrays[Mesh.ARRAY_TEX_UV] != null and arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Die Baumbilder brauchen eine vollständige Zuordnung: %s/%s/%s" % [species, variant, detail])
				check(textured >= 2, "Jeder Baum braucht Bilder für den Stamm und die Nadeln.")
	var track = load("res://scripts/track/track_data.gd").new()
	var landscape = load("res://scripts/track/landscape.gd").new()
	root.add_child(landscape)
	landscape.build(track)
	var terrain: MeshInstance3D = landscape.get_node_or_null("ForestTerrain")
	check(terrain != null, "Der Wald braucht zusammenhängendes Gelände.")
	if terrain != null:
		var arrays: Array = terrain.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		check(terrain.get_aabb().size.y > 8.0, "Das Gelände enthält Hänge und Täler.")
		var blocked := false
		var missing := false
		# Check the actual rendered triangles, not the terrain height helper.
		for distance in range(0, int(track.length_m) + 1, 25):
			var frame: Dictionary = track.sample(distance)
			for side in [-3.5, 0.0, 3.5]:
				var start: Vector3 = frame.position + track.right(frame.heading) * side + Vector3.UP * 100
				var found := false
				for face in range(0, indices.size(), 3):
					var a := vertices[indices[face]]
					var b := vertices[indices[face + 1]]
					var c := vertices[indices[face + 2]]
					if start.x < minf(a.x, minf(b.x,c.x)) or start.x > maxf(a.x,maxf(b.x,c.x)): continue
					if start.z < minf(a.z,minf(b.z,c.z)) or start.z > maxf(a.z,maxf(b.z,c.z)): continue
					var hit = Geometry3D.ray_intersects_triangle(start, Vector3.DOWN, a,b,c)
					if hit != null:
						found = true
						if hit.y > frame.position.y - 3.0: blocked = true
				if not found: missing = true
		check(not missing, "Das Gelände reicht unter die gesamte Waldstrecke.")
		check(not blocked, "Das Gelände lässt auch unter geneigten Kurven Platz für einen Fall.")
	landscape.free()
	print("WALD: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
