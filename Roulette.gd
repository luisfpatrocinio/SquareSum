extends Node

onready var line = get_node("Area2D");
onready var debugLabel = get_node("Label")

func _ready() -> void:
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	var xAxis = Input.get_axis("ui_left", "ui_right");
	line.rotation_degrees += xAxis;
	if line.rotation_degrees > 360: line.rotation_degrees -= 360
	if line.rotation_degrees < 0: line.rotation_degrees += 360
	
	line.rotation_degrees = round(line.rotation_degrees)
	debugLabel.text = str(line.rotation_degrees);
	
