extends RefCounted

const Assets = preload("res://scripts/forest_assets.gd")
var landscape
var terrain
var rng := RandomNumberGenerator.new()

func build(parent, ground) -> void:
	landscape = parent
	terrain = ground
	rng.seed = 84613
	var data = landscape.data
	# Irregular groups beside the raised road leave each approaching turn visible.
	for distance in range(0, int(data.length_m), 9):
		var frame: Dictionary = data.sample(distance)
		for side in [-1.0, 1.0]:
			var across: Vector3 = data.right(frame.heading) * side
			for row in range(3):
				var pos: Vector3 = frame.position + across * rng.randf_range(14 + row * 17, 25 + row * 19)
				pos += data.forward(frame.heading) * rng.randf_range(-5, 5)
				place_tree(pos, rng.randf_range(0.85, 1.35), distance + row)
			if distance % 18 == 0:
				var pos: Vector3 = frame.position + across * rng.randf_range(12, 24)
				place_prop("rock_moss_set_01", pos, rng.randf_range(2.2, 5.0), distance, 250)
			for patch in range(5):
				var pos: Vector3 = frame.position + across * rng.randf_range(11, 42)
				pos += data.forward(frame.heading) * rng.randf_range(-6, 6)
				place_prop("fern_02" if patch % 2 == 0 else "grass_medium_01", pos,
					rng.randf_range(2.5, 4.5), distance + patch, 110)
	# A wider forest fills the hills and closes gaps behind the nearby trees.
	var bounds := AABB(data.points[0], Vector3.ZERO)
	for point in data.points: bounds = bounds.expand(point)
	for x in range(int(bounds.position.x)-150, int(bounds.end.x)+150, 11):
		for z in range(int(bounds.position.z)-150, int(bounds.end.z)+150, 11):
			var pos := Vector3(x + rng.randf_range(-5,5), 0, z + rng.randf_range(-5,5))
			var gap: float = terrain.road_distance(pos).x
			if gap < 48 or gap > 155 or rng.randf() < 0.1: continue
			place_tree(pos, rng.randf_range(0.85, 1.65), x + z)

func place_tree(pos: Vector3, size: float, variant: int) -> void:
	var species := "fir_tree_01" if rng.randf() < 0.62 else "pine_tree_01"
	place(Assets.create_tree(species, variant), pos, size)

func place_prop(asset: String, pos: Vector3, size: float, variant: int, distance: float) -> void:
	place(Assets.create_prop(asset, variant, distance), pos, size)

func place(node: Node3D, pos: Vector3, size: float) -> void:
	var radius: float = node.get_meta("source_radius") * size
	if not landscape.clear_of_road(pos, radius):
		node.free()
		return
	pos.y = terrain.height_at(pos.x, pos.z) - 0.18
	if node.get_meta("forest_asset") == "rock_moss_set_01":
		pos.y -= radius * 0.45
	node.position = pos
	node.scale = Vector3.ONE * size
	node.rotation.y = rng.randf_range(0, TAU)
	node.set_meta("clearance_radius", radius)
	landscape.scenery.add_child(node)
