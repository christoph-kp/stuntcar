extends SceneTree

const MeshTools = preload("res://tools/assets/mesh_tools.gd")
const Vehicles = preload("res://tools/assets/vehicles.gd")
const Tracks = preload("res://tools/assets/tracks.gd")
const Landscapes = preload("res://tools/assets/landscapes.gd")
const Showcase = preload("res://tools/assets/showcase.gd")
var geo = MeshTools.new()
var catalog: Array = []

func _initialize() -> void:
	call_deferred("run")

func record(node: Node3D, category: String, id: String, title: String) -> void:
	var path := category + "/" + id + ".tscn"
	node.name = id
	geo.save_scene(node,path)
	catalog.append({"id":id,"title":title,"category":category,"path":path})
	node.free()

func run() -> void:
	for folder in ["materials","vehicle","track","alpine","forest","canyon","coast","shared","weather","examples","previews"]:
		DirAccess.make_dir_recursive_absolute(MeshTools.OUT + folder)
	for spec in [
		["paint_orange","ed6528",0.27,0.35,0.0], ["ivory","f4e4bf",0.4,0.1,0.0],
		["glass","173d4b",0.12,0.55,0.0], ["rubber","18212a",0.93,0.0,0.0],
		["metal","52616b",0.32,0.8,0.0], ["dark_metal","253845",0.65,0.5,0.0],
		["headlight","d0f3ff",0.22,0.1,2.0], ["taillight","ff3420",0.3,0.1,2.0],
		["amber","ffb23d",0.4,0.0,0.7], ["asphalt","354650",0.92,0.0,0.0],
		["wet_asphalt","253b49",0.24,0.15,0.0], ["concrete","94a4a8",0.9,0.0,0.0],
		["snow","e7f2f2",0.88,0.0,0.0], ["snow_shadow","b2ced9",0.96,0.0,0.0],
		["rock","607c89",0.95,0.0,0.0], ["rock_light","8ba3a9",0.9,0.0,0.0],
		["pine","254f49",0.93,0.0,0.0], ["pine_light","477565",0.95,0.0,0.0],
		["bark","614d3c",0.96,0.0,0.0], ["moss","78895a",0.97,0.0,0.0],
		["sandstone","b66a45",0.95,0.0,0.0], ["sandstone_light","df9970",0.98,0.0,0.0],
		["sand","b79369",1.0,0.0,0.0], ["basalt","3b5363",0.9,0.0,0.0],
		["sea","3f7e91",0.24,0.25,0.0], ["foam","b9d8da",0.9,0.0,0.0],
		["grass","607e64",1.0,0.0,0.0], ["display","192f3b",0.8,0.0,0.0]
	]: geo.material(spec[0],spec[1],spec[2],spec[3],spec[4])
	Vehicles.new().build(self,geo)
	Tracks.new().build(self,geo)
	Landscapes.new().build(self,geo)
	weather()
	var file := FileAccess.open(MeshTools.OUT+"catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"units":"meters","forward":"-Z","road_width":6.0,"assets":catalog},"\t"))
	file.close()
	Showcase.new().build(self,geo)
	print("Paket erstellt: %d Bauteile." % catalog.size())
	quit()

func weather() -> void:
	for snowy in [true,false]:
		var node := Node3D.new()
		var particles := CPUParticles3D.new()
		particles.name = "Snowflakes" if snowy else "Raindrops"
		particles.amount = 360 if snowy else 600
		particles.lifetime = 7 if snowy else 1.2
		particles.preprocess = particles.lifetime
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		particles.emission_box_extents = Vector3(12,5,16)
		particles.direction = Vector3(0.12,-1,0.05)
		particles.spread = 12 if snowy else 2
		particles.initial_velocity_min = 1.0 if snowy else 16.0
		particles.initial_velocity_max = 1.8 if snowy else 20.0
		particles.gravity = Vector3(0.1,-0.3,0) if snowy else Vector3(0,-3,0)
		particles.local_coords = false
		particles.use_fixed_seed = true
		particles.seed = 120
		particles.visibility_aabb = AABB(Vector3(-20,-30,-25),Vector3(40,45,50))
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.055,0.055) if snowy else Vector2(0.012,0.6)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color("d8e8ed") if snowy else Color(0.65,0.78,0.86,0.35)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		if not snowy: mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material = mat
		if snowy:
			var flake := SphereMesh.new()
			flake.radius = 0.035
			flake.height = 0.07
			flake.radial_segments = 8
			flake.rings = 4
			flake.material = mat
			particles.mesh = flake
		else:
			particles.mesh = mesh
		node.add_child(particles)
		record(node,"weather","snow" if snowy else "rain","Schneefall" if snowy else "Regen")
