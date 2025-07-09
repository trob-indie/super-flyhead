extends Camera2D

@export var mutant_path: NodePath
@export var follow_speed := 5.0  # higher = snappier

var mutant: Node2D
var head: Node2D
var target_node: Node2D
var target_position: Vector2

const PIXEL_SCALE = 4.0

func _ready():
	mutant = get_node(mutant_path)
	mutant.connect("head_detached", _on_head_detached)
	target_node = mutant

func _process(delta):
	if not target_node:
		return

	# Get rounded target position
	var pos = target_node.global_position * PIXEL_SCALE
	pos = pos.round()
	target_position = pos / PIXEL_SCALE

	# Smooth follow using lerp
	var lerped = global_position.lerp(target_position, delta * follow_speed)

	# Snap result to pixel grid
	global_position = (lerped * PIXEL_SCALE).round() / PIXEL_SCALE

func _on_head_detached(new_head, facing_right):
	if new_head:
		target_node = new_head
		mutant.connect("head_reattached", _on_head_reattached)

func _on_head_reattached(node):
	if node == mutant:
		target_node = mutant
