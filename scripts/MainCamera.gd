extends Camera2D

@export var mutant_path: NodePath
@export var follow_speed := 5.0  # higher = snappier

var mutant: Node2D
var head: Node2D
var target_node: Node2D
var target_position: Vector2

func _ready():
	mutant = get_node(mutant_path)
	mutant.connect("head_detached", _on_head_detached)
	target_node = mutant

func _process(delta):
	if not target_node:
		return

	target_position = target_node.global_position
	global_position = global_position.lerp(target_position, delta * follow_speed)

func _on_head_detached(new_head):
	print("oh shit wat up")
	if new_head:
		target_node = new_head
