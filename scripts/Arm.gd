extends Node2D

@onready var mesh = $ArmMesh
@onready var hand_sprite = $Hand
@onready var elbow_sprite = $Elbow
@onready var segment_sprites = $SegmentSprites

@export var direction := 1.0 # +1 for left arm, -1 for right arm
var facing_right := true
@export var shoulder_offset := Vector2.ZERO
@export var swing_amplitude := 30.0
@export var swing_height := 12.0
@export var vertical_amplitude := 10.0
@export var arm_length := 40.0

@export var segment_texture: Texture2D
@export var upper_length := 30.0
@export var lower_length := 30.0
@export var joint_spacing := 8.0
@export var hand_target := Vector2(40, 30)
@export var swing_radius := 12.0
@export var swing_speed := 3.0
@export var phase_offset := 0.0
@onready var shoulder_sprite = $Shoulder

var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")

func _process(delta):
	time += delta

	var joints = animate_arms_walk(time)
	draw_arm_mesh(joints)
	update_sprites(joints)

func solve_ik(shoulder: Vector2, target: Vector2, upper_len: float, lower_len: float) -> Array:
	var to_target = target - shoulder
	var dist = clamp(to_target.length(), 0.001, upper_len + lower_len)
	var base_angle = to_target.angle()

	var a = upper_len
	var b = lower_len
	var c = dist

	var angle_elbow = acos(clamp((a * a + b * b - c * c) / (2 * a * b), -1.0, 1.0))
	var angle_shoulder_offset = acos(clamp((a * a + c * c - b * b) / (2 * a * c), -1.0, 1.0))

	var shoulder_angle = base_angle - angle_shoulder_offset
	var elbow_pos = shoulder + Vector2(cos(shoulder_angle), sin(shoulder_angle)) * a
	return [shoulder, elbow_pos, target]

func draw_arm_mesh(points: Array) -> void:
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

	var hand_pos = mesh.to_global(points[2])
	var prev_pos = mesh.to_global(points[1])
	hand_sprite.global_position = hand_pos
	if facing_right:
		hand_sprite.rotation = (hand_pos - prev_pos).angle() - PI / 2
	else:
		var delta = hand_pos - prev_pos
		delta.x *= -1
		hand_sprite.rotation = delta.angle() - PI / 2
	hand_sprite.z_index = z_index + 1
	hand_sprite.z_as_relative = false
	hand_sprite.scale.x = direction

	var elbow_pos = mesh.to_global(Vector2(points[1].x + direction*2.5, points[1].y + 0.5))
	elbow_sprite.global_position = elbow_pos
	elbow_sprite.rotation = 0
	elbow_sprite.z_index = z_index + 1
	elbow_sprite.z_as_relative = false
	
	var shoulder_pos = mesh.to_global(points[0])
	shoulder_sprite.global_position = shoulder_pos
	if facing_right:
		shoulder_sprite.rotation = (elbow_pos - shoulder_pos).angle() - PI / 2
	else:
		var delta = elbow_pos - shoulder_pos
		delta.x *= -1
		shoulder_sprite.rotation = delta.angle() - PI / 2
	shoulder_sprite.z_index = z_index + 1
	shoulder_sprite.z_as_relative = false
	shoulder_sprite.scale.x = -direction

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

	while segment_sprites.get_child_count() < positions.size() - 1:
		var seg = Sprite2D.new()
		seg.texture = segment_texture
		segment_sprites.add_child(seg)

	for i in range(positions.size() - 1):
		var from = positions[i]
		var to = positions[i + 1]
		var seg = segment_sprites.get_child(i) as Sprite2D

		var mid = (from + to) * 0.5
		var dir = (to - from).normalized()
		var length = (to - from).length()

		seg.global_position = mesh.to_global(mid)
		seg.rotation = dir.angle() - PI / 2
		seg.z_index = z_index
		seg.z_as_relative = false
		seg.scale = Vector2(1.0, length / seg.texture.get_height())
		seg.visible = true

	for i in range(positions.size() - 1, segment_sprites.get_child_count()):
		segment_sprites.get_child(i).visible = false

func animate_arms_walk(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset

	var swing = sin(t)
	var swing_x = swing * swing_amplitude
	var swing_y = (1.0 - swing * swing) * vertical_amplitude + arm_length
	var hand = shoulder + Vector2(swing_x, swing_y)

	# Elbow midpoint
	var midpoint = (shoulder + hand) * 0.5

	# Bend strength: 0 when swinging back (swing < 0), -5 when forward (swing > 0)
	var bend_amount = -5.0 * max(swing, 0.0)  # only bends forward
	var arm_direction = (hand - shoulder).normalized()
	var perp = arm_direction.orthogonal()
	var elbow = midpoint + perp * bend_amount

	return [shoulder, elbow, hand]

func animate_arms_flap_wings(time: float) -> Array:
	var shoulder = shoulder_offset
	var swing = sin(time * swing_speed + phase_offset)
	var elbow = shoulder + Vector2(swing * swing_amplitude * direction, 10)
	var hand = elbow + Vector2(30 * direction, 4)
	return [shoulder, elbow, hand]

func animate_arms_double_punch(time: float) -> Array:
	var shoulder = shoulder_offset
	var swing = sin(time * swing_speed + phase_offset)
	var elbow = shoulder + Vector2(-8 * direction + swing * swing_amplitude * direction, 12)
	var hand = elbow + Vector2(30, 0)
	return [shoulder, elbow, hand]

func animate_arms_spicy_run(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)
	var elbow = shoulder + Vector2(swing * swing_amplitude, 12)
	var hand = elbow + Vector2(30 * direction, 0)
	return [shoulder, elbow, hand]

func animate_arms_power_walk(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)
	var elbow = shoulder + Vector2(swing * swing_amplitude, 12)
	var hand = elbow + Vector2(30, 0)
	return [shoulder, elbow, hand]

func animate_arms_big_man(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)
	var dip = (1.0 - pow(swing, 2)) * vertical_amplitude
	var elbow = shoulder + Vector2(swing * swing_amplitude, 12 + dip)
	var hand = elbow + Vector2(5, 20)
	return [shoulder, elbow, hand]
