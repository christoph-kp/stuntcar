extends RefCounted

func build(builder, g) -> void:
	var car := Node3D.new()
	car.set_meta("wheel_radius",0.4)
	car.set_meta("forward",Vector3.FORWARD)
	g.loft(car,"LowerBody",[[-1.64,0.68,0.25,0.55,0.10],[-1.25,0.82,0.23,0.62,0.12],[0.95,0.82,0.24,0.63,0.12],[1.55,0.72,0.26,0.50,0.08]],"dark_metal")
	g.loft(car,"Body",[[-1.65,0.67,0.43,0.67,0.08],[-1.2,0.83,0.45,0.86,0.12],[-0.45,0.78,0.46,0.91,0.10],[0.72,0.8,0.46,0.88,0.10],[1.48,0.76,0.44,0.81,0.12]],"paint_orange")
	g.loft(car,"CabinGlass",[[-0.65,0.63,0.84,0.88,0.01],[-0.17,0.56,0.86,1.34,0.07],[0.50,0.56,0.86,1.34,0.07],[1.02,0.64,0.82,0.90,0.025]],"glass")
	g.loft(car,"Roof",[[-0.21,0.56,1.32,1.37,0.015],[0.53,0.56,1.32,1.37,0.015]],"paint_orange")
	for side in [-1.0,1.0]:
		var stripe = g.loft(car,"HoodStripe",[[-1.61,0.075,0.676,0.68,0.001],[-1.18,0.075,0.865,0.869,0.001],[-0.66,0.075,0.899,0.903,0.001]],"ivory")
		stripe.position.x = side * 0.15
		g.box(car,"RoofStripe",Vector3(0.15,0.008,0.73),Vector3(side*0.15,1.379,0.16),"ivory")
		var rear_stripe = g.loft(car,"RearStripe",[[1.04,0.075,0.85,0.855,0.001],[1.47,0.075,0.817,0.822,0.001]],"ivory")
		rear_stripe.position.x = side*0.15
		g.box(car,"RearStripeEnd",Vector3(0.15,0.18,0.01),Vector3(side*0.15,0.64,1.486),"ivory")
		g.box(car,"DoorSill",Vector3(0.08,0.12,1.06),Vector3(side*0.80,0.42,0.10),"dark_metal")
		var pillar = g.box(car,"WindowPillar",Vector3(0.055,0.48,0.06),Vector3(side*0.575,1.08,0.46),"paint_orange")
		pillar.rotation.x = -0.08
		g.box(car,"DoorHandle",Vector3(0.025,0.035,0.16),Vector3(side*0.807,0.82,0.48),"metal")
		g.box(car,"MirrorArm",Vector3(0.15,0.045,0.055),Vector3(side*0.73,1.02,-0.43),"dark_metal")
		g.sphere(car,"Mirror",0.11,Vector3(side*0.82,1.04,-0.43),Vector3(1,0.65,1.2),"paint_orange")
		for z in [-1.0,1.0]:
			var arch_s: SurfaceTool = g.surface()
			for i in range(16):
				var a := PI * float(i)/16.0
				var b := PI * float(i+1)/16.0
				for layer in [0,1]:
					var x: float = side * (0.80 + layer*0.16)
					g.quad(arch_s,Vector3(x,0.40+sin(a)*0.47,z+cos(a)*0.47),Vector3(x,0.40+sin(b)*0.47,z+cos(b)*0.47),Vector3(x,0.40+sin(b)*0.56,z+cos(b)*0.56),Vector3(x,0.40+sin(a)*0.56,z+cos(a)*0.56),Vector3(side,0,0))
				g.quad(arch_s,Vector3(side*0.80,0.40+sin(a)*0.56,z+cos(a)*0.56),Vector3(side*0.96,0.40+sin(a)*0.56,z+cos(a)*0.56),Vector3(side*0.96,0.40+sin(b)*0.56,z+cos(b)*0.56),Vector3(side*0.80,0.40+sin(b)*0.56,z+cos(b)*0.56),Vector3(0,sin((a+b)*0.5),cos((a+b)*0.5)))
			g.part(car,"WheelArch",arch_s.commit(),Vector3.ZERO,"paint_orange")
			var wheel := Node3D.new()
			wheel.name = ("WheelF" if z < 0 else "WheelR") + ("L" if side < 0 else "R")
			wheel.position = Vector3(side*0.86,0.40,z)
			car.add_child(wheel)
			var tire = g.cylinder(wheel,"Tire",0.4,0.4,0.25,Vector3.ZERO,"rubber",24)
			tire.rotation.z = PI/2
			var rim = g.cylinder(wheel,"Rim",0.27,0.27,0.265,Vector3.ZERO,"dark_metal",24)
			rim.rotation.z = PI/2
			var hub = g.cylinder(wheel,"Hub",0.065,0.065,0.285,Vector3.ZERO,"metal",12)
			hub.rotation.z = PI/2
			for i in range(6):
				var angle := TAU*i/6.0
				var spoke = g.box(wheel,"Spoke",Vector3(0.018,0.23,0.045),Vector3(side*0.14,sin(angle)*0.14,cos(angle)*0.14),"metal")
				spoke.rotation.x = PI/2-angle
			for i in range(24):
				var angle := TAU*i/24.0
				var tread = g.box(wheel,"Tread",Vector3(0.21,0.014,0.045),Vector3(0,sin(angle)*0.402,cos(angle)*0.402),"rubber")
				tread.rotation.x = PI/2-angle
		g.box(car,"LampHousing",Vector3(0.36,0.18,0.08),Vector3(side*0.48,0.63,-1.61),"dark_metal")
		g.box(car,"HeadlightLeft" if side < 0 else "HeadlightRight",Vector3(0.25,0.08,0.012),Vector3(side*0.48,0.66,-1.657),"headlight")
		g.box(car,"RearLampHousing",Vector3(0.41,0.16,0.04),Vector3(side*0.47,0.67,1.56),"dark_metal")
		g.box(car,"TailLamp",Vector3(0.32,0.055,0.015),Vector3(side*0.47,0.69,1.587),"taillight")
		g.box(car,"WingMount",Vector3(0.065,0.25,0.18),Vector3(side*0.55,1.00,1.24),"dark_metal")
		g.box(car,"WingEnd",Vector3(0.05,0.16,0.37),Vector3(side*0.89,1.14,1.27),"paint_orange")
		var exhaust = g.cylinder(car,"Exhaust",0.085,0.085,0.10,Vector3(side*0.50,0.38,1.53),"metal",16)
		exhaust.rotation.x = PI/2
		var exhaust_inner = g.cylinder(car,"ExhaustInside",0.065,0.065,0.012,Vector3(side*0.50,0.38,1.587),"rubber",16)
		exhaust_inner.rotation.x = PI/2
		g.box(car,"HoodVent",Vector3(0.10,0.02,0.27),Vector3(side*0.52,0.88,-0.85),"dark_metal")
	g.box(car,"Wing",Vector3(1.80,0.07,0.35),Vector3(0,1.14,1.27),"paint_orange")
	g.box(car,"FrontGrille",Vector3(0.69,0.13,0.025),Vector3(0,0.42,-1.65),"rubber")
	for x in [-0.5,-0.25,0,0.25,0.5]:
		g.box(car,"RearDiffuser",Vector3(0.028,0.12,0.36),Vector3(x,0.26,1.32),"dark_metal")
	g.marker(car,"CameraTarget",Vector3(0,0.8,0))
	g.marker(car,"HeadlightSocketLeft",Vector3(-0.48,0.66,-1.70))
	g.marker(car,"HeadlightSocketRight",Vector3(0.48,0.66,-1.70))
	builder.record(car,"vehicle","stunt_coupe","Stunt-Coupé")
