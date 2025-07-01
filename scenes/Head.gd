extends RigidBody2D

@export var max_speed := 4000.0
@export var acceleration := 1000.0
@export var gravity := 981.0
@export var slope_boost := 6000.0
@export var boosted_max_speed := 8000.0
# in seconds
@export var boost_duration := 2.0

var boost_timer := 0.0
var is_speed_boosted := false
var direction := 1.0
var input_disabled := true
var input_force := Vector2.ZERO

# Path-following variables
@onready var path_follower: PathFollow2D
var endpoint1: Area2D
var endpoint2: Area2D
var is_on_path := false
var path_direction := 1
var path_speed := 0.0
var pending_path_exit_position = null

# in seconds
var endpoint_cooldown_time := 0.5
var endpoint_cooldown_timer := 0.0
var endpoint_collider: CollisionShape2D = null

var is_x_locked := false
var x_lock_position := 0.0
var gateway_y_threshold := 0.0

var can_attach = false
var attach_area = null
signal attempt_reattach

func _ready():
	var mutant = get_tree().get_root().find_child("Mutant", true, false)
	if mutant:
		mutant.connect("head_detached", _on_head_detached)
	
	for area in get_tree().get_nodes_in_group("HeadAttachmentArea"):
		area.connect("body_entered", self._on_area_entered)
		area.connect("body_exited", self._on_area_exited)

func _physics_process(delta):
	if input_disabled:
		return

	if is_on_path:
		_process_path_following(delta)
		return
	
	if pending_path_exit_position != null:
		await get_tree().create_timer(.0001).timeout 
		global_position = pending_path_exit_position
		pending_path_exit_position = null
	
	if is_x_locked and global_position.y >= gateway_y_threshold + 50:
		is_x_locked = false

	# Handle boost duration countdown (currently just for slopes)
	if is_speed_boosted:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_speed_boosted = false

	# Capture input
	input_force = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		input_force.x += 1
	if Input.is_action_pressed("move_left"):
		input_force.x -= 1

	if input_force != Vector2.ZERO:
		input_force = input_force.normalized() * acceleration
		
		if is_x_locked:
			position.x = x_lock_position
			input_force.x = 0.0

		apply_central_force(input_force)

	# Apply gravity
	apply_central_force(Vector2(0, gravity))

	var speed_limit = boosted_max_speed
	if is_speed_boosted:
		speed_limit = max_speed
	var vel = linear_velocity
	if abs(vel.x) > speed_limit:
		vel.x = sign(vel.x) * speed_limit
		linear_velocity = vel
	
	if endpoint_cooldown_timer > 0.0:
		endpoint_cooldown_timer -= delta
		if endpoint_cooldown_timer <= 0.0 and endpoint_collider:
			endpoint_collider.disabled = false
			endpoint_collider = null

func _integrate_forces(state):
	if input_disabled or is_on_path:
		return

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
			var boost_force = tangent * slope_boost * sign(slope_velocity) * abs(slope_alignment)
			apply_central_force(boost_force)
			is_speed_boosted = true
			boost_timer = boost_duration

	# Input suppression if moving into a wall
	if input_force != Vector2.ZERO and opposing_normal != Vector2.ZERO:
		var input_dir = input_force.normalized()
		var normal_dir = opposing_normal.normalized()
		if input_dir.dot(normal_dir) > 0.0:
			input_force = Vector2.ZERO

func _process_path_following(delta):
	if not is_on_path or path_follower == null:
		return

	var curve = path_follower.get_parent().curve
	var curve_length = curve.get_baked_length()
	var t = path_follower.progress
	# Tunable: smaller for tighter curves
	var delta_t = 1.0

	# Safely sample two points to compute tangent
	var p1 = curve.sample(t, true)
	var p2 = curve.sample(t + delta_t * path_direction, true)
	var tangent = (p2 - p1).normalized()

	# Apply gravity along the tangent
	var gravity_along_tangent = Vector2(0, gravity).dot(tangent)
	path_speed += gravity_along_tangent * delta
	path_speed = clamp(path_speed, -boosted_max_speed, boosted_max_speed)

	# Move along the path
	path_follower.progress += path_speed * delta * path_direction
	global_position = path_follower.global_position

	# Exit path if at either end (no velocity applied)
	# You can tighten or loosen this if needed
	const EPSILON := 0.01

	if path_direction == 1 and path_follower.progress_ratio >= 1.0 - EPSILON:
		is_on_path = false
		path_follower.progress_ratio = 1.0
		pending_path_exit_position = path_follower.global_position
		if endpoint2:
			endpoint_collider = endpoint2.get_node_or_null("CollisionShape2D")
			if endpoint_collider:
				endpoint_collider.disabled = true
				endpoint_cooldown_timer = endpoint_cooldown_time
	elif path_direction == -1 and path_follower.progress_ratio <= EPSILON:
		is_on_path = false
		path_follower.progress_ratio = 0.0
		pending_path_exit_position = path_follower.global_position
		if endpoint1:
			endpoint_collider = endpoint1.get_node_or_null("CollisionShape2D")
			if endpoint_collider:
				endpoint_collider.disabled = true
				endpoint_cooldown_timer = endpoint_cooldown_time

func enter_path(path: Path2D, direction: int):
	is_on_path = true
	path_direction = direction

	var follower := path.get_node("PathFollow2D")
	path_follower = follower
	
	endpoint1 = path.get_node("Endpoint1")
	endpoint2 = path.get_node("Endpoint2")

	if direction == 1:
		follower.progress_ratio = 0.0
	else:
		follower.progress_ratio = 1.0

	global_position = follower.global_position
	path_speed = linear_velocity.length()
	linear_velocity = Vector2.ZERO

func _on_head_detached(new_head):
	if new_head == self:
		input_disabled = false

func lock_x_position(y_threshold: float) -> void:
	is_x_locked = true
	x_lock_position = global_position.x
	gateway_y_threshold = y_threshold

func _on_area_entered(body):
	if body==self:
		can_attach=true
		attach_area=body

func _on_area_exited(body):
	if body==self:
		can_attach=false
		attach_area=null

func _input(event):
	if event.is_action_pressed("head") and can_attach and attach_area:
		reattach_to_body(attach_area)

func reattach_to_body(body_node):
	emit_signal("attempt_reattach")
