extends StaticBody2D

@export var room_width := 2048.0
@export var room_height := 1024.0
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

	# OUTER EDGE
	for i in range(arc_resolution + 1):
		var angle = lerp(PI / 2, 3 * PI / 2, float(i) / arc_resolution)
		outer.append(Vector2(-ow2, 0) + Vector2(cos(angle), sin(angle)) * outer_radius)
	# Don't duplicate the top-right point, start from i=1
	for i in range(1, arc_resolution + 1):
		var angle = lerp(-PI / 2, PI / 2, float(i) / arc_resolution)
		outer.append(Vector2(ow2, 0) + Vector2(cos(angle), sin(angle)) * outer_radius)

	# INNER EDGE
	for i in range(arc_resolution + 1):
		var angle = lerp(PI / 2, 3 * PI / 2, float(i) / arc_resolution)
		inner.append(Vector2(-iw2, 0) + Vector2(cos(angle), sin(angle)) * inner_radius)
	# Don't duplicate the top-left point, start from i=1
	for i in range(1, arc_resolution + 1):
		var angle = lerp(-PI / 2, PI / 2, float(i) / arc_resolution)
		inner.append(Vector2(iw2, 0) + Vector2(cos(angle), sin(angle)) * inner_radius)
	inner.reverse()

	var poly = outer + inner

	# Flip Y coordinates (seam is now at top, pinched)
	for i in range(poly.size()):
		poly[i].y = -poly[i].y

	return poly
