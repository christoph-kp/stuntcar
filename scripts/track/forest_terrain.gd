extends RefCounted

const STEP := 6.0
var track
var samples: PackedVector3Array
var noise := FastNoiseLite.new()

func _init(route) -> void:
	track = route
	noise.seed = 731
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	for i in range(0, route.points.size(), 6):
		samples.append(route.points[i])
	samples.append(route.points[-1])

func road_distance(pos: Vector3) -> Vector2:
	var best := INF
	var height := 12.0
	for p in samples:
		var sq := (pos.x - p.x) * (pos.x - p.x) + (pos.z - p.z) * (pos.z - p.z)
		if sq < best:
			best = sq
			height = p.y
	return Vector2(sqrt(best), height)

func height_at(x: float, z: float) -> float:
	var nearest := road_distance(Vector3(x, 0, z))
	var hills := 22.0 + noise.get_noise_2d(x, z) * 28.0
	var rise := smoothstep(10.0, 48.0, nearest.x)
	var distant := smoothstep(80.0, 180.0, nearest.x) * 20.0
	# Keep the forest in the valley. Raised ramps must stand above the trees.
	return minf(nearest.y, 12.0) - 7.5 + rise * hills + distant

func create_mesh() -> MeshInstance3D:
	var bounds := AABB(track.points[0], Vector3.ZERO)
	for point in track.points: bounds = bounds.expand(point)
	var origin := Vector2(floor((bounds.position.x - 230.0) / STEP) * STEP,
		floor((bounds.position.z - 230.0) / STEP) * STEP)
	var columns := ceili((bounds.size.x + 460.0) / STEP) + 1
	var rows := ceili((bounds.size.z + 460.0) / STEP) + 1
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(rows):
		for x in range(columns):
			var px := origin.x + x * STEP
			var pz := origin.y + z * STEP
			vertices.append(Vector3(px, height_at(px, pz), pz))
			uvs.append(Vector2(px, pz) / 5.0)
	for z in range(rows - 1):
		for x in range(columns - 1):
			var a := z * columns + x
			indices.append_array(PackedInt32Array([a, a+1, a+columns, a+1, a+columns+1, a+columns]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var surface := SurfaceTool.new()
	surface.create_from_arrays(arrays)
	surface.generate_normals()
	surface.generate_tangents()
	var node := MeshInstance3D.new()
	node.name = "ForestTerrain"
	node.mesh = surface.commit()
	# The car can land on the forest floor before its automatic restart.
	node.create_trimesh_collision()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/forest/terrain.gdshader")
	mat.set_shader_parameter("earth", load("res://assets/forest/ground/color.jpg"))
	mat.set_shader_parameter("earth_normal", load("res://assets/forest/ground/normal.jpg"))
	mat.set_shader_parameter("moss", load("res://assets/quality/ground/color.jpg"))
	node.material_override = mat
	return node
