extends RefCounted

func build(builder,g) -> void:
	for spec in [
		["straight_24","Gerade · 24 m","straight",0.0],
		["curve_left_45","Linkskurve · 45 Grad","curve",-PI/4],
		["curve_right_45","Rechtskurve · 45 Grad","curve",PI/4],
		["bank_left_90","Steilkurve links · 90 Grad","bank",-PI/2],
		["bank_right_90","Steilkurve rechts · 90 Grad","bank",PI/2],
		["jump_launch","Sprungrampe · 18 Grad","launch",0.0],
		["jump_landing","Landerampe · 18 Grad","landing",0.0],
		["hill_32","Kuppe · 32 m","hill",0.0],
		["loop_12","Looping · 12 m Radius","loop",0.0]
	]:
		var points := PackedVector3Array()
		var ups := PackedVector3Array()
		var forwards := PackedVector3Array()
		var kind: String = spec[2]
		var angle: float = spec[3]
		var count := 160 if kind == "loop" else 80
		for i in range(count+1):
			var t := float(i)/count
			var p := Vector3(0,0,-24*t)
			var f := Vector3.FORWARD
			var up := Vector3.UP
			if kind in ["curve","bank"]:
				var radius := 28.0
				var a := t*absf(angle)
				var sign_value := signf(angle)
				p = Vector3(sign_value*radius*(1-cos(a)),0,-radius*sin(a))
				f = Vector3(sign_value*sin(a),0,-cos(a))
				if kind == "bank": up = up.rotated(f,sign_value*deg_to_rad(45)*pow(sin(PI*t),2))
			elif kind in ["launch","landing"]:
				var slope := tan(deg_to_rad(18))
				if kind == "launch":
					p = Vector3(0,9*slope*t*t,-18*t)
					f = Vector3(0,slope*t,-1).normalized()
				else:
					p = Vector3(0,-18*slope*(t-t*t*0.5),-18*t)
					f = Vector3(0,-slope*(1-t),-1).normalized()
				up = Vector3.RIGHT.cross(f).normalized()
			elif kind == "hill":
				p = Vector3(0,3*pow(sin(PI*t),2),-32*t)
				f = Vector3(0,3*PI*sin(TAU*t)/32,-1).normalized()
				up = Vector3.RIGHT.cross(f).normalized()
			elif kind == "loop":
				# A full vertical loop, with a smooth lateral offset of nine meters.
				var a := t*TAU
				p = Vector3(9*(3*t*t-2*t*t*t),12*(1-cos(a)),-12*sin(a))
				f = Vector3(54*t*(1-t),12*TAU*sin(a),-12*TAU*cos(a)).normalized()
				var radial := Vector3(0,cos(a),sin(a))
				var right := f.cross(radial).normalized()
				up = right.cross(f).normalized()
			points.append(p)
			ups.append(up)
			forwards.append(f)
		var node := make_track(g,points,ups,forwards)
		node.set_meta("kind",kind)
		builder.record(node,"track",spec[0],spec[1])
	var post := Node3D.new()
	g.box(post,"Foot",Vector3(0.32,0.10,0.32),Vector3(0,0.05,0),"dark_metal")
	g.box(post,"Post",Vector3(0.13,0.90,0.15),Vector3(0,0.50,0),"dark_metal")
	g.box(post,"Reflector",Vector3(0.17,0.19,0.17),Vector3(0,0.89,0),"amber")
	builder.record(post,"shared","road_post","Randpfosten")
	var support := Node3D.new()
	g.box(support,"Column",Vector3(0.8,7.1,1.3),Vector3(0,-4.45,0),"concrete")
	g.box(support,"Beam",Vector3(6.6,0.55,1.6),Vector3(0,-0.70,0),"concrete")
	g.box(support,"Foot",Vector3(2.5,0.4,2.6),Vector3(0,-8,0),"concrete")
	builder.record(support,"shared","bridge_support_8","Brückenstütze · 8 m")
	var gate := Node3D.new()
	for x in [-3.7,3.7]:
		g.box(gate,"Leg",Vector3(0.24,4.6,0.24),Vector3(x,2.3,0),"dark_metal")
		g.box(gate,"LegMark",Vector3(0.28,0.65,0.28),Vector3(x,1,0),"paint_orange")
	g.box(gate,"Beam",Vector3(7.7,0.45,0.40),Vector3(0,4.5,0),"dark_metal")
	for i in range(12):
		g.box(gate,"Flag",Vector3(0.6,0.20,0.02),Vector3(-3.3+i*0.6,4.5,0.21),"ivory" if i%2 else "paint_orange")
	builder.record(gate,"shared","checkpoint_gate","Streckentor")

func make_track(g,points: PackedVector3Array,ups: PackedVector3Array,forwards: PackedVector3Array) -> Node3D:
	var node := Node3D.new()
	var road: SurfaceTool = g.surface()
	var sides: SurfaceTool = g.surface()
	var orange: SurfaceTool = g.surface()
	var cream: SurfaceTool = g.surface()
	var line: SurfaceTool = g.surface()
	var total := 0.0
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		var ua := ups[i]
		var ub := ups[i+1]
		var ra := forwards[i].cross(ua).normalized()
		var rb := forwards[i+1].cross(ub).normalized()
		var normal := (ua+ub).normalized()
		g.quad(road,a-ra*3,a+ra*3,b+rb*3,b-rb*3,normal)
		g.quad(sides,a-ra*3-ua*0.38,b-rb*3-ub*0.38,b+rb*3-ub*0.38,a+ra*3-ua*0.38,-normal)
		for side in [-1.0,1.0]:
			g.quad(sides,a+ra*3*side,b+rb*3*side,b+rb*3*side-ub*0.38,a+ra*3*side-ua*0.38,(ra+rb)*side)
			var border: SurfaceTool = cream if int(total/3)%2 else orange
			g.quad(border,a+ra*2.73*side+ua*0.035,a+ra*3*side+ua*0.035,b+rb*3*side+ub*0.035,b+rb*2.73*side+ub*0.035,normal)
		if int(total/3)%3 == 0:
			g.quad(line,a-ra*0.035+ua*0.025,a+ra*0.035+ua*0.025,b+rb*0.035+ub*0.025,b-rb*0.035+ub*0.025,normal)
		total += a.distance_to(b)
	var mesh: MeshInstance3D = g.part(node,"Road",road.commit(),Vector3.ZERO,"asphalt")
	g.part(node,"Deck",sides.commit(),Vector3.ZERO,"dark_metal")
	g.part(node,"OrangeEdge",orange.commit(),Vector3.ZERO,"paint_orange")
	g.part(node,"IvoryEdge",cream.commit(),Vector3.ZERO,"ivory")
	g.part(node,"CenterMark",line.commit(),Vector3.ZERO,"ivory")
	var collision := StaticBody3D.new()
	collision.name = "RoadCollision"
	collision.collision_layer = 1
	collision.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = mesh.mesh.create_trimesh_shape()
	collision.add_child(shape)
	node.add_child(collision)
	for i in [0,points.size()-1]:
		var f := forwards[i]
		var right := f.cross(ups[i]).normalized()
		g.marker(node,"Entry" if i == 0 else "Exit",points[i],Basis(right,ups[i],-f))
	node.set_meta("centerline",points)
	node.set_meta("up_vectors",ups)
	node.set_meta("length_m",total)
	node.set_meta("road_width",6.0)
	return node
