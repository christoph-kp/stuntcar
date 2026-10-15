extends Camera3D

var initialized := false

func follow(car: Node3D, heading: float, delta: float, overview: bool, pitch: float = 0.0, speed: float = 22.0) -> void:
	var forward := Vector3(sin(heading), 0, -cos(heading))
	var right := Vector3(cos(heading), 0, sin(heading))
	var destination: Vector3
	var target: Vector3
	if overview:
		destination = car.global_position - forward * 17.0 + right * 13.0 + Vector3.UP * 12.0
		target = car.global_position + forward * 15.0 - right * 6.0
		fov = 58
	else:
		destination = car.global_position - forward * 5.6 + Vector3.UP * (2.35 + maxf(0.0, -sin(pitch)) * 6.0)
		target = car.global_position + forward * 13.0 + Vector3.UP * (0.9 + clampf(tan(pitch) * 10.0, -3.0, 4.0))
		fov = lerpf(fov, lerpf(80.0, 100.0, clampf((speed - 14.0) / 32.0, 0.0, 1.0)), 1.0 - exp(-3.0 * delta))
	if not initialized:
		global_position = destination
		initialized = true
	else:
		global_position = global_position.lerp(destination, 1.0 - exp(-9.0 * delta))
	look_at(target, Vector3.UP)
