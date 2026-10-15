extends RefCounted

const OUT := "res://assets/stuntcar_kit/"
var materials: Dictionary = {}

func material(id: String, hex: String, roughness: float = 0.7, metal: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = id
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	mat.metallic = metal
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = Color(hex)
		mat.emission_energy_multiplier = emission
	ResourceSaver.save(mat, OUT + "materials/" + id + ".tres")
	mat.take_over_path(OUT + "materials/" + id + ".tres")
	materials[id] = mat
	return mat

func part(parent: Node3D, id: String, mesh: Mesh, pos: Vector3, mat: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = materials[mat]
	parent.add_child(instance)
	return instance

func box(parent: Node3D, id: String, size: Vector3, pos: Vector3, mat: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return part(parent, id, mesh, pos, mat)

func cylinder(parent: Node3D, id: String, bottom: float, top: float, height: float, pos: Vector3, mat: String, segments: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return part(parent, id, mesh, pos, mat)

func sphere(parent: Node3D, id: String, radius: float, pos: Vector3, scale_value: Vector3, mat: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 5
	var node := part(parent, id, mesh, pos, mat)
	node.scale = scale_value
	return node

func quad(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, up: Vector3 = Vector3.UP) -> void:
	# Godot uses clockwise front faces; normals explicitly point outwards.
	var points := [a, b, c, a, c, d]
	if (b-a).cross(c-a).dot(up) > 0: points = [a, c, b, a, d, c]
	for v: Vector3 in points:
		s.set_normal(up.normalized())
		s.set_uv(Vector2(v.x, v.z) * 0.25)
		s.add_vertex(v)

func surface() -> SurfaceTool:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	return s

func loft(parent: Node3D, id: String, sections: Array, mat: String) -> MeshInstance3D:
	# Each section: longitudinal Z, half width, bottom Y, top Y, bevel.
	var rings: Array = []
	for row in sections:
		var z: float = row[0]
		var w: float = row[1]
		var bottom: float = row[2]
		var top: float = row[3]
		var bevel: float = minf(row[4], (top-bottom) * 0.45)
		rings.append([Vector3(-w+bevel,top,z),Vector3(w-bevel,top,z),Vector3(w,top-bevel,z),Vector3(w,bottom+bevel,z),Vector3(w-bevel,bottom,z),Vector3(-w+bevel,bottom,z),Vector3(-w,bottom+bevel,z),Vector3(-w,top-bevel,z)])
	var s := surface()
	for j in range(rings.size()-1):
		for k in range(8):
			var a: Vector3 = rings[j][k]
			var b: Vector3 = rings[j][(k+1)%8]
			var c: Vector3 = rings[j+1][(k+1)%8]
			var d: Vector3 = rings[j+1][k]
			quad(s,a,b,c,d,(d-a).cross(b-a).normalized())
	for end in [0, rings.size()-1]:
		var ring: Array = rings[end]
		var center := Vector3(0,(sections[end][2]+sections[end][3])*0.5,sections[end][0])
		var normal := Vector3.FORWARD if end == 0 else Vector3.BACK
		for k in range(8):
			var a: Vector3 = ring[k]
			var b: Vector3 = ring[(k+1)%8]
			var verts := [center,a,b] if (a-center).cross(b-center).dot(normal) < 0 else [center,b,a]
			for v in verts:
				s.set_normal(normal)
				s.set_uv(Vector2(v.x,v.y))
				s.add_vertex(v)
	return part(parent,id,s.commit(),Vector3.ZERO,mat)

func own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		own(child,root)

func rock(parent: Node3D, id: String, pos: Vector3, size: Vector3, mat: String, seed_value: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rows: Array = []
	var segments := 10
	var rings := 7
	for j in range(rings+1):
		var row: Array[Vector3] = []
		var latitude := PI*float(j)/rings
		for i in range(segments):
			var angle := TAU*i/segments
			var radius := rng.randf_range(0.83,1.13)
			if j == 0 or j == rings: radius = 1.0
			row.append(Vector3(sin(latitude)*cos(angle),cos(latitude),sin(latitude)*sin(angle))*size*radius)
		rows.append(row)
	var s := surface()
	for j in range(rings):
		for i in range(segments):
			var k := (i+1)%segments
			for tri in [[rows[j][i],rows[j+1][i],rows[j+1][k]],[rows[j][i],rows[j+1][k],rows[j][k]]]:
				var a: Vector3 = tri[0]
				var b: Vector3 = tri[1]
				var c: Vector3 = tri[2]
				var normal := (b-a).cross(c-a).normalized()
				if normal.length() < 0.5: continue
				if normal.dot((a+b+c)/3) < 0: normal = -normal
				var verts := [a,c,b] if (b-a).cross(c-a).dot(normal) > 0 else [a,b,c]
				for v in verts:
					s.set_normal(normal)
					s.set_uv(Vector2(v.x,v.z)*0.25)
					s.add_vertex(v)
	return part(parent,id,s.commit(),pos,mat)

func save_scene(node: Node3D, relative: String) -> void:
	own(node,node)
	var scene := PackedScene.new()
	assert(scene.pack(node) == OK)
	assert(ResourceSaver.save(scene,OUT+relative) == OK)

func marker(parent: Node3D, id: String, pos: Vector3, basis_value: Basis = Basis.IDENTITY) -> Marker3D:
	var m := Marker3D.new()
	m.name = id
	m.position = pos
	m.basis = basis_value
	parent.add_child(m)
	return m
