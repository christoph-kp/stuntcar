extends Node3D

# A visual test only. The existing game's vehicle and track logic stay separate.
var car: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var world: WorldEnvironment
var hud: CanvasLayer
var speed_label: Label
var mode_label: Label
var speed := 0.0
var steering := 0.0
var mode := 0
var dusk := false
var orbit_angle := 0.0
var wheels: Array[Node3D] = []
var wheel_rest: Array[Basis] = []
var wheel_spin := 0.0
var dragging := false
var camera_distance := 7.4
var fps_samples: Array[float] = []

func _ready() -> void:
	build_environment()
	build_road()
	build_trees()
	build_car()
	build_camera()
	build_hud()
	set_camera(0)

func surface(folder: String, repeats: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/" + folder + "/color.jpg")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/" + folder + "/normal.jpg")
	m.normal_scale = 0.65
	m.roughness_texture = load("res://assets/" + folder + "/arm.jpg")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.ao_enabled = true
	m.ao_texture = m.roughness_texture
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.uv1_scale = repeats
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func simple_material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func box(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	add_child(instance)
	return instance

func build_environment() -> void:
	world = WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/sky/environment.hdr")
	sky.sky_material = panorama
	sky.radiance_size = Sky.RADIANCE_SIZE_512
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.sky_rotation = Vector3(0, 0.8, 0)
	env.background_energy_multiplier = 0.65
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.8
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.ssil_intensity = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.fog_enabled = true
	env.fog_light_color = Color("a8b5b8")
	env.fog_density = 0.0018
	env.fog_sky_affect = 0.12
	world.environment = env
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-28, -38, 0)
	sun.light_color = Color("fff0d7")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.light_angular_distance = 1.0
	add_child(sun)
	var probe := ReflectionProbe.new()
	probe.name = "LocalReflections"
	probe.position = Vector3(0, 2, 0)
	probe.size = Vector3(55, 24, 110)
	probe.max_distance = 140
	probe.box_projection = false
	probe.cull_mask = 1
	add_child(probe)

func ground_height(x: float, z: float) -> float:
	var edge := smoothstep(5.0, 20.0, absf(x))
	return -0.06 + edge * (0.6 + sin(x * 0.13 + z * 0.045) * 0.5 + cos(z * 0.08) * 0.4)

func build_road() -> void:
	var road_mat := surface("road", Vector3(4.0, 120.0, 1.0))
	var road := MeshInstance3D.new()
	road.name = "Asphalt"
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 240)
	road.mesh = plane
	road.position.y = 0.025
	road.material_override = road_mat
	add_child(road)
	var ground_mat := surface("ground", Vector3.ONE)
	ground_mat.albedo_color = Color(0.36, 0.43, 0.30)
	ground_mat.roughness_texture = null
	ground_mat.roughness = 0.98
	ground_mat.normal_scale = 0.4
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-140, 140, 3):
		for x in range(-70, 70, 3):
			for offset in [Vector2(0,0),Vector2(3,0),Vector2(0,3),Vector2(3,0),Vector2(3,3),Vector2(0,3)]:
				var px: float = x + offset.x
				var pz: float = z + offset.y
				st.set_uv(Vector2(px, pz) / 3.5)
				st.add_vertex(Vector3(px,ground_height(px,pz),pz))
	st.generate_normals()
	st.generate_tangents()
	var terrain := MeshInstance3D.new()
	terrain.name = "ForestFloor"
	terrain.mesh = st.commit()
	terrain.material_override = ground_mat
	add_child(terrain)
	var paint := simple_material(Color("d8d5be"))
	for side in [-1.0, 1.0]:
		box("EdgeLine", Vector3(side*3.64,0.032,0),Vector3(0.11,0.008,240),paint)
	for z in range(-116, 120, 10):
		box("CentreLine",Vector3(0,0.032,z),Vector3(0.10,0.008,3),paint)
	var metal := simple_material(Color("8a9697"),0.37,0.75)
	var dark := simple_material(Color("333c3d"),0.7,0.4)
	var amber := simple_material(Color("e9a14d"),0.4)
	for side in [-1.0,1.0]:
		for z in range(-120,120,4):
			# Two narrow metal strips form a roadside barrier with open space below.
			box("BarrierPost",Vector3(side*4.65,0.40,z),Vector3(0.09,0.92,0.08),dark)
			box("BarrierRail",Vector3(side*4.65,0.75,z+2),Vector3(0.075,0.18,4.02),metal)
			box("BarrierRail",Vector3(side*4.65,0.52,z+2),Vector3(0.075,0.13,4.02),metal)
			if z % 12 == 0:
				box("Reflector",Vector3(side*4.58,0.77,z),Vector3(0.035,0.06,0.16),amber)

