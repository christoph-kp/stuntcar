extends RefCounted

const VoiceStrength = preload("res://scripts/input/voice_strength.gd")

const CRUISE_SPEED := 22.0
const MIN_SPEED := 14.0
const MAX_SPEED := 46.0
const SPEED_STEP := 5.0
const BOOST_SECONDS := 1.2
const BOOST_COOLDOWN := 2.8
const BOOST_BONUS := 12.0
const BOOST_ACCEL := 32.0
const FULL_BRAKE_DECEL := 42.0
var boost_remaining := 0.0
var boost_cooldown := 0.0
var emergency_braking := false
var drift_angle := 0.0
var steering_input := 0.0
var target_speed_mps := CRUISE_SPEED
var speed_strength := 1.0
var turn_strength := 1.0
var track
var position := Vector3.ZERO
var heading := 0.0
var speed_mps := 0.0
var distance_m := 0.0
var elapsed_s := 0.0
var active_curve_id := -1
var completed_curves := 0
var off_road := false
var finished := false
var lateral := 0.0
var hint_seconds := 5.0
var manual_remaining := 0.0
var manual_direction := 0
var last_command := 0
var completed_ids: Dictionary = {}
var correction_remaining := 0.0
var guide_offset := 0.0
var airborne := false
var pitch := 0.0
var bank := 0.0
var speed_feedback := ""
var speed_feedback_seconds := 0.0
var jump_assist_until := -1.0
var landing_pulse := 0.0

func _init(track_data) -> void:
	track = track_data
	reset()

func reset(checkpoint_m: float = 0.0) -> void:
	var frame: Dictionary = track.sample(checkpoint_m)
	position = frame.position
	heading = frame.heading
	speed_mps = CRUISE_SPEED
	target_speed_mps = CRUISE_SPEED
	speed_strength = 1.0
	turn_strength = 1.0
	distance_m = checkpoint_m
	elapsed_s = 0.0
	active_curve_id = -1
	completed_curves = 0
	completed_ids.clear()
	off_road = false
	finished = false
	lateral = 0.0
	manual_remaining = 0.0
	manual_direction = 0
	last_command = 0
	correction_remaining = 0.0
	guide_offset = 0.0
	airborne = false
	pitch = track.pitch_at(distance_m)
	bank = track.bank_at(distance_m)
	speed_feedback = ""
	speed_feedback_seconds = 0.0
	jump_assist_until = -1.0
	landing_pulse = 0.0
	boost_remaining = 0.0
	boost_cooldown = 0.0
	emergency_braking = false
	drift_angle = 0.0
	steering_input = 0.0

func request_turn(direction: int, strength: float = VoiceStrength.NORMAL) -> void:
	if off_road or finished or direction not in [-1, 1]:
		return
	last_command = direction
	turn_strength = VoiceStrength.multiplier(strength)
	steering_input = float(direction) * turn_strength
	var curve: Dictionary = track.next_curve(distance_m)
	var jump: Dictionary = track.jump_for_correction(distance_m)
	if not jump.is_empty() and (absf(lateral) < 0.15 or signf(lateral) == -direction):
		jump_assist_until = maxf(jump.end_m + 24.0, distance_m + 24.0)
		manual_remaining = 0.0
		# A turn cue can arrive during landing. Keep that authorization while
		# the same command centers the car for the last part of the jump.
		if not curve.is_empty() and curve.turn_sign == direction and distance_m >= curve.start_m - input_window_m():
			active_curve_id = curve.id
		return
	jump_assist_until = -1.0
	var window := input_window_m()
	if not curve.is_empty() and curve.turn_sign == direction and distance_m >= curve.start_m - window:
		if active_curve_id == curve.id or distance_m >= curve.start_m:
			correction_remaining = 1.35
		active_curve_id = curve.id
		manual_remaining = 0.0
	else:
		active_curve_id = -1
		manual_direction = direction
		manual_remaining = 0.3
		correction_remaining = 0.0
		guide_offset = 0.0

