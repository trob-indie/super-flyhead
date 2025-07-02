extends Node2D

@export var animation_state := "idle"

#### BLENDING ####
var previous_state = "idle"
var previous_time := 0.0
var previous_pose: Array = []
var blend_amount := 1.0
var blend_speed := 4.0
#### /BLENDING ####

var current_time = 0.0
var target_time = 0.0

@export var limb_type = "arm"
@export var limb_width = 1.0
# +1 for left limb, -1 for right limb
@export var direction := 1.0
@export var facing_right := true

# Arm-specific
@export var swing_amplitude := 30.0
@export var swing_height := 12.0
@export var vertical_amplitude := 10.0
@export var arm_length := 120.0
@export var hand_target := Vector2(40, 30)
@export var swing_radius := 12.0
@export var swing_speed := 3.0
@export var shoulder_offset := Vector2.ZERO

# Leg-specific
@export var foot_target := Vector2(0, 100)
@export var walk_radius := 8.0
@export var walk_speed := 8.0
@export var upper_length := 30.0
@export var lower_length := 30.0
@export var joint_spacing := 8.0

@export var phase_offset := 0.0

@onready var mesh = $LimbMesh
@onready var fill_sprites = $FillSprites

@export var head_path: NodePath
var head: Node2D

var decapitate_duration = 0.0
var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")
	
	head = get_node(head_path)

func _process(delta):
	time += delta

	var joints = blend_animations(delta)
	draw_limb_mesh(joints)
	fill_sprites.update_sprites(joints, direction, facing_right, limb_width, z_index)

func set_animation_state(state: String):
	if state == animation_state:
		return
	previous_state = animation_state
	previous_time = time
	blend_amount = 0.0
	previous_pose = get_pose_for_state(previous_state, previous_time)
	self.animation_state = state

func animate_limb_walk(time: float) -> Array:
	if limb_type == "arm":
		return animate_arm_walk(time)
	else:
		return animate_leg_walk(time)

func animate_arm_walk(time: float) -> Array:
	var t = time * swing_speed + phase_offset
	var swing = sin(t)
	var swing_x = swing * swing_amplitude
	var swing_y = (1.0 - swing * swing) * vertical_amplitude + arm_length
	var shoulder = shoulder_offset
	var hand = shoulder + Vector2(swing_x, swing_y)
	var midpoint = (shoulder + hand) * 0.5
	var bend_amount = -12.0 * max(swing, 0.0)
	var direction_vec = (hand - shoulder).normalized()
	var perp = direction_vec.orthogonal()
	var elbow = midpoint + perp * bend_amount
	return [shoulder, elbow, hand]

func animate_leg_walk(time: float) -> Array:
	var angle = time * walk_speed + phase_offset
	var foot_offset = Vector2(cos(angle), sin(angle)) * walk_radius
	var animated_target = foot_target + foot_offset
	return solve_ik(Vector2.ZERO, animated_target, upper_length, lower_length)

func animate_limb_idle(time: float) -> Array:
	if limb_type == "arm":
		return animate_arm_idle(time)
	else:
		return animate_leg_idle(time)

func animate_arm_idle(time: float) -> Array: 
	var shoulder = shoulder_offset
	var hand = shoulder + Vector2(0, arm_length + 7.5)
	var elbow = (shoulder + hand) * 0.5
	return [shoulder, elbow, hand]

func animate_leg_idle(time: float) -> Array:
	var origin = Vector2.ZERO
	var target = foot_target
	return solve_ik(origin, target, upper_length, lower_length)

func animate_limb_jump(time: float) -> Array:
	if limb_type == "arm":
		return animate_arm_jump(time)
	else:
		return animate_leg_jump(time)

func animate_arm_jump(time: float) -> Array:
	var shoulder = shoulder_offset
	var hand = shoulder + Vector2(0, arm_length - 10.0)
	var elbow = (shoulder + hand) * 0.5 + Vector2(5 * direction, -5)
	return [shoulder, elbow, hand]

