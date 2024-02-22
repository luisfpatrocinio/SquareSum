extends Node2D

var highlighted = false;
var no = 0;
onready var polygon = get_node("Polygon2D");
onready var label = get_node("Label");
onready var transitionScene = preload("res://Transition.tscn");
var scaleTo = 1;
var myScale = 1;
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
		scaleTo = 2
	else:
		var _angTo = floor(polygon.rotation_degrees / 90) * 90;
		polygon.rotation_degrees = lerp(polygon.rotation_degrees, _angTo, 0.1680);
		polygon.color = Color(0.262745, 0.262745, 0.415686);
		scaleTo = 1
	
	myScale = lerp(myScale, scaleTo, 0.168);
	scale = Vector2(myScale, myScale);
	

func startGame():
	print("Starting...")
	var trans = transitionScene.instance();
	trans.global_position = Vector2(480, 270);
	trans.destinyScene = "res://Level.tscn";
	get_parent().add_child(trans)

func exitGame():
	get_tree().quit()
