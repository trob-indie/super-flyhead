extends RigidBody2D

@export var max_speed := 4000.0
@export var acceleration := 800.0
@export var gravity := 981.0
@export var slope_boost := 6000.0
@export var boosted_max_speed := 8000.0
@export var boost_duration := 2.0  # in seconds
@export var boost_timer := 0.0
@export var is_speed_boosted := false

var direction := 1.0 
var input_disabled := true
var input_force := Vector2.ZERO  # Moved to be accessible in both functions

func _ready():
	var mutant = get_tree().get_root().find_child("Mutant", true, false)
	if mutant:
		mutant.connect("head_detached", _on_head_detached)

func _physics_process(delta):
	if input_disabled:
		return

	# Handle boost duration countdown
	if is_speed_boosted:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_speed_boosted = false

	# Capture input for use in _integrate_forces
	input_force = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_force.x += 1
	if Input.is_action_pressed("move_left"):
		input_force.x -= 1

	if input_force != Vector2.ZERO:
		input_force = input_force.normalized() * acceleration

	# Apply gravity
	apply_central_force(Vector2(0, gravity))

	var speed_limit = max_speed
	if is_speed_boosted:
		speed_limit = boosted_max_speed
	var vel = linear_velocity
	if abs(vel.x) > speed_limit:
		vel.x = sign(vel.x) * speed_limit
		linear_velocity = vel

#Gets the surface normal
#Computes the tangent vector (the direction of the slope)
#Checks if you're moving with that slope (downhill)
var temp_counter = 0
func _integrate_forces(state):
	temp_counter += 1
	if input_disabled:
		return

	if temp_counter % 25 == 0:
		print(linear_velocity)

	var opposing_normal = Vector2.ZERO
	for i in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(i)
		opposing_normal += contact_normal

		var tangent = Vector2(contact_normal.y, -contact_normal.x).normalized()
		var gravity_dir = Vector2.DOWN
		var slope_alignment = gravity_dir.dot(tangent)
		var slope_velocity = linear_velocity.dot(tangent)

		var is_moving_downward_slope = slope_alignment > 0.1 and slope_velocity > 0
		var is_moving_upward_ceiling_slope = slope_alignment < -0.1 and slope_velocity < 0

		if is_moving_downward_slope or is_moving_upward_ceiling_slope:
			# Boost *along* the slope (tangent), in the same direction as velocity
			var boost_force = tangent * slope_boost * sign(slope_velocity) * abs(slope_alignment)
			apply_central_force(boost_force)
			
			# Temporarily increase max speed
			is_speed_boosted = true
			boost_timer = boost_duration

		# Apply general-purpose sticky force into the surface
		var stick_force = -contact_normal * 6000
		apply_central_force(stick_force)

	# Suppress input if pushing away from surfaces
	if input_force != Vector2.ZERO and opposing_normal != Vector2.ZERO:
		var input_dir = input_force.normalized()
		var normal_dir = opposing_normal.normalized()
		if input_dir.dot(normal_dir) <= 0.4:
			apply_central_force(input_force)

func _on_head_detached(new_head):
	if new_head == self:
		input_disabled = false