func animate_leg_jump(time: float) -> Array:
	var origin = Vector2.ZERO
	var foot = foot_target + Vector2(0, 0)  # pull legs up slightly
	return solve_ik(origin, foot, upper_length, lower_length)

func animate_limb_collapse(time: float) -> Array:
	if limb_type == "arm":
		return animate_arm_collapse(time)
	else:
		return animate_leg_collapse(time)

func animate_leg_collapse(time: float) -> Array:
	var origin = Vector2.ZERO
	var thigh_dir = Vector2(0, 1)
	
	# move knee forward
	var knee_offset = Vector2(40, -50)
	var shin_dir = Vector2(-0.5, 1).normalized()

	var knee = origin + thigh_dir * upper_length + knee_offset
	var foot = knee + shin_dir * lower_length
	return [origin, knee, foot]

func animate_arm_collapse(time: float) -> Array:
	var shoulder = shoulder_offset
	var hand = shoulder + Vector2(0, arm_length + 7.5)
	var elbow = (shoulder + hand) * 0.5
	return [shoulder, elbow, hand]

func animate_limb_decapitate(time: float) -> Array:
	if limb_type == "arm":
		return animate_arm_decapitate(time)
	else:
		return animate_leg_decapitate(time)

func animate_arm_decapitate(time: float) -> Array:
	var shoulder = shoulder_offset
	var initial_hand = shoulder + Vector2(0, arm_length + 7.5)
	var initial_elbow = (shoulder + initial_hand) * 0.5

	var elbow_action_duration = decapitate_duration * 0.75
	var jerk_action_duration = decapitate_duration * 0.25

	var elbow = initial_elbow
	var hand = initial_hand

	if time <= elbow_action_duration:
		# Phase 1: Rotate arm CCW around elbow
		var progress = clamp(time / elbow_action_duration, 0.0, 1.0)

		var target_elbow = initial_elbow + Vector2(45.0, -10.0)
		elbow = elbow.lerp(target_elbow, progress)

		var initial_vector = initial_hand - elbow
		var initial_angle = initial_vector.angle()
		var total_rotation = -(5.0 * PI / 4.0)
		var angle = initial_angle + total_rotation * progress

		var rotated = initial_vector.length() * Vector2(cos(angle), sin(angle))
		hand = elbow + rotated
	else:
		var initial_vector = hand - elbow
		# Phase 2: Quickly jerk elbow above shoulder, hand above elbow
		var jerk_progress = clamp((time - elbow_action_duration) / jerk_action_duration, 0.0, 1.0)

		# Final positions after rotation phase
		var elbow_rotated_final = initial_elbow + Vector2(45.0, -10.0)
		var final_rotation_angle = initial_vector.angle() - (5.0 * PI / 4.0)
		var hand_rotated_final = elbow_rotated_final + initial_vector.length() * Vector2(cos(final_rotation_angle), sin(final_rotation_angle))

		# Jerk target positions (vertical alignment)
		var jerk_target_elbow = shoulder + Vector2(0, -arm_length * 0.5)
		var jerk_target_hand = shoulder + Vector2(0, -arm_length + 15)

		# Quickly interpolate elbow and hand to vertical alignment above shoulder
		elbow = elbow_rotated_final.lerp(jerk_target_elbow, jerk_progress)
		hand = hand_rotated_final.lerp(jerk_target_hand, jerk_progress)

	return [shoulder, elbow, hand]

func animate_leg_decapitate(time: float) -> Array:
	# currently the same as idle
	var origin = Vector2.ZERO
	var target = foot_target
	return solve_ik(origin, target, upper_length, lower_length)

