extends CharacterBody2D

@export var gravity := 981.0
@export var max_fall_speed := 1200.0

@export var move_speed := 200.0
@export var rotate_speed := 2.0
var direction := 1.0 

var input_disabled = true

func _ready():
	var mutant = get_tree().get_root().find_child("Mutant", true, false)
	if mutant:
		mutant.connect("head_detached", _on_head_detached)

func _process(delta):
	if input_disabled:
		return
		
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)

	# Left/right movement + rotation
	if Input.is_action_pressed("move_left"):
		velocity.x = -move_speed
		rotation -= rotate_speed * delta
		direction = -1.0
	elif Input.is_action_pressed("move_right"):
		velocity.x = move_speed
		rotation += rotate_speed * delta
		direction = 1.0
	else:
		velocity.x = 0
	position += velocity * delta
	rotation += direction * rotate_speed * delta

func _physics_process(delta):
	move_and_slide()

func _on_head_detached(new_head):
	if new_head == self:
		input_disabled = false
