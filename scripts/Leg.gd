extends Node2D

@onready var mesh = $LegMesh
@onready var knee_sprite = $Knee
@onready var foot_sprite = $Foot
@onready var segment_sprites = $SegmentSprites
@export var segment_texture: Texture2D

@export var direction := 1.0 # +1 = right, -1 = left
var facing_right := true
@export var upper_length := 25.0
@export var lower_length := 25.0
@export var leg_width := 1.0
@export var foot_target := Vector2(0, 50)
@export var walk_radius := 8.0
@export var walk_speed := 8.0
@export var phase_offset := 0.0
@export var joint_spacing := 8.0

var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")

func _process(delta):
	time += delta
	
	# Animate foot target in a small circle, mirrored by direction
	var angle = time * walk_speed + phase_offset
	var foot_offset = Vector2(cos(angle), sin(angle)) * walk_radius
	var animated_target = foot_target + foot_offset
	animated_target.x *= direction

	var joints = solve_ik(Vector2.ZERO, animated_target, upper_length, lower_length)
	draw_leg_mesh(joints)
	update_sprites(joints)

func solve_ik(hip: Vector2, target: Vector2, upper_len: float, lower_len: float) -> Array:
	var to_target = target - hip
	var dist = clamp(to_target.length(), 0.001, upper_len + lower_len)
	var base_angle = to_target.angle()

	var a = upper_len
	var b = lower_len
	var c = dist

	# Law of Cosines
	var angle_knee = acos(clamp((a * a + b * b - c * c) / (2 * a * b), -1.0, 1.0))
	var angle_hip_offset = acos(clamp((a * a + c * c - b * b) / (2 * a * c), -1.0, 1.0))

	var hip_angle = base_angle - angle_hip_offset
	var knee_pos = hip + Vector2(cos(hip_angle), sin(hip_angle)) * a
	return [hip, knee_pos, target]

func draw_leg_mesh(points: Array) -> void:
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
		var normal = dir.orthogonal() * (leg_width * 0.5)

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

	# Break each bone into enough segments based on distance and joint spacing
	for i in range(2):  # Hip→Knee and Knee→Foot
		var from = from_points[i]
		var to = to_points[i]
		var segment_count = max(1, int((to - from).length() / joint_spacing))

		for j in range(segment_count):
			var t = float(j) / segment_count
			var pos = from.lerp(to, t)
			positions.append(pos)

	# Add final point (just before the foot)
	positions.append(points[2])

	# Ensure enough sprites
	while segment_sprites.get_child_count() < positions.size() - 1:
		var seg = Sprite2D.new()
		seg.texture = segment_texture
		segment_sprites.add_child(seg)

	# Update sprites along the segments
	for i in range(positions.size() - 1):
		var from = positions[i]
		var to = positions[i + 1]
		var seg = segment_sprites.get_child(i) as Sprite2D

		var pos = (from + to) * 0.5
		var dir = (to - from).normalized()
		var length = (to - from).length()

		seg.global_position = mesh.to_global(pos)
		seg.rotation = dir.angle() - PI / 2
		seg.z_index = z_index
		seg.z_as_relative = false
		seg.visible = true

		# Optional: stretch the sprite vertically to fill the space
		seg.scale = Vector2(1.0, length / seg.texture.get_height())

	# Hide extras
	for i in range(positions.size() - 1, segment_sprites.get_child_count()):
		segment_sprites.get_child(i).visible = false

	# Update foot sprite
	var foot_pos = mesh.to_global(points[2])
	var prev_pos = mesh.to_global(points[1])
	foot_sprite.global_position = foot_pos
	foot_sprite.rotation = (foot_pos - prev_pos).angle() - PI / 2
	if facing_right:
		foot_sprite.rotation = (foot_pos - prev_pos).angle() - PI / 2
	else:
		var delta = foot_pos - prev_pos
		delta.x *= -1
		foot_sprite.rotation = delta.angle() - PI / 2
	foot_sprite.z_index = z_index + 1
	foot_sprite.z_as_relative = false

	# Position knee
	var knee_pos = mesh.to_global(points[1])
	knee_sprite.global_position = knee_pos
	knee_sprite.rotation = 0
	knee_sprite.z_index = z_index + 1
	knee_sprite.z_as_relative = false
