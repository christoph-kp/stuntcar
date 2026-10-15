extends RefCounted

const OUT := "res://assets/stuntcar_kit/"

func item(parent: Node3D, path: String, pos: Vector3 = Vector3.ZERO, rot: float = 0.0) -> Node3D:
	var node: Node3D = load(OUT+path+".tscn").instantiate()
	node.scene_file_path = ""
	node.position = pos
	node.rotation.y = rot
	parent.add_child(node)
	return node

func environment(scene: Node3D, theme: String = "alpine") -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("38657d")
	sky_mat.sky_horizon_color = Color("d5e1dd")
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = Color("395363")
	if theme == "canyon":
		sky_mat.sky_top_color = Color("4d657d")
		sky_mat.sky_horizon_color = Color("edbb91")
	elif theme == "coast":
		sky_mat.sky_top_color = Color("203f55")
		sky_mat.sky_horizon_color = Color("7b97a6")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b8d0df")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	if theme in ["alpine","forest","coast"]:
		env.fog_enabled = true
		env.fog_light_color = Color("9caf9e") if theme == "forest" else Color("90b2c7")
		env.fog_density = 0.0025 if theme != "alpine" else 0.0012
	var world := WorldEnvironment.new()
	world.name = "Environment"
	world.environment = env
	scene.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-32,-32,0)
	sun.light_color = Color("ffe0b4") if theme == "canyon" else Color("fff4df")
	sun.light_energy = 0.80 if theme != "coast" else 0.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 240
	scene.add_child(sun)

func camera(scene: Node3D, pos: Vector3, target: Vector3, ortho: float = 0.0) -> void:
	var cam := Camera3D.new()
	cam.name = "PreviewCamera"
	cam.position = pos
	cam.basis = Basis.looking_at(target-pos)
	cam.fov = 52
	cam.near = 0.5
	cam.far = 1600
	if ortho > 0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho
	cam.current = true
	scene.add_child(cam)

func label(scene: Node3D, text: String, pos: Vector3, size: float = 0.025) -> void:
	var node := Label3D.new()
	node.text = text
	node.position = pos
	node.font_size = 48
	node.pixel_size = size
	node.modulate = Color("f1e3c9")
	node.outline_modulate = Color("16313e")
	node.outline_size = 6
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	scene.add_child(node)

func build(builder,g) -> void:
	var studio := Node3D.new()
	studio.name = "VehicleStudio"
	environment(studio)
	g.box(studio,"Floor",Vector3(200,0.1,200),Vector3(0,-0.13,0),"display")
	g.cylinder(studio,"Plinth",2.7,2.7,0.12,Vector3(0,-0.06,0),"dark_metal",64)
	item(studio,"vehicle/stunt_coupe")
	camera(studio,Vector3(3.6,2.2,-4.4),Vector3(0,0.65,0))
	g.save_scene(studio,"examples/vehicle_studio.tscn")
	studio.free()
	var yard := Node3D.new()
	yard.name = "TrackGallery"
	environment(yard,"canyon")
	g.box(yard,"Floor",Vector3(230,0.5,240),Vector3(35,-5,-55),"display")
	var tracks: Array = builder.catalog.filter(func(a): return a.category == "track")
	for i in range(tracks.size()):
		var entry: Dictionary = tracks[i]
		var pos := Vector3((i%3)*60-45,0,-floori(i/3.0)*70)
		var node := item(yard,entry.path.trim_suffix(".tscn"),pos)
		label(yard,entry.title,pos+Vector3(0,1,8),0.065)
		if entry.id in ["straight_24","loop_12","bank_right_90"]:
			item(yard,"vehicle/stunt_coupe",pos+Vector3(0,0.03,-1.8))
		if entry.id == "loop_12":
			# Visible braces stop the loop from appearing to float.
			for x in [-3.6,12.6]:
				g.box(yard,"LoopBrace",Vector3(0.45,19,0.65),pos+Vector3(x,5.0,0),"dark_metal")
		var end: Marker3D = node.get_node("Exit")
		g.marker(yard,"Connection",pos+end.position)
	camera(yard,Vector3(155,180,195),Vector3(25,0,-65),195)
	g.save_scene(yard,"examples/track_gallery.tscn")
	yard.free()
	var stunt := Node3D.new()
	stunt.name = "StuntPreview"
	environment(stunt,"canyon")
	g.box(stunt,"Ground",Vector3(250,1,220),Vector3(15,-8.5,-15),"display")
	var approach := item(stunt,"track/straight_24",Vector3(0,0,24))
	var loop := item(stunt,"track/loop_12")
	var exit_road := item(stunt,"track/straight_24")
	exit_road.transform = loop.get_node("Exit").transform
	var bank := item(stunt,"track/bank_right_90")
	bank.transform = exit_road.transform * exit_road.get_node("Exit").transform
	var ramp := item(stunt,"track/jump_launch")
	ramp.transform = bank.transform * bank.get_node("Exit").transform
	var landing := item(stunt,"track/jump_landing")
	landing.position = ramp.transform * Vector3(0,9*tan(deg_to_rad(18)),-30)
	landing.basis = ramp.basis
	for road in [approach,exit_road]:
		for distance in [5,17]: item(stunt,"shared/bridge_support_8",road.transform*Vector3(0,0,-distance))
	item(stunt,"vehicle/stunt_coupe",Vector3(0,0.02,8))
	item(stunt,"shared/checkpoint_gate",Vector3(0,0,21))
	for i in range(4): item(stunt,"canyon/mesa",Vector3(-65+i*48,-8,-120),i*0.4)
	camera(stunt,Vector3(100,65,85),Vector3(30,7,-22),105)
	g.save_scene(stunt,"examples/stunt_preview.tscn")
	stunt.free()
	for theme in ["alpine","forest","canyon","coast"]:
		var scene := landscape_example(g,theme)
		g.save_scene(scene,"examples/"+theme+"_preview.tscn")
		scene.free()

