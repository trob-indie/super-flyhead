extends Node2D

@export var tile_texture: Texture2D = preload("res://sprites/environment/padded-room/tile.png")
@export var rows := 10
@export var columns := 12
@export var tile_size := Vector2(128, 128)
@export var base_scale := 1.0
@export var depth_scale := 0.9
@export var perspective_skew := 0.55
@export var horizontal_spacing_multiplier := 1.0  # set to <1.0 to make tiles overlap

func _ready():
	generate_perspective_grid()

func generate_perspective_grid():
	var y_offset = 0.0

	for row in range(rows):
		var inverse_row = rows - row - 1
		var scale = pow(depth_scale, inverse_row)
		var tile_height = tile_size.y * scale * 0.5

		# stack vertically so tiles touch
		if row > 0:
			var prev_inverse_row = rows - row
			var prev_scale = pow(depth_scale, prev_inverse_row)
			var prev_tile_height = tile_size.y * prev_scale * 0.5
			y_offset += (prev_tile_height + tile_height) / 2.0

		# calculate horizontal scale per column and total row width
		var row_width = 0.0
		var col_scales := []
		for col in range(columns):
			var center_offset = col - (columns - 1) / 2.0
			var col_scale = 1.0 - abs(center_offset) / columns * perspective_skew
			var final_scale_x = scale * col_scale
			col_scales.append(final_scale_x)
			row_width += tile_size.x * final_scale_x * horizontal_spacing_multiplier

		var x_start = -row_width / 2.0
		var x_offset = 0.0

		for col in range(columns):
			var col_scale = col_scales[col]

			var tile = Sprite2D.new()
			tile.texture = tile_texture
			tile.scale = Vector2(col_scale, scale * 0.5)
			tile.position = Vector2(
				x_start + x_offset,
				y_offset
			)
			tile.z_index = row
			add_child(tile)

			x_offset += tile_size.x * col_scale * horizontal_spacing_multiplier
