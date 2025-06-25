extends StaticBody2D

@onready var path: Path2D = $Path2D
@onready var collision: CollisionPolygon2D = $CollisionPolygon2D
@onready var gateway: Area2D = $Gateway  # Optional — set this if using a static gateway

@export var depth := 100.0         # How far to extend downward from the curve
@export var resolution := 32       # Number of samples for curve smoothness

func _ready():
	if not path or not path.curve:
		push_error("Missing Path2D or its Curve2D.")
		return

	if not collision:
		push_error("Missing CollisionPolygon2D.")
		return

	var curve := path.curve
	var polygon := PackedVector2Array()
	var length := curve.get_baked_length()

	# Sample the top edge of the ramp
	for i in range(resolution + 1):
		var d = i / float(resolution) * length
		var point = curve.sample_baked(d)
		polygon.append(point)

	# Sample the bottom edge (reversed), offset downward
	for i in range(resolution, -1, -1):
		var d = i / float(resolution) * length
		var point = curve.sample_baked(d)
		point.y += depth
		polygon.append(point)

	collision.polygon = polygon

	if gateway and not gateway.is_connected("body_entered", Callable(self, "_on_gateway_body_entered")):
		gateway.body_entered.connect(_on_gateway_body_entered)

func _on_gateway_body_entered(body):
	if body.name == "Head":
		body.lock_x_position(gateway.global_position.y)