func landscape_example(g,theme: String) -> Node3D:
	var scene := Node3D.new()
	scene.name = theme.capitalize()+"Preview"
	environment(scene,theme)
	var ground_mat: String = {"alpine":"snow_shadow","forest":"grass","canyon":"sand","coast":"sea"}[theme]
	g.box(scene,"Ground",Vector3(420,2,420),Vector3(0,-9,0),ground_mat)
	var first := item(scene,"track/straight_24",Vector3(0,0,12))
	var curve := item(scene,"track/curve_right_45")
	curve.transform = first.transform * first.get_node("Exit").transform * curve.get_node("Entry").transform.affine_inverse()
	var next := item(scene,"track/straight_24")
	next.transform = curve.transform * curve.get_node("Exit").transform * next.get_node("Entry").transform.affine_inverse()
	var bank := item(scene,"track/bank_left_90")
	bank.transform = next.transform * next.get_node("Exit").transform * bank.get_node("Entry").transform.affine_inverse()
	if theme == "coast":
		for module in [first,curve,next,bank]: module.get_node("Road").material_override = g.materials.wet_asphalt
	for module in [first,curve,next,bank]:
		var points: PackedVector3Array = module.get_meta("centerline")
		var ups: PackedVector3Array = module.get_meta("up_vectors")
		for i in range(0,points.size()-1,18):
			var f := (points[i+1]-points[i]).normalized()
			var right := f.cross(ups[i]).normalized()
			for side in [-1.0,1.0]:
				var post := item(scene,"shared/road_post")
				post.transform = module.transform * Transform3D(Basis(right,ups[i],-f),points[i]+right*3.15*side)
		for i in range(10,points.size(),35):
			item(scene,"shared/bridge_support_8",module.transform*points[i])
	item(scene,"vehicle/stunt_coupe",Vector3(0,0.015,6.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 105
	for side in [-1,1]:
		for i in range(10):
			var pos := Vector3(side*(14+rng.randf_range(0,25)), -7, 10-i*12)
			# Keep the right-hand curve clear of trees and cliff meshes.
			if side == 1: pos.x += 38
			if theme in ["alpine","forest"]:
				item(scene,theme+("/snow_pine_tall" if theme == "alpine" else "/pine_tall"),pos,rng.randf_range(0,TAU))
			item(scene,theme+"/boulder_"+str(1+i%2),pos+Vector3(0,0,3),rng.randf_range(0,TAU))
		for i in range(3):
			item(scene,theme+"/cliff_18",Vector3(side*(30 if side < 0 else 78),-8,-25-i*32),0.5)
	if theme == "alpine":
		for i in range(5):
			var mountain := item(scene,"alpine/mountain_group",Vector3(-110+i*65,-9,-185),0.3*i)
			mountain.scale = Vector3.ONE*1.45
		for z in [0,-10,-20]: item(scene,"alpine/snowbank",Vector3(-6,-0.1,z),PI/2)
	elif theme == "forest":
		for i in range(24): item(scene,"forest/pine_tall",Vector3(-110+i*8,-8,-140-rng.randf_range(0,25)))
	elif theme == "canyon":
		for i in range(5): item(scene,"canyon/mesa",Vector3(-90+i*48,-8,-130-rng.randf_range(0,25)),i)
		item(scene,"canyon/rock_tower",Vector3(-14,-8,-15))
	elif theme == "coast":
		item(scene,"coast/lighthouse",Vector3(66,6,-76))
		var island := item(scene,"coast/boulder_2",Vector3(66,-8,-76))
		island.scale = Vector3(4,4,4)
		for i in range(6): item(scene,"coast/foam_strip",Vector3(-16+i*13,-7.95,-24-i*9),i)
	if theme in ["alpine","coast"]:
		item(scene,"weather/"+("snow" if theme == "alpine" else "rain"),Vector3(0,7,5))
	camera(scene,Vector3(0,3.5,14),Vector3(4,1,-18))
	return scene
