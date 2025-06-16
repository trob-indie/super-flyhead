extends Node2D

@export var animation_state := "idle" # "idle" or "walk"
var blend_amount = 0.0 # controls how much "influence" the walk animation has
@export var blend_speed := 4.0  # How quickly to blend between animations

@export var limb_type = "arm"
@export var direction := 1.0 # +1 for left limb, -1 for right limb
@export var facing_right := true

# Common kinematics and animation params
@export var upper_length := 30.0
@export var lower_length := 30.0
@export var joint_spacing := 8.0

# Arm-specific
@export var swing_amplitude := 30.0
@export var swing_height := 12.0
@export var vertical_amplitude := 10.0
@export var arm_length := 40.0
@export var hand_target := Vector2(40, 30)
@export var swing_radius := 12.0
@export var swing_speed := 3.0
@export var shoulder_offset := Vector2.ZERO

# Leg-specific
@export var foot_target := Vector2(0, 50)
@export var walk_radius := 8.0
@export var walk_speed := 8.0

@export var phase_offset := 0.0

@export var lower_joint_sprite: Texture2D
@onready var lower_joint_sprite_instance = $LowerJoint
@export var middle_joint_sprite: Texture2D
@onready var middle_joint_sprite_instance = $MiddleJoint
@export var upper_joint_sprite: Texture2D
@onready var upper_joint_sprite_instance = $UpperJoint
@onready var mesh = $LimbMesh
@onready var fill_sprites = $FillSprites
@export var fill_texture: Texture2D

var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")
	lower_joint_sprite_instance.texture = lower_joint_sprite
	middle_joint_sprite_instance.texture = middle_joint_sprite
	upper_joint_sprite_instance.texture = upper_joint_sprite

func _process(delta):
	time += delta

	if animation_state == "walk":
		blend_amount = clamp(blend_amount + delta * blend_speed, 0.0, 1.0)
	else:
		blend_amount = clamp(blend_amount - delta * blend_speed, 0.0, 1.0)

	var walk_pose = animate_limb_walk(time)
	var idle_pose = animate_limb_idle(time)

	# Blend each joint between idle and walk
	var joints = []
	for i in range(idle_pose.size()):
		var blended = idle_pose[i].lerp(walk_pose[i], blend_amount)
		joints.append(blended)
	draw_limb_mesh(joints)
	update_sprites(joints)

func animate_limb(time: float) -> Array:
	if animation_state == "walk":
		return animate_limb_walk(time)
	return animate_limb_idle(time)

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
	var bend_amount = -5.0 * max(swing, 0.0)
	var direction_vec = (hand - shoulder).normalized()
	var perp = direction_vec.orthogonal()
	var elbow = midpoint + perp * bend_amount
	return [shoulder, elbow, hand]

func animate_leg_walk(time: float) -> Array:
	var angle = time * walk_speed + phase_offset
	var foot_offset = Vector2(cos(angle), sin(angle)) * walk_radius
	var animated_target = foot_target + foot_offset
	animated_target.x *= direction
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

func update_sprites(points: Array) -> void:
	if points.size() != 3:
		return

	var positions := []
	var from_points = [points[0], points[1]]
	var to_points = [points[1], points[2]]

	for i in range(2):
		var from = from_points[i]
		var to = to_points[i]
		var segment_count = max(1, int((to - from).length() / joint_spacing))

		for j in range(segment_count):
			var t = float(j) / segment_count
			positions.append(from.lerp(to, t))
	positions.append(points[2])

	while fill_sprites.get_child_count() < positions.size() - 1:
		var seg = Sprite2D.new()
		seg.texture = fill_texture
		fill_sprites.add_child(seg)

	for i in range(positions.size() - 1):
		var from = positions[i]
		var to = positions[i + 1]
		var seg = fill_sprites.get_child(i) as Sprite2D
		var mid = (from + to) * 0.5
		var dir = (to - from).normalized()
		var length = (to - from).length()
		seg.global_position = mesh.to_global(mid)
		seg.rotation = dir.angle() - PI / 2
		seg.z_index = z_index
		seg.z_as_relative = false
		seg.scale = Vector2(1.0, length / seg.texture.get_height())
		seg.visible = true

	for i in range(positions.size() - 1, fill_sprites.get_child_count()):
		fill_sprites.get_child(i).visible = false

	if limb_type == "arm":
		update_sprites_arm(points)
	elif limb_type == "leg":
		update_sprites_leg(points)

func update_sprites_arm(points):
	var shoulder_pos = mesh.to_global(points[0])
	var elbow_pos = mesh.to_global(Vector2(points[1].x + direction*2.5, points[1].y + 0.5))
	var hand_pos = mesh.to_global(points[2])
	lower_joint_sprite_instance.global_position = hand_pos
	if facing_right:
		lower_joint_sprite_instance.rotation = (hand_pos - elbow_pos).angle() - PI / 2
	else:
		var delta = hand_pos - elbow_pos
		delta.x *= -1
		lower_joint_sprite_instance.rotation = delta.angle() - PI / 2
	lower_joint_sprite_instance.scale.x = direction
	lower_joint_sprite_instance.z_index = z_index + 1
	lower_joint_sprite_instance.z_as_relative = false

	middle_joint_sprite_instance.global_position = elbow_pos
	middle_joint_sprite_instance.rotation = 0
	middle_joint_sprite_instance.z_index = z_index - 1
	middle_joint_sprite_instance.z_as_relative = false

	if facing_right:
		upper_joint_sprite_instance.rotation = (elbow_pos - shoulder_pos).angle() - PI / 2
	else:
		var delta = elbow_pos - shoulder_pos
		delta.x *= -1
		upper_joint_sprite_instance.rotation = delta.angle() - PI / 2
	upper_joint_sprite_instance.global_position = shoulder_pos
	upper_joint_sprite_instance.z_index = z_index + 1
	upper_joint_sprite_instance.z_as_relative = false
	upper_joint_sprite_instance.scale.x = -direction

func update_sprites_leg(points):
	var knee_pos = mesh.to_global(points[1])
	var foot_pos = mesh.to_global(points[2])
	var prev_pos = mesh.to_global(points[1])
	lower_joint_sprite_instance.global_position = foot_pos
	lower_joint_sprite_instance.rotation = (foot_pos - prev_pos).angle() - PI / 2
	if facing_right:
		lower_joint_sprite_instance.rotation = (foot_pos - prev_pos).angle() - PI / 2
	else:
		var delta = foot_pos - prev_pos
		delta.x *= -1
		lower_joint_sprite_instance.rotation = delta.angle() - PI / 2
	lower_joint_sprite_instance.z_index = z_index + 1
	lower_joint_sprite_instance.z_as_relative = false

	middle_joint_sprite_instance.global_position = knee_pos
	middle_joint_sprite_instance.rotation = 0
	middle_joint_sprite_instance.z_index = z_index + 1
	middle_joint_sprite_instance.z_as_relative = false


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
