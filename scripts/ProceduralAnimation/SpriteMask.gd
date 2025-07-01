extends Node2D

@export var lower_joint_offset: Vector2 = Vector2(0, 2)
@export var tip_offset: Vector2 = Vector2(0, 0)
@export var lower_joint_angle_offset: float = 0.0
@export var upper_z_index: int = 1
@export var upper_scale_x: float = -1.0
@export var lower_scale_x: float = -1.0
@export var fill_texture: Texture2D
@export var upper_joint_offset: Vector2 = Vector2(0, 0)
@export var bottom_border_shader: Shader
var bottom_border_shader_material: ShaderMaterial

@onready var lower_joint_sprite_instance = get_parent().get_node("LowerJoint")
@onready var middle_joint_sprite_instance = get_parent().get_node("MiddleJoint")
@onready var upper_joint_sprite_instance = get_parent().get_node("UpperJoint")
var lower_joint_sprite: Texture2D
var middle_joint_sprite: Texture2D
var upper_joint_sprite: Texture2D

@onready var mesh = get_parent().get_node("LimbMesh")

func _ready() -> void:
	lower_joint_sprite = lower_joint_sprite_instance.texture
	middle_joint_sprite = middle_joint_sprite_instance.texture
	upper_joint_sprite = upper_joint_sprite_instance.texture
	if bottom_border_shader:
		bottom_border_shader_material = ShaderMaterial.new()
		bottom_border_shader_material.shader = bottom_border_shader

func update_sprites(points: Array, direction: float, facing_right: bool, limb_width: float, z_index: int):
	if points.size() != 3:
		return

	var positions := []
	var from_points = [points[0], points[1]]
	var to_points = [points[1], points[2]]

	for i in range(2):
		var from = from_points[i]
		var to = to_points[i]
		var segment_count = 1

		for j in range(segment_count):
			var t = float(j) / segment_count
			positions.append(from.lerp(to, t))
	positions.append(points[2])

	while self.get_child_count() < positions.size() - 1:
		var seg = Sprite2D.new()
		seg.texture = fill_texture
		self.add_child(seg)

	for i in range(positions.size() - 1):
		var from = positions[i]
		var to = positions[i + 1]
		var seg = self.get_child(i) as Sprite2D
		var mid = (from + to) * 0.5
		var dir = (to - from).normalized()
		var length = (to - from).length()
		seg.global_position = mesh.to_global(mid)
		seg.rotation = dir.angle() - PI / 2
		seg.z_index = z_index
		seg.z_as_relative = false
		seg.scale = Vector2(limb_width, length / seg.texture.get_height())
		seg.visible = true

	for i in range(positions.size() - 1, self.get_child_count()):
		self.get_child(i).visible = false

	if positions.size() > 1:
		var last_sprite = self.get_child(positions.size() - 2) as Sprite2D
		if bottom_border_shader_material:
			last_sprite.material = bottom_border_shader_material
	
	self.update_limb_sprites(points, direction, facing_right, limb_width, z_index)

func update_limb_sprites(points: Array, direction: float, facing_right: bool, limb_width: float, z_index: int):
	var p0 = mesh.to_global(points[0] + Vector2(upper_joint_offset.x * direction, upper_joint_offset.y))
	var p1 = mesh.to_global(points[1])
	var p2 = mesh.to_global(points[2] + tip_offset)
	
	# Lower joint (hand or foot)
	lower_joint_sprite_instance.global_position = p2 + lower_joint_offset
	if facing_right:
		lower_joint_sprite_instance.rotation = (p2 - p1).angle() - PI / 2 + lower_joint_angle_offset
	else:
		var delta = p2 - p1
		delta.x *= -1
		lower_joint_sprite_instance.rotation = delta.angle() - PI / 2 + lower_joint_angle_offset
	lower_joint_sprite_instance.z_index = z_index - 1
	lower_joint_sprite_instance.z_as_relative = false
	lower_joint_sprite_instance.scale.x = lower_scale_x * limb_width

	# Middle joint
	middle_joint_sprite_instance.global_position = p1
	middle_joint_sprite_instance.rotation = 0
	middle_joint_sprite_instance.z_index = z_index - 1
	middle_joint_sprite_instance.z_as_relative = false
	middle_joint_sprite_instance.scale.x = limb_width

	# Upper joint
	if facing_right:
		upper_joint_sprite_instance.rotation = (p1 - p0).angle() - PI / 2
	else:
		var delta = p1 - p0
		delta.x *= -1
		upper_joint_sprite_instance.rotation = delta.angle() - PI / 2
	upper_joint_sprite_instance.global_position = p0
	upper_joint_sprite_instance.z_index = z_index + upper_z_index
	upper_joint_sprite_instance.z_as_relative = false
	upper_joint_sprite_instance.scale.x = upper_scale_x * limb_width
