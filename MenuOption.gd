extends Node2D

var highlighted = false;
var no = 0;
onready var polygon = get_node("Polygon2D");
onready var label = get_node("Label");
var callback = funcref(self, "startGame");

func _ready() -> void:
	match no:
		0: 
			label.text = "Iniciar"; 
			callback = funcref(self, "startGame");
#		1:
#			label.text = "Tutorial";			
		1:
			label.text = "Sair";
			callback = funcref(self, "exitGame");


func _process(delta: float) -> void:
	if highlighted:
		polygon.rotation_degrees += 64 * delta;
		if polygon.rotation_degrees > 360: polygon.rotation_degrees -= 360;
		polygon.color = Color(0.94902, 0.941176, 0.898039);
	else:
		var _angTo = floor(polygon.rotation_degrees / 90) * 90;
		polygon.rotation_degrees = lerp(polygon.rotation_degrees, _angTo, 0.1680);
		polygon.color = Color(0.262745, 0.262745, 0.415686);
		

func startGame():
	get_tree().change_scene("res://Level.tscn");
	

func exitGame():
	get_tree().quit()
