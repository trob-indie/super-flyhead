extends CharacterBody2D

@export var detached_head_scene: PackedScene

@export var gravity := 981.0
@export var max_fall_speed := 1200.0
@export var move_speed := 250.0
@export var jump_force := 500.0

@export var nod_amplitude_deg := 12.0
@export var nod_speed := 8.0

@onready var collider = $CollisionShape2D
@onready var collider_shape = collider.shape as RectangleShape2D
var default_collider_height := 339.0
var collapsed_collider_height := 175.0
var collider_blend := 1.0
var collider_blend_speed := 5.0
var should_collapse := false

@onready var head = $Visual/Head
@onready var right_arm = $Visual/Arms/Arm0
@onready var left_arm = $Visual/Arms/Arm1
@onready var right_leg = $Visual/Legs/Leg0
@onready var left_leg = $Visual/Legs/Leg1
@onready var limbs = [right_arm, left_arm, right_leg, left_leg]
@onready var visual = $Visual

var facing_right := true
var input_disabled = false

var decap_duration = 0.75
var decap_timer = 0.0
var decap_anim_time = 0.0

var detached_head = null
var can_reattach = false

signal head_detached
signal head_reattached

var detach_cooldown := 0.0

func _physics_process(delta):
	detach_cooldown = max(detach_cooldown - delta, 0.0)

	apply_gravity(delta)
	collapse_collider(delta)

	if input_disabled:
		decap_anim_time += delta
		wait_for_decap_to_collapse_transition(delta)
		for limb in [right_arm, left_arm, right_leg, left_leg]:
			if limb.animation_state == "decapitate":
				limb.set_external_animation_time(decap_anim_time, decap_duration)
		move_and_slide()
		return

	var input_left = Input.is_action_pressed("move_left")
	var input_right = Input.is_action_pressed("move_right")
	var input_jump = Input.is_action_just_pressed("jump")
	var input_head = Input.is_action_just_pressed("head")

	if input_head and head.visible and detach_cooldown <= 0.0:
		input_disabled = true
		decap_timer = decap_duration
		decap_anim_time = 0.0 
		
		visual.set_animation_state_with_timer("decapitate", 0.0, 0.0)
		return
	
	if input_jump and is_on_floor():
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
	for limb in limbs:
		limb.facing_right = facing_right
	
	if visual.set_animation_state_on_condition("jump", not is_on_floor()):
		pass
	elif visual.set_animation_state_on_condition("walk", velocity.x != 0):
		pass
	else:
		visual.set_animation_state("idle")

	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

func collapse_collider(delta):
	if should_collapse:
		collider_blend = max(collider_blend - delta * collider_blend_speed, 0.0)
	else:
		collider_blend = min(collider_blend + delta * collider_blend_speed, 1.0)

	# Blend height and update shape
	var height = lerp(collapsed_collider_height, default_collider_height, collider_blend)
	collider_shape.size.y = height

func wait_for_decap_to_collapse_transition(delta):
	if decap_timer > 0.0:
		decap_timer -= delta
	elif decap_timer <= 0.0 and head.visible:
		decap_timer = 0.0
		should_collapse = true
		head.visible = false
		detached_head = detached_head_scene.instantiate()
		detached_head.connect("attempt_reattach", Callable(self, "_on_head_attempt_reattach"))
		detached_head.global_position = head.global_position
		detached_head.name = "Head"
		get_tree().root.add_child(detached_head)
		emit_signal("head_detached", detached_head)
		# Enable head reattachment
		visual.set_animation_state("collapse")

func _on_head_attempt_reattach():
	if detached_head:
		reattach_head()

func reattach_head():
	if detached_head:
		detached_head.queue_free()
		detached_head = null
	head.visible = true
	should_collapse = false
	input_disabled = false
	visual.set_animation_state_with_timer("idle", 0.0, 0.0)
	detach_cooldown = 0.2
	emit_signal("head_reattached", self)

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
