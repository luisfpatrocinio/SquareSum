extends Area2D

var radius = 128
onready var my_index = 0
var my_number = randi() % 5 + 1;

onready var controller = get_parent()

func _ready() -> void:
	pass


func _process(delta):
	$Label.text = str(my_number);
	var _n = len(controller.numbersArray) + 1
	var angle = deg2rad(360 / _n * my_index)
	var posx = 480 + cos(angle) * radius
	var posy = 270 + sin(angle) * radius
	global_position = Vector2(posx, posy)
