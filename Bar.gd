extends Area2D
onready var parent = get_parent()
onready var polygon = get_node("Polygon2D")
var colliders = [];
var numbers = [];

func _process(delta):
	colliders = get_overlapping_areas()
	for collider in colliders:
		numbers.append(collider.my_number)
#	parent.debugLabel.text = str(numbers)