func input_window_m() -> float:
	return maxf(speed_mps, target_speed_mps) * hint_seconds

func change_speed(direction: int, strength: float = VoiceStrength.NORMAL) -> void:
	if direction not in [-1, 1] or off_road or finished: return
	var strong := VoiceStrength.bars(strength) == 3
	if direction < 0:
		boost_remaining = 0.0
		if strong or emergency_braking:
			emergency_braking = true
			target_speed_mps = 0.0
			speed_feedback = tr("I18N_FULL_BRAKE")
			speed_feedback_seconds = 2.0
			return
	else:
		emergency_braking = false
	var before := target_speed_mps
	speed_strength = VoiceStrength.multiplier(strength)
	var minimum := 0.0 if direction < 0 and target_speed_mps < MIN_SPEED else MIN_SPEED
	target_speed_mps = clampf(target_speed_mps + direction * SPEED_STEP * speed_strength, minimum, MAX_SPEED)
	speed_feedback_seconds = 2.0
	if direction > 0 and strong and boost_cooldown <= 0.0:
		boost_remaining = BOOST_SECONDS
		boost_cooldown = BOOST_COOLDOWN
		speed_feedback = tr("I18N_TURBO_BOOST")
		return
	if is_equal_approx(before, target_speed_mps):
		speed_feedback = tr("I18N_SPEED_MAX") if direction > 0 else tr("I18N_SPEED_MIN")
	else:
		speed_feedback = (tr("I18N_SPEED_FASTER") if direction > 0 else tr("I18N_SPEED_SLOWER")) % roundi(target_speed_mps * 3.6)

func keyboard_speed(direction: int, delta: float) -> void:
	if direction not in [-1, 1] or delta <= 0.0 or off_road or finished: return
	speed_strength = 1.0
	if direction > 0:
		emergency_braking = false
		target_speed_mps = minf(MAX_SPEED, maxf(target_speed_mps, speed_mps) + 10.0 * delta)
	else:
		boost_remaining = 0.0
		if emergency_braking: return
		# Brake now, even when the previous voice target was much higher.
		target_speed_mps = maxf(0.0, minf(target_speed_mps, speed_mps) - 18.0 * delta)
	speed_feedback_seconds = 0.0

func effective_target_speed() -> float:
	return minf(MAX_SPEED + BOOST_BONUS, target_speed_mps + BOOST_BONUS) if boost_remaining > 0.0 else target_speed_mps

