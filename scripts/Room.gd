extends StaticBody2D

#@onready var collision_polygon := $CollisionPolygon2D

# You can expand this with ramps or curves later
#func _ready():
	#var points = [
		#Vector2(-1024, -1024),  # top-left
		#Vector2(1024, -1024),   # top-right
		#Vector2(1024, 1024),    # bottom-right
		#Vector2(-1024, 1024)    # bottom-left
	#]
#
	## Clockwise: inside = solid ✅
	#points.reverse()  # if needed — ensure clockwise order
#
	#collision_polygon.polygon = points
