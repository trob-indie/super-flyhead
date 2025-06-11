extends Node2D

@export var num_legs: int = 2
@export var leg_length: float = 50.0
@export var num_segments: int = 3
@export var segment_spacing: float = 12.0

@export var stride_amplitude: float = 8.0
@export var lift_amplitude: float = 4.0
@export var run_speed: float = 8.0

@export var hip_sprite: Texture2D
@export var foot_sprite: Texture2D
@export var segment_sprite: Texture2D

var time: float = 0.0

func _ready():
	generate_legs()

func generate_legs():
	for child in $Legs.get_children():
		child.queue_free()
	
	for i in range(num_legs):
		var leg = Node2D.new()
		leg.name = "Leg%d" % i

		var offset_x = (i - (num_legs - 1) / 2) * 20
		leg.position = Vector2(offset_x, 0)

		var hip = Sprite2D.new()
		hip.texture = hip_sprite
		hip.position = Vector2(0, 0)
		hip.name = "Hip"
		leg.add_child(hip)

		for j in range(num_segments):
			var segment = Sprite2D.new()
			segment.texture = segment_sprite
			segment.position = Vector2(0, segment_spacing * (j + 1))
			segment.name = "Segment%d" % j
			leg.add_child(segment)

		var foot = Sprite2D.new()
		foot.texture = foot_sprite
		foot.position = Vector2(0, segment_spacing * (num_segments + 1))
		foot.name = "Foot"
		leg.add_child(foot)

		$Legs.add_child(leg)

func _process(delta):
	time += delta
	
	for i in range($Legs.get_child_count()):
		var leg = $Legs.get_child(i) as Node2D
		var phase_offset = PI * i

		# Hip
		if leg.has_node("Hip"):
			var hip = leg.get_node("Hip") as Sprite2D
			hip.position.x = 0
			hip.position.y = sin(time * run_speed + phase_offset) * lift_amplitude * 0.2

		# Segments
		for j in range(num_segments):
			var segment_name = "Segment%d" % j
			if leg.has_node(segment_name):
				var segment = leg.get_node(segment_name) as Sprite2D
				var stride = sin(time * run_speed + phase_offset) * stride_amplitude * (j + 1) / (num_segments + 1)
				var lift = abs(cos(time * run_speed + phase_offset)) * lift_amplitude * (j + 1) / (num_segments + 1)
				segment.position.x = stride
				segment.position.y = segment_spacing * (j + 1) - lift

		# Foot
		if leg.has_node("Foot"):
			var foot = leg.get_node("Foot") as Sprite2D
			var stride = sin(time * run_speed + phase_offset) * stride_amplitude
			var lift = abs(cos(time * run_speed + phase_offset)) * lift_amplitude
			foot.position.x = stride
			foot.position.y = segment_spacing * (num_segments + 1) - lift
