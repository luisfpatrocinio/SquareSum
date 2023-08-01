extends Node

onready var NumberScene = preload("res://Number.tscn")
onready var line = get_node("Area2D");
onready var debugLabel = get_node("Label")
onready var numbersArray =  get_tree().get_nodes_in_group("numbers")



func _ready() -> void:
	print("Spawna")
	for i in range(2 * (randi() % 5)):
		spawn_number(i)
	
func _process(delta: float) -> void:
	var xAxis = Input.get_axis("ui_left", "ui_right");
	line.rotation_degrees += xAxis;
	if line.rotation_degrees > 360: line.rotation_degrees -= 360
	if line.rotation_degrees < 0: line.rotation_degrees += 360
	
	line.rotation_degrees = round(line.rotation_degrees)
	debugLabel.text = str(line.rotation_degrees);
	

	
func spawn_number(x):
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var number = NumberScene.instance()
	add_child(number)
	print(str(number.my_number))
	number.my_number = x
	number.global_position = Vector2(
		randi() % 50,
		randi() % 30
	)
	number.my_index = len(numbersArray)
	print(numbersArray)
	number.add_to_group("numbers")
	print(number.global_position)

	
	
