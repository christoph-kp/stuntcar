extends RefCounted

func build(builder,g) -> void:
	for snowy in [false,true]:
		for tall in [false,true]:
			var tree := Node3D.new()
			var size := 1.35 if tall else 1.0
			g.cylinder(tree,"Trunk",0.23,0.13,5.8*size,Vector3(0,2.9*size,0),"bark",9)
			for i in range(4):
				var height := (2.4+i*1.2)*size
				var radius := (2.1-i*0.38)*size
				g.cylinder(tree,"Branches",radius,0.03,2.6*size,Vector3(0,height,0),"pine" if i%2 == 0 else "pine_light",9)
				if snowy:
					g.cylinder(tree,"Snow",radius*0.87,0.02,2.23*size,Vector3(0,height+0.25*size,0),"snow",9)
			builder.record(tree,"alpine" if snowy else "forest",("snow_pine_" if snowy else "pine_")+("tall" if tall else "small"),"Schneetanne" if snowy else "Tanne")
	for theme in ["alpine","forest","canyon","coast"]:
		for variant in range(2):
			var rock := Node3D.new()
			var base: String = {"alpine":"rock","forest":"rock","canyon":"sandstone","coast":"basalt"}[theme]
			var size := 1.0 if variant == 0 else 1.6
			var body = g.rock(rock,"Rock",Vector3(0,1.0*size,0),Vector3(1.95,1.35,1.5)*size,base,32+variant)
			body.rotation.y = 0.34+variant*0.4
			if theme in ["alpine","forest"]:
				g.sphere(rock,"Top",1.25,Vector3(-0.1*size,1.75*size,0.05),Vector3(1.30,0.36,1.0)*size,"snow" if theme == "alpine" else "moss")
			builder.record(rock,theme,"boulder_"+str(variant+1),"Felsen " + str(variant+1))
		var cliff := Node3D.new()
		var mat: String = {"alpine":"rock","forest":"rock","canyon":"sandstone","coast":"basalt"}[theme]
		for i in range(5):
			var h := 8.0 + sin(i*2.1)*2.0
			var block = g.rock(cliff,"CliffRock",Vector3((i-2)*3.4,h*0.40,sin(i)*0.6),Vector3(3.7,h*0.65,3.5),mat,120+i)
			block.rotation.y = i*0.7
			if theme == "canyon":
				g.cylinder(cliff,"Stratum",3.05,2.9,0.55,Vector3((i-2)*3.4,h*0.67,sin(i)*0.6),"sandstone_light",6)
			elif theme == "alpine":
				g.rock(cliff,"SnowCap",Vector3((i-2)*3.4,h*0.88,sin(i)*0.6),Vector3(2.4,0.8,2.3),"snow",120+i)
		builder.record(cliff,theme,"cliff_18","Felswand · etwa 18 m")
		var ground := Node3D.new()
		g.box(ground,"Ground",Vector3(24,0.35,24),Vector3(0,-0.175,0),{"alpine":"snow_shadow","forest":"grass","canyon":"sand","coast":"basalt"}[theme])
		builder.record(ground,theme,"ground_24","Bodenplatte · 24 m")
	var mountain := Node3D.new()
	for i in range(3):
		var h := 26.0+i*9
		g.rock(mountain,"Mountain",Vector3((i-1)*17,h*0.20,i*5),Vector3(21,h*0.64,18),"rock_light",200+i)
		g.rock(mountain,"SnowRidge",Vector3((i-1)*17,h*0.54,i*5),Vector3(12,h*0.31,10),"snow",200+i)
	builder.record(mountain,"alpine","mountain_group","Berggruppe")
	var bank := Node3D.new()
	g.sphere(bank,"Snowbank",2.0,Vector3(0,0.1,0),Vector3(2.2,0.35,0.8),"snow")
	builder.record(bank,"alpine","snowbank","Schneewall")
	var log_node := Node3D.new()
	var log_mesh = g.cylinder(log_node,"Log",0.34,0.27,3.5,Vector3(0,0.34,0),"bark",10)
	log_mesh.rotation.z = PI/2
	for x in [-1.76,1.76]:
		var end = g.cylinder(log_node,"End",0.24,0.24,0.02,Vector3(x,0.34,0),"sand",10)
		end.rotation.z = PI/2
	builder.record(log_node,"forest","fallen_log","Baumstamm")
	var shrub := Node3D.new()
	for i in range(4):
		g.sphere(shrub,"Leaves",0.65,Vector3(sin(i*2.4)*0.5,0.45,cos(i*2.4)*0.5),Vector3(1,0.8,1),"moss" if i%2 else "pine_light")
	builder.record(shrub,"forest","shrub","Strauch")
	var mesa := Node3D.new()
	g.cylinder(mesa,"Foot",15,11,13,Vector3(0,6.5,0),"sandstone",7)
	g.cylinder(mesa,"Band",11.3,10.9,1.0,Vector3(0,12.5,0),"sandstone_light",7)
	g.cylinder(mesa,"Top",10.9,9.5,6.0,Vector3(0,16,0),"sandstone",7)
	builder.record(mesa,"canyon","mesa","Tafelberg")
	var tower := Node3D.new()
	for i in range(4):
		var pillar = g.cylinder(tower,"Layer",3.4-i*0.6,3.0-i*0.6,3.0,Vector3(sin(i)*0.3,1.5+i*2.8,0),"sandstone" if i%2 else "sandstone_light",7)
		pillar.rotation.y = i*0.2
	builder.record(tower,"canyon","rock_tower","Felsturm")
	var lighthouse := Node3D.new()
	g.cylinder(lighthouse,"Base",2.2,1.8,0.65,Vector3(0,0.325,0),"concrete",16)
	g.cylinder(lighthouse,"Tower",1.25,0.82,8,Vector3(0,4.5,0),"ivory",16)
	g.cylinder(lighthouse,"Band",1.10,0.98,2,Vector3(0,4.5,0),"paint_orange",16)
	g.cylinder(lighthouse,"Gallery",1.38,1.38,0.25,Vector3(0,8.55,0),"dark_metal",16)
	g.cylinder(lighthouse,"Lantern",0.77,0.77,1.3,Vector3(0,9.3,0),"glass",12)
	g.cylinder(lighthouse,"Lamp",0.22,0.22,0.65,Vector3(0,9.3,0),"amber",12)
	for i in range(6):
		var a := TAU*i/6.0
		g.box(lighthouse,"Frame",Vector3(0.07,1.4,0.07),Vector3(cos(a)*0.8,9.3,sin(a)*0.8),"dark_metal")
	g.cylinder(lighthouse,"Roof",1.1,0.0,0.9,Vector3(0,10.4,0),"dark_metal",12)
	g.box(lighthouse,"Door",Vector3(0.55,1.3,0.08),Vector3(0,1.15,1.19),"dark_metal")
	g.marker(lighthouse,"LightSocket",Vector3(0,9.3,-0.85))
	builder.record(lighthouse,"coast","lighthouse","Leuchtturm")
	var sea := Node3D.new()
	g.box(sea,"Water",Vector3(48,0.08,48),Vector3(0,-0.04,0),"sea")
	builder.record(sea,"coast","water_48","Wasserfläche · 48 m")
	var foam := Node3D.new()
	for i in range(7):
		g.sphere(foam,"Foam",0.6,Vector3(i*0.85-2.6,0,sin(i)*0.2),Vector3(1.2,0.04,0.6),"foam")
	builder.record(foam,"coast","foam_strip","Schaumkante")
