extends StaticBody2D

@export var room_width := 2240.0
@export var room_height := 992.0
@export var thickness := 128.0 # Thickness of the walkable track band
@export var arc_resolution := 32

func _ready():
	var outer_radius = room_height / 2
	var inner_radius = outer_radius - thickness
	var outer_width = room_width
	var inner_width = room_width - 2 * thickness

	var poly = create_capsule_ring_polygon(
		outer_width, outer_radius, 
		inner_width, inner_radius, 
		arc_resolution
	)
	$CollisionPolygon2D.polygon = poly

func create_capsule_ring_polygon(
	outer_width: float, outer_radius: float,
	inner_width: float, inner_radius: float,
	arc_resolution: int
) -> Array:
	var outer = []
	var inner = []

	var ow2 = outer_width / 2
	var iw2 = inner_width / 2

	var left_arc_top : Vector2
	var right_arc_top : Vector2
	var left_arc_bottom : Vector2
	var right_arc_bottom : Vector2
	var inner_left_bottom : Vector2

	# OUTER EDGE -- left arc (top-left to bottom-left)
	for i in range(arc_resolution + 1):
		var angle = lerp(PI / 2, 3 * PI / 2, float(i) / arc_resolution)
		var pt = Vector2(-ow2, 0) + Vector2(cos(angle), sin(angle)) * outer_radius
		if i == 0:
			left_arc_top = pt
		if i == arc_resolution:
			left_arc_bottom = pt
		outer.append(pt)

	# BOTTOM RECTANGLE SEGMENT (connect bottom-left to bottom-right)
	right_arc_bottom = Vector2(ow2, left_arc_bottom.y)
	outer.append(right_arc_bottom)

	# OUTER EDGE -- right arc (bottom-right to top-right)
	for i in range(1, arc_resolution + 1):
		var angle = lerp(-PI / 2, PI / 2, float(i) / arc_resolution)
		var pt = Vector2(ow2, 0) + Vector2(cos(angle), sin(angle)) * outer_radius
		if i == arc_resolution:
			right_arc_top = pt
		outer.append(pt)

	# TOP RECTANGLE SEGMENT (connect top-right to top-left)
	outer.append(left_arc_top)

	# INNER EDGE -- left arc (top-left to bottom-left, along left endcap, but inner)
	for i in range(arc_resolution + 1):
		var angle = lerp(PI / 2, 3 * PI / 2, float(i) / arc_resolution)
		var pt = Vector2(-iw2, 0) + Vector2(cos(angle), sin(angle)) * inner_radius
		if i == 0:
			inner_left_bottom = pt
		inner.append(pt)

	# INNER EDGE -- right arc (bottom-right to top-right, along right endcap, but inner)
	for i in range(1, arc_resolution + 1):
		var angle = lerp(-PI / 2, PI / 2, float(i) / arc_resolution)
		inner.append(Vector2(iw2, 0) + Vector2(cos(angle), sin(angle)) * inner_radius)

	# ADD bottom-left inner point to form bottom rectangle properly
	inner.append(inner_left_bottom)

	# Reverse so it winds correctly
	inner.reverse()

	var poly = outer + inner
	return poly
