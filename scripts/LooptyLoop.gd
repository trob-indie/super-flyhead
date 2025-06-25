extends Path2D

@onready var endpoint1 = $Endpoint1
@onready var endpoint2 = $Endpoint2

func _ready():
	endpoint1.body_entered.connect(_on_endpoint1_entered)
	endpoint2.body_entered.connect(_on_endpoint2_entered)

func _on_endpoint1_entered(body):
	if body.name == "Head":
		body.enter_path(self, 1)  # Forward

func _on_endpoint2_entered(body):
	if body.name == "Head":
		body.enter_path(self, -1)  # Backward
