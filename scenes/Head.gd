extends RigidBody2D

@export var max_speed := 1000.0
@export var acceleration := 800.0
@export var gravity := 981.0
@export var slope_boost := 3800.0

var direction := 1.0 
var input_disabled := true

func _ready():
	var mutant = get_tree().get_root().find_child("Mutant", true, false)
	if mutant:
		mutant.connect("head_detached", _on_head_detached)

func _physics_process(delta):
	if input_disabled:
		return

	var input_force = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_force.x += 1
	if Input.is_action_pressed("move_left"):
		input_force.x -= 1

	if input_force != Vector2.ZERO:
		input_force = input_force.normalized() * acceleration
		apply_central_force(input_force)

	# Apply gravity
	apply_central_force(Vector2(0, gravity))

	# Only clamp if input is pressed — skip if slope might help
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
		var vel = linear_velocity
		if abs(vel.x) > max_speed:
			vel.x = sign(vel.x) * max_speed
			linear_velocity = vel

#Gets the surface normal
#Computes the tangent vector (the direction of the slope)
#Checks if you're moving with that slope (downhill)
func _integrate_forces(state):
	if input_disabled:
		return
	
	for i in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(i)
		var tangent = Vector2(contact_normal.y, -contact_normal.x).normalized()

		var moving_dir = sign(linear_velocity.x)
		var downhill_alignment = tangent.dot(Vector2.RIGHT * moving_dir)

		if downhill_alignment > 0.1:
			# You're moving in the downhill direction
			var boost_force = tangent * slope_boost * downhill_alignment
			apply_central_force(boost_force)

func _on_head_detached(new_head):
	if new_head == self:
		input_disabled = false
