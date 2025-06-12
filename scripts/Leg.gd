extends Node2D

@onready var mesh = $LegMesh
@onready var foot_sprite = $Foot

@export var num_joints := 6
@export var joint_spacing := 16.0
@export var leg_width := 10.0
@export var walk_speed := 5.0
@export var step_length := 10.0
@export var step_lift := 6.0
@export var phase_offset := 0.0  # 👈 Set different values on Leg0, Leg1

var time := 0.0

func _ready():
	mesh.material = null
	mesh.texture = null
	mesh.color = Color("#d5bfaa")

func _process(delta):
	time += delta

	var points = generate_joint_positions()
	var smooth = catmull_rom(points, 10)
	var polygon = build_leg_polygon(smooth)
	mesh.polygon = polygon

	# Move foot sprite to end of the leg
	if smooth.size() >= 2:
		var foot_pos = smooth[-1]
		var prev_pos = smooth[-2]
		var angle = (foot_pos - prev_pos).angle()

		foot_sprite.global_position = mesh.to_global(foot_pos)
		foot_sprite.rotation = angle

func generate_joint_positions() -> Array:
	var joints := []

	for i in range(num_joints):
		var ratio = float(i) / (num_joints - 1)
		var t = time * walk_speed + phase_offset + ratio * 0.5
		var swing = sin(t)
		var x = swing * step_length * ratio  # less motion near hip
		var y = i * joint_spacing - abs(swing) * step_lift * (1.0 - ratio)
		joints.append(Vector2(x, y))
	
	return joints

func catmull_rom(points: Array, subdivisions: int) -> Array:
	if points.size() < 4:
		return points

	var result := []
	for i in range(1, points.size() - 2):
		for j in range(subdivisions):
			var t = float(j) / subdivisions
			var p0 = points[i - 1]
			var p1 = points[i]
			var p2 = points[i + 1]
			var p3 = points[i + 2]
			var point = 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0*p0 - 5.0*p1 + 4.0*p2 - p3) * t * t +
				(-p0 + 3.0*p1 - 3.0*p2 + p3) * t * t * t
			)
			result.append(point)
	result.append(points[-2])
	return result

func build_leg_polygon(points: Array) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var left := []
	var right := []

	var point_count := points.size()
	if point_count < 2:
		return poly

	for i in range(point_count):
		var dir = Vector2.UP
		if i < point_count - 1:
			dir = (points[i + 1] - points[i]).normalized()
		elif i > 0:
			dir = (points[i] - points[i - 1]).normalized()
		var normal = dir.orthogonal() * (leg_width * 0.5)

		var left_pt = points[i] - normal
		var right_pt = points[i] + normal
		left.append(left_pt)
		right.insert(0, right_pt)

	poly.append_array(left)
	poly.append_array(right)
	return poly
