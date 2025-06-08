extends Camera3D

@export var speed := 150.0
@export var mouse_sensitivity := 0.002

var rotation_v := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation_v = clamp(rotation_v - event.relative.y * mouse_sensitivity, -PI / 2, PI / 2)
		rotation.x = rotation_v
	
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"): # ESC to release mouse
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	var move_direction := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		move_direction -= global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		move_direction += global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		move_direction -= global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		move_direction += global_transform.basis.x
	if Input.is_action_pressed("move_up"):
		move_direction += global_transform.basis.y
	if Input.is_action_pressed("move_down"):
		move_direction -= global_transform.basis.y

	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()
		global_position += move_direction * speed * delta