func build_trees() -> void:
	var source: Node3D = load("res://assets/tree/tree.gltf").instantiate()
	var variants: Array[MeshInstance3D] = []
	for child in source.find_children("*", "MeshInstance3D", true, false):
		variants.append(child)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6149
	for i in range(180):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * rng.randf_range(7.5,34.0)
		var z := rng.randf_range(-122.0,118.0)
		if x > 0 and z > -14 and z < 5:
			x += 6.0
		var tree := MeshInstance3D.new()
		tree.name = "Pine_%02d" % i
		tree.mesh = variants[i % variants.size()].mesh
		tree.position = Vector3(x,ground_height(x,z)-0.025,z)
		tree.rotation.y = rng.randf_range(-PI,PI)
		var size := rng.randf_range(3.5,8.0)
		tree.scale = Vector3(size*0.85,size,size*0.85)
		tree.visibility_range_end = 130.0
		tree.lod_bias = 0.7
		add_child(tree)
	# A few young trees show the source model at a smaller scale near the road.
	for i in range(12):
		var tree := MeshInstance3D.new()
		tree.mesh = variants[i % variants.size()].mesh
		var x := (-1.0 if i % 2 == 0 else 1.0) * rng.randf_range(5.6,7.5)
		var z := rng.randf_range(-65,50)
		tree.position = Vector3(x,ground_height(x,z),z)
		tree.rotation.y = rng.randf_range(-PI,PI)
		tree.scale = Vector3.ONE * rng.randf_range(1.0,2.0)
		add_child(tree)
	source.free()

func build_car() -> void:
	car = Node3D.new()
	car.name = "Car"
	car.position = Vector3(1.65,0.035,0)
	add_child(car)
	var model: Node3D = load("res://assets/car/CarConcept.gltf").instantiate()
	model.rotation.y = PI
	car.add_child(model)
	var materials: Dictionary = {}
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		# Keep the car out of its own captured reflections.
		mesh.layers = 2
		for i in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(i)
			if not original is StandardMaterial3D:
				continue
			var key: String = original.resource_name
			if not materials.has(original):
				var m: StandardMaterial3D = original.duplicate()
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				# Imported normal maps use per-texture transforms that this material
				# representation cannot reproduce consistently. Keep clean geometry.
				m.normal_enabled = false
				m.ao_enabled = false
				if key in ["Tireside","Tiretread"]:
					m.albedo_color = Color("17191a")
					m.albedo_texture = null
					m.metallic = 0.0
					m.roughness = 0.78
				elif key in ["Rim1","Rim2"]:
					m.emission_enabled = false
					m.metallic = 0.85
					m.roughness = 0.3
				if key.begins_with("Paint 1"):
					m.albedo_color = Color("e65d19")
					m.metallic = 0.65
					m.roughness = 0.24
					m.clearcoat_enabled = true
					m.clearcoat = 1.0
					m.clearcoat_roughness = 0.16
					m.normal_enabled = false
					m.ao_enabled = false
				elif key.begins_with("Paint 2"):
					m.albedo_color = Color("202a2d")
					m.metallic = 0.7
					m.roughness = 0.27
					m.normal_enabled = false
					m.ao_enabled = false
				elif key == "Glass":
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					m.albedo_color = Color(0.18,0.25,0.28,0.42)
					m.metallic = 0.35
					m.roughness = 0.08
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
					m.refraction_enabled = false
				elif key == "License":
					# A neutral plate replaces the sample's branding in this preview.
					m.albedo_texture = null
					m.albedo_color = Color("111b20")
				elif key == "Headlight":
					m.emission_energy_multiplier = 2.2
				materials[original] = m
			mesh.set_surface_override_material(i,materials[original])
	for wheel_name in ["WheelFrontL","WheelFrontR","WheelRearL","WheelRearR"]:
		var wheel: Node3D = model.find_child(wheel_name,true,false)
		if wheel:
			var pivot := Node3D.new()
			pivot.name = wheel_name+"Spin"
			car.add_child(pivot)
			pivot.global_position = wheel.global_position
			wheel.reparent(pivot,true)
			# The source parks both front wheels at 30 degrees. Straighten them
			# before the test's steering and spin transforms are applied.
			if wheel_name.begins_with("WheelFront"):
				pivot.rotate_y(deg_to_rad(30.0))
			wheels.append(pivot)
			wheel_rest.append(pivot.basis)
	for side in [-1.0,1.0]:
		var light := SpotLight3D.new()
		light.position = Vector3(side*0.76,0.62,-2.1)
		light.rotation_degrees.x = -6
		light.light_color = Color("dcecff")
		light.light_energy = 2.0
		light.spot_range = 32.0
		light.spot_angle = 28
		light.visible = false
		light.name = "HeadlightBeam"
		car.add_child(light)

func build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.1
	camera.far = 450
	camera.fov = 48
	camera.current = true
	camera.cull_mask = 3
	add_child(camera)

