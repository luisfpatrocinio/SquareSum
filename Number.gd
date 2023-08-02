extends Area2D

var radius = 148
onready var my_index = 0
var my_number = 0
onready var my_scale = 0

onready var controller = get_parent()

func _ready() -> void:
	pass


func _process(delta):
	if my_scale < 1:
		my_scale += 0.078
	else:
		my_scale = 1
		
	$CollisionShape2D.scale = Vector2(3 * my_scale, 3 * my_scale)
	
	$Label.text = str(my_number);
	var _n = len(controller.numbersArray)
	var angle = deg2rad(360 / _n * my_index)
	var posx = 480 + cos(angle) * radius
	var posy = 270 + sin(angle) * radius
	global_position = Vector2(posx, posy)
