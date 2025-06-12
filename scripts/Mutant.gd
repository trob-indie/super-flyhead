extends Node2D

#@export var num_legs: int = 2
#@export var leg_length: float = 50.0
#@export var num_segments: int = 3
#@export var segment_spacing: float = 12.0
#
#@export var stride_amplitude: float = 8.0
#@export var lift_amplitude: float = 4.0
#@export var run_speed: float = 8.0
#
#@export var hip_sprite: Texture2D
#@export var foot_sprite: Texture2D
#@export var segment_sprite: Texture2D
#
#var time: float = 0.0

var segment_shader := preload("res://shaders/segment_blend.gdshader")

func _ready():
	pass

func _process(delta):
	pass