func text_label(parent: Node, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(32,30)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.055,0.07,0.86)
	style.content_margin_left = 22
	style.content_margin_right = 26
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel",style)
	hud.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",6)
	panel.add_child(rows)
	text_label(rows,"STUNTCAR  /  QUALITÄTSPROBE",14,Color("f5ab65"))
	mode_label = text_label(rows,"Ansicht · Waldstrecke",26,Color("f4f2e9"))
	text_label(rows,"1  Auto ansehen     2  Fahrkamera",17,Color("cbd1d2"))
	text_label(rows,"W / ↑  Gas     S / ↓  Bremse     A / D  Lenken",17,Color("cbd1d2"))
	text_label(rows,"L  Abendlicht     R  Zurücksetzen     H  Anzeige",17,Color("cbd1d2"))
	text_label(rows,"Maus ziehen: Ansicht drehen · Mausrad: Abstand",15,Color("a7b1b4"))
	speed_label = text_label(rows,"0 km/h",18,Color("f4f2e9"))
	var note := Label.new()
	note.text = "Kostenlose Modelle · echte Darstellung in Godot · kurze Teststrecke"
	note.position = Vector2(34,953)
	note.add_theme_font_size_override("font_size",16)
	note.add_theme_color_override("font_color",Color("e4e8e5"))
	note.add_theme_constant_override("outline_size",5)
	note.add_theme_color_override("font_outline_color",Color(0.03,0.04,0.04,0.8))
	hud.add_child(note)

func set_camera(value: int) -> void:
	mode = value
	mode_label.text = "Auto ansehen · Waldstrecke" if mode == 0 else "Fahrkamera · Waldstrecke"
	update_camera(1.0,true)

func reset_car() -> void:
	car.position = Vector3(1.65,0.035,0)
	car.rotation = Vector3.ZERO
	speed = 0
	steering = 0
	wheel_spin = 0
	update_camera(1.0,true)

func toggle_light() -> void:
	dusk = not dusk
	sun.light_energy = 0.28 if dusk else 1.25
	sun.light_color = Color("ffad70") if dusk else Color("fff0d7")
	sun.rotation_degrees.x = -8 if dusk else -28
	world.environment.background_energy_multiplier = 0.18 if dusk else 0.65
	world.environment.ambient_light_energy = 0.3 if dusk else 0.5
	world.environment.fog_light_color = Color("647785") if dusk else Color("a8b5b8")
	for child in car.get_children():
		if child is SpotLight3D:
			child.visible = dusk

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: set_camera(0)
			KEY_2: set_camera(1)
			KEY_L: toggle_light()
			KEY_R: reset_car()
			KEY_H: hud.visible = not hud.visible
			KEY_ESCAPE: get_tree().quit()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(4.8,camera_distance-0.5)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(16,camera_distance+0.5)
	if event is InputEventMouseMotion and dragging and mode == 0:
		orbit_angle += event.relative.x * 0.006

func _process(delta: float) -> void:
	var gas := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var brake := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	step_drive(delta,gas,brake,float(right)-float(left))
	update_camera(delta)
	speed_label.text = "%d km/h   ·   %d Bilder/s" % [roundi(speed*3.6),Engine.get_frames_per_second()]

func step_drive(delta: float, gas: bool, brake: bool, turn: float) -> void:
	if gas and mode == 0:
		set_camera(1)
	speed = move_toward(speed,24.0 if gas and not brake else 0.0,(15.0 if brake else 5.0 if gas else 2.5)*delta)
	steering = move_toward(steering,turn*0.23,delta*0.8)
	car.position.z -= speed*delta
	car.position.x = clampf(car.position.x+steering*speed*delta,-2.75,2.75)
	car.rotation.y = lerp_angle(car.rotation.y,-steering,1.0-exp(-delta*5.0))
	wheel_spin -= speed*delta/0.38
	for i in range(wheels.size()):
		wheels[i].basis = Basis(Vector3.UP,-steering if i < 2 else 0.0)*Basis(Vector3.RIGHT,wheel_spin)*wheel_rest[i]
	if car.position.z < -103:
		car.position.z = 100
		update_camera(1.0,true)

func update_camera(delta: float, instant: bool = false) -> void:
	if camera == null:
		return
	var target := car.position+Vector3(0,0.75,0)
	var offset := Vector3(sin(0.53+orbit_angle)*camera_distance,2.2,-cos(0.53+orbit_angle)*camera_distance)
	if mode == 1:
		offset = Vector3(0,2.65,7.2)
		target = car.position+Vector3(0,0.6,-2.5)
	var desired := car.position+offset
	camera.position = desired if instant else camera.position.lerp(desired,1.0-exp(-delta*7.0))
	camera.look_at(target)
