extends Node2D

var highlighted = false;
var no: int = 0;
var optionId: String = "";
onready var polygon = get_node("Polygon2D");
onready var label = get_node("Label");
onready var transitionScene = preload("res://scenes/ui/Transition.tscn");
var scaleTo = 1;
var myScale = 1;
var callback = funcref(self, "startGame");
export var optionTextKey: String = ""

func _ready() -> void:
	match optionId:
		"start": 
			label.text = tr("menu.start"); 
			callback = funcref(self, "startGame");	
		"credits":
			label.text = tr("menu.credits"); 
			callback = funcref(self, "showCredits");
		"exit":
			label.text = tr("menu.exit"); 
			callback = funcref(self, "exitGame");


func _process(delta: float) -> void:
	# Initialize text
	if label.text == "" or label.text == "optionTextKey":
		label.text = tr(optionTextKey)
		
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
	trans.destinyScene = "res://scenes/main/Level.tscn";
	get_parent().get_parent().add_child(trans)
	
func showCredits():
	get_parent().get_parent().showingCredits = true;
	pass

func exitGame():
	get_tree().quit()