func solve_ik(origin: Vector2, target: Vector2, upper_len: float, lower_len: float) -> Array:
	var to_target = target - origin
	var dist = clamp(to_target.length(), 0.001, upper_len + lower_len)
	var base_angle = to_target.angle()

	var a = upper_len
	var b = lower_len
	var c = dist

	var angle_knee = acos(clamp((a * a + b * b - c * c) / (2 * a * b), -1.0, 1.0))
	var angle_origin_offset = acos(clamp((a * a + c * c - b * b) / (2 * a * c), -1.0, 1.0))

	var origin_angle = base_angle - angle_origin_offset
	var joint_pos = origin + Vector2(cos(origin_angle), sin(origin_angle)) * a
	return [origin, joint_pos, target]

func draw_limb_mesh(points: Array) -> void:
	var poly := PackedVector2Array()
	if points.size() != 3:
		mesh.polygon = poly
		return

	var left := []
	var right := []

	for i in range(points.size()):
		var dir := Vector2.UP
		if i < points.size() - 1:
			dir = (points[i + 1] - points[i]).normalized()
		elif i > 0:
			dir = (points[i] - points[i - 1]).normalized()
		var normal = dir.orthogonal() * 5.0

		left.append(points[i] - normal)
		right.insert(0, points[i] + normal)

	poly.append_array(left)
	poly.append_array(right)
	mesh.polygon = poly

func set_external_animation_time(anim_time: float, duration: float) -> void:
	time = anim_time
	decapitate_duration = duration

func blend_animations(delta) -> Array:
	if blend_amount < 1.0:
		blend_amount = clamp(blend_amount + delta * blend_speed, 0.0, 1.0)

	var current_pose = get_pose_for_state(animation_state, time)
	var joints = []

	if blend_amount < 1.0:
		if previous_pose.size() != current_pose.size():
			previous_pose = current_pose
		for i in range(current_pose.size()):
			joints.append(previous_pose[i].lerp(current_pose[i], blend_amount))
	else:
		joints = current_pose
	
	return joints


func get_pose_for_state(state: String, t: float) -> Array:
	match state:
		"idle":
			return animate_limb_idle(t)
		"walk", "run":
			return animate_limb_walk(t)
		"collapse":
			return animate_limb_collapse(t)
		"decapitate":
			return animate_limb_decapitate(t)
		"jump":
			return animate_limb_jump(t)
		_:
			return animate_limb_idle(t)

#func animate_arms_flap_wings(time: float) -> Array:
	#var shoulder = shoulder_offset
	#var swing = sin(time * swing_speed + phase_offset)
	#var elbow = shoulder + Vector2(swing * swing_amplitude * direction, 10)
	#var hand = elbow + Vector2(30 * direction, 4)
	#return [shoulder, elbow, hand]
#
#func animate_arms_double_punch(time: float) -> Array:
	#var shoulder = shoulder_offset
	#var swing = sin(time * swing_speed + phase_offset)
	#var elbow = shoulder + Vector2(-8 * direction + swing * swing_amplitude * direction, 12)
	#var hand = elbow + Vector2(30, 0)
	#return [shoulder, elbow, hand]
#
#func animate_arms_spicy_run(time: float) -> Array:
	#var shoulder = shoulder_offset
	#var t = time * swing_speed + phase_offset
	#var swing = sin(t)
	#var elbow = shoulder + Vector2(swing * swing_amplitude, 12)
	#var hand = elbow + Vector2(30 * direction, 0)
	#return [shoulder, elbow, hand]
#
#func animate_arms_power_walk(time: float) -> Array:
	#var shoulder = shoulder_offset
	#var t = time * swing_speed + phase_offset
	#var swing = sin(t)
	#var elbow = shoulder + Vector2(swing * swing_amplitude, 12)
	#var hand = elbow + Vector2(30, 0)
	#return [shoulder, elbow, hand]
#
#func animate_arms_big_man(time: float) -> Array:
	#var shoulder = shoulder_offset
	#var t = time * swing_speed + phase_offset
	#var swing = sin(t)
	#var dip = (1.0 - pow(swing, 2)) * vertical_amplitude
	#var elbow = shoulder + Vector2(swing * swing_amplitude, 12 + dip)
	#var hand = elbow + Vector2(5, 20)
	#return [shoulder, elbow, hand]
