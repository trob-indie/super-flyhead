extends CharacterBody2D

@export var detached_head_scene: PackedScene

@export var gravity := 981.0
@export var max_fall_speed := 1200.0
@export var move_speed := 250.0
@export var jump_force := 500.0

@export var nod_amplitude_deg := 12.0
@export var nod_speed := 8.0

@onready var head = $Visual/Head
@onready var right_arm = $Visual/Arms/Arm0
@onready var left_arm = $Visual/Arms/Arm1
@onready var right_leg = $Visual/Legs/Leg0
@onready var left_leg = $Visual/Legs/Leg1
@onready var visual = $Visual

var facing_right := true
var input_disabled = false
signal head_detached

func _physics_process(delta):
	if input_disabled:
		return
	
	var input_left = Input.is_action_pressed("move_left")
	var input_right = Input.is_action_pressed("move_right")
	var input_jump = Input.is_action_just_pressed("jump")
	var input_head = Input.is_action_just_pressed("head")
	
	if input_head:
		head.visible = false
		if detached_head_scene:
			var new_head = detached_head_scene.instantiate()
			new_head.global_position = head.global_position
			new_head.name = "Head"
			get_tree().root.add_child(new_head)
			input_disabled = true
			emit_signal("head_detached", new_head)
		

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		if input_jump:
			velocity.y = -jump_force

	# Horizontal movement
	velocity.x = 0.0
	if input_right and not input_left:
		facing_right = true
		velocity.x = move_speed
	elif input_left and not input_right:
		facing_right = false
		velocity.x = -move_speed

	visual.scale.x = 1 if facing_right else -1

	# Update limbs
	for limb in [right_arm, left_arm, right_leg, left_leg]:
		limb.facing_right = facing_right
		if not is_on_floor():
			limb.animation_state = "jump"
		elif velocity.x != 0:
			limb.animation_state = "walk"
		else:
			limb.animation_state = "idle"

	move_and_slide()

var time := 0.0
func _process(delta):
	if input_disabled:
		return
	
	time += delta
	
	if right_leg.animation_state != "walk" and left_leg.animation_state != "walk":
		head.rotation = lerp(head.rotation, 0.0, delta * 8.0)
		return

	# Sample foot phases
	var phase0 = sin(time * nod_speed + right_leg.phase_offset + PI)
	var phase1 = sin(time * nod_speed + left_leg.phase_offset + PI)

	# Combine: pick the deeper "impact"
	var impact = min(phase0, phase1)
	var nod_amount = max(0.0, -impact)
	var target_rotation = deg_to_rad(nod_amplitude_deg) * nod_amount
	head.rotation = lerp(head.rotation, target_rotation, delta * 8.0)
