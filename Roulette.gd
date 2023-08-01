extends Node

onready var NumberScene = preload("res://Number.tscn")
onready var line = get_node("Area2D");
onready var debugLabel = get_node("Label")
var numbersArray = []
var desired_number = 0



func _ready() -> void:
	randomize()
	print("Spawna")
	for i in range(2 + 2 * (randi() % 5)):
		spawn_number(1 + randi() % 4)
	desired_number = generate_desired_number()
	
	
func _process(delta: float) -> void:
	var xAxis = Input.get_axis("ui_left", "ui_right");
	line.rotation_degrees += xAxis;
	if line.rotation_degrees > 360: line.rotation_degrees -= 360
	if line.rotation_degrees < 0: line.rotation_degrees += 360
	
	line.rotation_degrees = round(line.rotation_degrees)
	debugLabel.text = str(line.rotation_degrees);
	
	$Label2.text = "A soma é:" + str(desired_number)
	
	if Input.is_action_just_pressed("ui_up"):
		get_tree().reload_current_scene()
	

	
func spawn_number(x):
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var number = NumberScene.instance()
	add_child(number)
	number.my_number = x
	number.global_position = Vector2(
		randi() % 50,
		randi() % 30
	)
	print("Spawnando numero: " + str(number.my_number))
	number.my_index = len(numbersArray)
	number.add_to_group("numbers")
	

func generate_desired_number():
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var _n = len(numbersArray)
	print("Tamanho do numbersArray: " + str(_n))
	var randindex = randi() % (_n / 2)
	var number1 = numbersArray[randindex]
	var randindex2 = randindex + _n / 2
	var number2 = numbersArray[randindex2]
	print("Numeros escolhidos: ")
	print(str(number1.my_index) + " ::: " + str(number1.my_number))
	print(str(number2.my_index) + " ::: " + str(number2.my_number))
	return number1.my_number + number2.my_number

