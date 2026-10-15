extends RefCounted

const ROOT := "res://assets/forest/"
static var meshes := {}
static var tree_meshes := {}

static func prepare_materials(mesh: Mesh) -> void:
	for surface in range(mesh.get_surface_count()):
		var original = mesh.surface_get_material(surface)
		if not original is StandardMaterial3D: continue
		var mat: StandardMaterial3D = original.duplicate()
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mat.roughness = 0.92
		if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold = 0.38
			mat.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.normal_scale = 0.55
		mesh.surface_set_material(surface, mat)

static func variants(asset: String) -> Array:
	if not meshes.has(asset):
		var source = load(ROOT + asset + "/" + asset + ".gltf").instantiate()
		var found := []
		for item in source.find_children("*", "MeshInstance3D", true, false):
			# Select source LOD0 variants; Godot creates lower detail levels on import.
			if "_LOD" in item.name and not str(item.name).ends_with("_LOD0"): continue
			prepare_materials(item.mesh)
			found.append(item.mesh)
		meshes[asset] = found
		source.free()
	return meshes[asset]

static func tree_mesh(species: String, variant: int, detail: String) -> Mesh:
	var key := "%s_%s_%s" % [species, ["a", "b", "c"][posmod(variant,3)], detail]
	if not tree_meshes.has(key):
		var source = load(ROOT + "trees/" + key + ".glb").instantiate()
		var item = source.find_children("*", "MeshInstance3D", true, false)[0]
		var mesh: Mesh = item.mesh
		prepare_materials(mesh)
		if detail == "far":
			for surface in range(mesh.get_surface_count()):
				var material: StandardMaterial3D = mesh.surface_get_material(surface)
				material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				material.roughness_texture = null
				material.normal_enabled = false
				material.set_flag(BaseMaterial3D.FLAG_DONT_RECEIVE_SHADOWS, true)
		tree_meshes[key] = mesh
		source.free()
	return tree_meshes[key]

static func radius(mesh: Mesh) -> float:
	var aabb := mesh.get_aabb()
	return Vector2(aabb.size.x, aabb.size.z).length() * 0.5

static func centered(mesh: Mesh) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	var aabb := mesh.get_aabb()
	item.position = Vector3(-aabb.get_center().x, -aabb.position.y, -aabb.get_center().z)
	item.lod_bias = 0.7
	return item

static func create_tree(species: String, variant: int) -> Node3D:
	var node := Node3D.new()
	node.name = "ForestTree"
	node.set_meta("forest_asset", species)
	var near_mesh := tree_mesh(species, variant, "near")
	var far_mesh := tree_mesh(species, variant, "far")
	node.set_meta("source_radius", maxf(radius(near_mesh), radius(far_mesh)))
	var near := centered(near_mesh)
	# Use the two prepared tree meshes; automatic mesh LOD distorts thin branches.
	near.lod_bias = 1000.0
	near.visibility_range_end = 45.0
	near.visibility_range_end_margin = 5.0
	node.add_child(near)
	var far := centered(far_mesh)
	far.lod_bias = 1000.0
	# Keep both levels aligned even when decimation changes the bounds.
	far.position = near.position
	far.visibility_range_begin = 45.0
	far.visibility_range_begin_margin = 5.0
	far.visibility_range_end = 280.0
	far.visibility_range_end_margin = 20.0
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(far)
	return node

static func create_prop(asset: String, variant: int, distance: float) -> Node3D:
	var choices := variants(asset)
	var mesh: Mesh = choices[posmod(variant, choices.size())]
	var node := Node3D.new()
	node.name = "ForestProp"
	node.set_meta("forest_asset", asset)
	node.set_meta("source_radius", radius(mesh))
	var item := centered(mesh)
	item.visibility_range_end = distance
	item.visibility_range_end_margin = 12.0
	if asset != "rock_moss_set_01":
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(item)
	return node
