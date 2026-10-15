extends CharacterBody3D

const QualityAssets = preload("res://scripts/quality_assets.gd")
var wheels: Array[Node3D] = []
var body: Node3D
var fall_velocity := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.6
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.65, 2.7)
	collision.shape = shape
	collision.position.y = 0.325
	add_child(collision)
	body = QualityAssets.create_car()
	add_child(body)
	for wheel_name in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		wheels.append(body.get_node(wheel_name))

func place(model) -> void:
	global_position = model.position + Vector3.UP * 0.03
	rotation = Vector3(model.pitch, -model.heading, model.bank)
	body.rotation = Vector3.ZERO
	body.position = Vector3.ZERO
	velocity = Vector3.ZERO
	fall_velocity = 0.0

func drive(model, delta: float) -> void:
	# The assisted model owns the road and flight path. Falling remains physical.
	var before := global_position
	global_position = model.position + Vector3.UP * 0.03
	velocity = (global_position - before) / maxf(delta, 0.001)
	rotation.y = -model.heading
	rotation.z = model.bank
	rotation.x = lerp_angle(rotation.x, model.pitch, 1.0 - exp(-10.0 * delta))
	body.position.y = -sin(model.landing_pulse * PI) * 0.16
	body.rotation.z = lerp_angle(body.rotation.z, -model.lateral * 0.055, 1.0 - exp(-7.0 * delta))
	for wheel in wheels:
		wheel.rotate_x(-model.speed_mps * delta / 0.384)

func fall(delta: float) -> void:
	velocity.y -= 22.0 * delta
	move_and_slide()
	rotation.z += 0.3 * delta
