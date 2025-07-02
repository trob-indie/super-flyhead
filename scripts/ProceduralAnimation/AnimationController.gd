extends Node2D

@onready var arm0 = $Arms/Arm0
@onready var arm1 = $Arms/Arm1
@onready var leg0 = $Legs/Leg0
@onready var leg1 = $Legs/Leg1

var limbs: Array

func _ready():
	limbs = [arm0, arm1, leg0, leg1]

func set_animation_state(state: String) -> void:
	for limb in limbs:
		limb.set_animation_state(state)

func set_animation_state_on_condition(state: String, cond: bool) -> bool:
	if cond:
		for limb in limbs:
			limb.set_animation_state(state)
		return true
	return false

func set_animation_state_with_timer(state: String, sync_time: float, animation_duration: float) -> void:
	for limb in limbs:
		limb.set_animation_state(state)
		limb.set_external_animation_time(sync_time, animation_duration)