func step(delta: float) -> void:
	if off_road or finished:
		return
	elapsed_s += delta
	speed_feedback_seconds = maxf(0.0, speed_feedback_seconds - delta)
	boost_remaining = maxf(0.0, boost_remaining - delta)
	boost_cooldown = maxf(0.0, boost_cooldown - delta)
	var desired_speed := effective_target_speed()
	var rate := BOOST_ACCEL if boost_remaining > 0.0 else (18.0 if desired_speed < speed_mps else 10.0) * speed_strength
	if emergency_braking: rate = FULL_BRAKE_DECEL
	# Brakes act on the road. Preserve forward motion until the landing.
	if desired_speed >= speed_mps or track.jump_at(distance_m).is_empty():
		speed_mps = move_toward(speed_mps, desired_speed, rate * delta)
	steering_input = move_toward(steering_input, 0.0, delta * 2.2)
	var rolling_steer := clampf(speed_mps / MIN_SPEED, 0.0, 1.0)
	correction_remaining = maxf(0.0, correction_remaining - delta)
	landing_pulse = maxf(0.0, landing_pulse - delta * 3.0)
	if jump_assist_until > distance_m:
		var target: Dictionary = track.sample(distance_m + 10.0)
		var offset: Vector3 = target.position - position
		var desired := atan2(offset.x, -offset.z)
		var exit_blend := clampf((distance_m - jump_assist_until + 8.0) / 8.0, 0.0, 1.0)
		desired = lerp_angle(desired, target.heading, exit_blend)
		# Scale the lateral correction around the road direction.
		desired = lerp_angle(target.heading, desired, turn_strength)
		heading = rotate_toward(heading, desired, deg_to_rad(65.0) * turn_strength * rolling_steer * delta)
	elif active_curve_id >= 0:
		var curve: Dictionary = track.curves[active_curve_id]
		# A command authorizes only this curve, never the rest of the road.
		if distance_m >= curve.end_m:
			if not completed_ids.has(active_curve_id):
				completed_ids[active_curve_id] = true
				completed_curves += 1
			active_curve_id = -1
			last_command = 0
			guide_offset = 0.0
		elif distance_m >= curve.start_m - 4.0:
			var lookahead := 4.0
			var target_s := distance_m + lookahead
			var target: Dictionary = track.sample(target_s)
			# The car really approaches the outside edge. A fresh tap pulls it inward.
			var entry := smoothstep(curve.start_m + 3.0, curve.start_m + 19.0, target_s)
			var exit := 1.0 - smoothstep(curve.end_m - 23.0, curve.end_m - 7.0, target_s)
			var speed_risk := clampf((speed_mps - 28.0) / 18.0, 0.0, 1.0)
			var edge := 2.35 + speed_risk * 1.1 * clampf(35.0 / curve.radius, 0.8, 1.3)
			if correction_remaining > 0.0:
				# A quiet input pulls partway toward the centre; a loud input
				# can pull a little beyond it, within the road width.
				edge = clampf(lerpf(edge, 0.2, turn_strength), -1.4, 4.2)
			else:
				edge += (1.0 - turn_strength) * 0.6
			var requested_offset: float = -float(curve.turn_sign) * edge * entry * exit
			guide_offset = move_toward(guide_offset, requested_offset, 3.5 * turn_strength * delta)
			var offset: Vector3 = target.position + track.right(target.heading) * guide_offset - position
			var desired := atan2(offset.x, -offset.z)
			var exit_blend := clampf((distance_m - float(curve.end_m) + 8.0) / 8.0, 0.0, 1.0)
			desired = lerp_angle(desired, track.sample(curve.end_m).heading, exit_blend)
			heading = rotate_toward(heading, desired, deg_to_rad(170.0) * turn_strength * rolling_steer * delta)
	elif manual_remaining > 0.0:
		heading += float(manual_direction) * deg_to_rad(25.0) * turn_strength * rolling_steer * minf(delta, manual_remaining)
		manual_remaining = maxf(0.0, manual_remaining - delta)
	position += track.forward(heading) * speed_mps * delta
	var projection: Dictionary = track.project(position, distance_m)
	distance_m = projection.distance_m
	lateral = projection.lateral
	var was_airborne := airborne
	airborne = not track.jump_at(distance_m).is_empty()
	bank = track.bank_at(distance_m)
	position.y = track.flight_height(distance_m) + lateral * tan(bank)
	# Follow the surface in the actual direction of travel, including banking.
	var ahead: Dictionary = track.project(position + track.forward(heading) * 0.4, distance_m)
	var ahead_height: float = track.flight_height(ahead.distance_m) + ahead.lateral * tan(ahead.bank)
	pitch = atan2(ahead_height - position.y, 0.4)
	if was_airborne and not airborne: landing_pulse = 1.0
	var drift_target := 0.0
	if active_curve_id >= 0 and not airborne and speed_mps > 26.0:
		var curve: Dictionary = track.curves[active_curve_id]
		var blend := smoothstep(curve.start_m, curve.start_m + 10.0, distance_m) * (1.0 - smoothstep(curve.end_m - 12.0, curve.end_m, distance_m))
		drift_target = -float(curve.turn_sign) * deg_to_rad(20.0) * clampf((speed_mps - 26.0) / 20.0, 0.0, 1.0) * blend
	drift_angle = lerpf(drift_angle, drift_target, 1.0 - exp(-6.0 * delta))
	# No horizontal snap or lane clamp: a missed turn really leaves the deck.
	if absf(lateral) > 3.2 or projection.gap > 3.2:
		off_road = true
	if distance_m >= track.length_m - 0.5 and absf(lateral) <= 2.2:
		finished = true
