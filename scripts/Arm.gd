extends Node2D

@onready var mesh = $ArmMesh
@onready var hand_sprite = $Hand
@onready var elbow_sprite = $Elbow
@onready var segment_sprites = $SegmentSprites
@export var direction := 1.0 # +1 for left arm, -1 for right arm
@export var shoulder_offset := Vector2.ZERO
@export var swing_amplitude := 30.0  # How far the arm swings (pixels)
@export var swing_height := 12.0     # Vertical arc offset
@export var vertical_amplitude := 10.0  # tweak this for more or less bounce

@export var segment_texture: Texture2D
@export var upper_length := 30.0
@export var lower_length := 30.0
@export var joint_spacing := 8.0
@export var hand_target := Vector2(40, 30)
@export var swing_radius := 12.0
@export var swing_speed := 3.0
@export var phase_offset := 0.0

var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")

func _process(delta):
	time += delta
	
	var joints = animate_arms_run(time)
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
		var normal = dir.orthogonal() * (5.0)  # arm_width = 10

		left.append(points[i] - normal)
		right.insert(0, points[i] + normal)

	poly.append_array(left)
	poly.append_array(right)
	mesh.polygon = poly

func update_sprites(points: Array) -> void:
	if points.size() != 3:
		return

	# Hand
	var hand_pos = mesh.to_global(points[2])
	var prev_pos = mesh.to_global(points[1])
	hand_sprite.global_position = hand_pos
	hand_sprite.rotation = (hand_pos - prev_pos).angle() - PI / 2

	# Elbow (static rotation)
	var elbow_pos = mesh.to_global(points[1])
	elbow_sprite.global_position = elbow_pos
	elbow_sprite.rotation = 0
	elbow_sprite.z_index = z_index + 1
	elbow_sprite.z_as_relative = false

	# Segment coverage
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

func animate_arms_run(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)

	# Arc-shaped dip (elbow drops downward in middle of swing only)
	var dip = (1.0 - pow(swing, 2)) * vertical_amplitude

	var elbow_offset = Vector2(
		swing * swing_amplitude,
		12 + dip
	)
	var elbow = shoulder + elbow_offset

	# Hand stays in front of elbow
	var hand = elbow + Vector2(5, 20)

	return [shoulder, elbow, hand]

func animate_arms_flap_wings(time: float) -> Array:
	var shoulder = shoulder_offset  # fixed point
	var swing = sin(time * swing_speed + phase_offset)

	# Move elbow in a horizontal arc
	var elbow_x = swing * swing_amplitude * direction
	var elbow_y = 10  # vertical distance below shoulder (tweak as needed)
	var elbow = shoulder + Vector2(elbow_x, elbow_y)

	# Hand in front of elbow, slightly down
	var hand_offset = Vector2(30 * direction, 4)
	var hand = elbow + hand_offset

	var joints = [shoulder, elbow, hand]
	return joints

func animate_arms_double_punch(time: float) -> Array:
	var shoulder = shoulder_offset

	# Elbow swings side-to-side under and behind the shoulder
	var swing = sin(time * swing_speed + phase_offset)
	var elbow_offset = Vector2(-8 * direction + swing * swing_amplitude * direction, 12)
	var elbow = shoulder + elbow_offset

	# Hand is horizontally in front of elbow
	var hand_offset = Vector2(30, 0)
	var hand = elbow + hand_offset

	return [shoulder, elbow, hand]

func animate_arms_spicy_run(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)

	# Elbow swings left-right from the shoulder, no direction applied
	var elbow_offset = Vector2(swing * swing_amplitude, 12)
	var elbow = shoulder + elbow_offset

	# Hand always in front of elbow, but mirrored per arm
	var hand = elbow + Vector2(30 * direction, 0)

	return [shoulder, elbow, hand]

func animate_arms_power_walk(time: float) -> Array:
	var shoulder = shoulder_offset
	var t = time * swing_speed + phase_offset
	var swing = sin(t)

	# Elbow swings left-right from the shoulder, no direction applied
	var elbow_offset = Vector2(swing * swing_amplitude, 12)
	var elbow = shoulder + elbow_offset

	# Hand always in front of elbow, but mirrored per arm
	var hand = elbow + Vector2(30, 0)

	return [shoulder, elbow, hand]
