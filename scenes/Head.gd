extends RigidBody2D

@export var max_speed := 1000.0
@export var acceleration := 800.0
@export var gravity := 981.0

var direction := 1.0 

var input_disabled = true

func _ready():
	var mutant = get_tree().get_root().find_child("Mutant", true, false)
	if mutant:
		mutant.connect("head_detached", _on_head_detached)

func _physics_process(delta):
	if input_disabled:
		return
		
	var input_force = Vector2.ZERO

	# Horizontal input
	if Input.is_action_pressed("move_right"):
		input_force.x += 1
	if Input.is_action_pressed("move_left"):
		input_force.x -= 1

	if input_force != Vector2.ZERO:
		# Apply horizontal acceleration
		input_force = input_force.normalized() * acceleration
		apply_central_force(input_force)

	# Apply gravity as constant downward force
	var gravity_force = Vector2(0, gravity)
	apply_central_force(gravity_force)

	# Clamp velocity to max speed (only for horizontal movement)
	var velocity = linear_velocity
	if abs(velocity.x) > max_speed:
		velocity.x = sign(velocity.x) * max_speed
	linear_velocity = velocity

func _on_head_detached(new_head):
	if new_head == self:
		input_disabled = false
