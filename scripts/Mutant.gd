extends CharacterBody2D

@export var gravity := 800.0  # pixels per second squared
@export var max_fall_speed := 1200.0
@export var move_speed := 100.0

@onready var right_arm = $Visual/Arms/Arm0
@onready var left_arm = $Visual/Arms/Arm1
@onready var right_leg = $Visual/Legs/Leg0
@onready var left_leg = $Visual/Legs/Leg1
@onready var visual = $Visual

var facing_right := true

func _physics_process(delta):
	# Apply gravity	
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		velocity.y = 0.0
	
	var input_left = Input.is_action_pressed("move_left")
	var input_right = Input.is_action_pressed("move_right")
	
	velocity.x = 0.0
	if input_right and not input_left:
		facing_right = true
		velocity.x = move_speed
	elif input_left and not input_right:
		facing_right = false
		velocity.x = -move_speed
	
	visual.scale.x = 1 if facing_right else -1
	
	# Move and slide handles collisions
	move_and_slide()
