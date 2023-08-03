extends Node2D

var destinyScene = "res://MainMenu.tscn";
onready var polygon = get_node("Polygon");
var scaleFactor = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	polygon.scale = Vector2(scaleFactor, scaleFactor);

func _process(delta: float) -> void:
	var _spd = 0.050;
	scaleFactor = lerp(scaleFactor, 15, _spd)
	polygon.scale = Vector2(scaleFactor, scaleFactor);
	if (scaleFactor > 14):
		get_tree().change_scene(destinyScene);
		queue_free()
