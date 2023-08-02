extends Area2D
onready var parent = get_parent()

var colliders = [];
var numbers = []

func _process(delta):
	colliders = get_overlapping_areas()
	for collider in colliders:
		numbers.append(collider.my_number)
	parent.get_node("Label").text = str(numbers)

