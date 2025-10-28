extends Node2D

var alpha = 2
onready var label = get_node("Label")


func _process(_delta):
	if alpha > 0:
		 alpha -= 0.05
	else:
		queue_free()
	label.modulate = Color(1, 1, 1, alpha)
	
	global_position.y -= 0.666  + 0.3 * alpha

