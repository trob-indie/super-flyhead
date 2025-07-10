extends Node2D

@export var tile_texture: Texture2D = preload("res://sprites/environment/padded-room/tile.png")
@export var tile_shader: ShaderMaterial = preload("res://shaders/shiny.tres")
@export var rows := 3
@export var columns := 34
@export var tile_size := Vector2(96, 96)
@export var base_scale := 1.0
@export var depth_scale := 0.96
@export var perspective_skew := 0.3
@export var horizontal_spacing_multiplier := 1.0
@export var y_scale_near := 0.60
@export var y_scale_far := 0.42
@export var skew_amount := 1.0
@export var vertical_spacing_factor := 1.0
@export var row_width_near := 1.02
@export var row_width_far := 1.02
@export var flip_vertical := false # NEW: set true for ceiling

var mm_instance: MultiMeshInstance2D
var camera: Camera2D

func _ready():
	camera = get_tree().get_root().find_child("Camera2D", true, false)
	mm_instance = generate_multimesh_tiles()

func _process(delta):
	if mm_instance and mm_instance.material is ShaderMaterial:
		var shader_mat := mm_instance.material as ShaderMaterial
		var light_world_pos = Vector2(camera.global_position.x, camera.global_position.y - 300.0)
		shader_mat.set_shader_parameter("light_position", light_world_pos)

func generate_multimesh_tiles() -> MultiMeshInstance2D:
	var mesh := QuadMesh.new()
	mesh.size = tile_size
	
	var material := tile_shader.duplicate()
	material.set_shader_parameter("texture_albedo", tile_texture)

	var mm_instance = MultiMeshInstance2D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = mesh
	mm.instance_count = rows * columns
	mm_instance.multimesh = mm
	mm_instance.material = material
	add_child(mm_instance)

	var col_scale_factors := []
	for col in range(columns):
		var center_offset = col - (columns - 1) / 2.0
		var normalized_offset = abs(center_offset) / ((columns - 1) / 2.0)
		var base_col_scale = 1.0 - normalized_offset * perspective_skew
		col_scale_factors.append(base_col_scale)

	var y_offset = 0.0
	var idx = 0

	for row in range(rows):
		var effective_row = row if flip_vertical else (rows - row - 1)
		var next_row = (row + 1) if flip_vertical else (rows - row)

		var row_scale = pow(depth_scale, effective_row)
		var row_ratio = float(effective_row) / (rows - 1)
		var y_scale = lerp(y_scale_near, y_scale_far, row_ratio)
		var tile_height = tile_size.y * row_scale * y_scale

		if row > 0:
			var prev_row_ratio = float(next_row) / (rows - 1)
			var prev_y_scale = lerp(y_scale_near, y_scale_far, prev_row_ratio)
			var avg_scaled_height = tile_size.y * ((y_scale + prev_y_scale) / 2.0)
			y_offset += avg_scaled_height * vertical_spacing_factor

		var width_factor = lerp(row_width_near, row_width_far, row_ratio)
		var row_width = 0.0
		var col_scales := []
		for col in range(columns):
			var col_scale = row_scale * col_scale_factors[col] * width_factor
			col_scales.append(col_scale)
			row_width += tile_size.x * col_scale * horizontal_spacing_multiplier

		var x_start = -row_width / 2.0
		var x_offset = 0.0

		for col in range(columns):
			var col_scale = col_scales[col]
			var center_offset = col - (columns - 1) / 2.0
			var normalized_offset = center_offset / ((columns - 1) / 2.0)
			var skew = -normalized_offset * skew_amount

			var transform := Transform2D(
				Vector2(col_scale, 0),
				Vector2(skew, -y_scale * (-1.0 if flip_vertical else 1.0)),
				Vector2(
					x_start + x_offset + (tile_size.x * col_scale * horizontal_spacing_multiplier) / 2.0,
					y_offset
				)
			)

			mm.set_instance_transform_2d(idx, transform)
			idx += 1

			x_offset += tile_size.x * col_scale * horizontal_spacing_multiplier

	return mm_instance
