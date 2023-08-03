extends Node

onready var NumberScene = preload("res://Number.tscn")
onready var Controller = get_parent()
onready var line = get_node("Area2D");
onready var debugLabel = get_node("DebugLabel")
onready var instructionLabel = get_node("InstructionLabel")
onready var timer = get_node("Timer")
onready var startTimer = get_node("TimerToStart")
onready var timerLabel = get_node("TimerLabel")
onready var barNumberLabel = get_node("BarNumber")
onready var operator1 = get_node("Operator1")
onready var operator2 = get_node("Operator2")
onready var insideDiamond = line.get_node("Polygon2D_Fundo")
onready var completedSound = preload("res://assets/pickedCoinEcho.wav")
onready var wrongSound = preload("res://assets/errorItem.wav")
onready var createPolygonTimer = get_node("createPolygonTimer");
onready var polygonDeco = preload("res://Polygon.tscn");
onready var flash = get_node("FlashScreen");
onready var audio = get_node("Audio")
onready var progressBar = get_node("TextureProgress")

var barAngSpd = 12
var numbersArray = []
var desired_number = 0
var actualLevel = 0
onready var timerValue = 0
var barNumber = 2 + randi() % 3
var success = false
onready var globalAngle = 0

const MAX_TIME = 15;

func _ready() -> void:
	# Ajustar posição da janela
	OS.window_position = Vector2(32, 32)
	randomize()
	
	for _i in range(5):
		var _pol = polygonDeco.instance();
		_pol.global_position = Vector2(
			randi() % 960,
			randi() % 480
		)
		add_child(_pol)
	
	new_level()
	
		
func _process(delta: float) -> void:
	# Receber Input do Jogador: Inclinar Barra
	var xAxis = Input.get_axis("ui_left", "ui_right");
	var _destAng = line.rotation_degrees;
	if !success:
		_destAng += xAxis * barAngSpd;
		insideDiamond.color = Color(0.262745, 0.262745, 0.415686);
	else:
		_destAng = 0 if line.rotation_degrees < 90 else 180
		insideDiamond.color = Color(0.94902, 0.941176, 0.898039);
	
	line.rotation_degrees = lerp(line.rotation_degrees, _destAng, 0.168)
		
	if line.rotation_degrees > 180: line.rotation_degrees -= 180
	if line.rotation_degrees < 0: line.rotation_degrees += 180
#	line.rotation_degrees = round(line.rotation_degrees)
	debugLabel.text = str(line.rotation_degrees);
	
	# Reduzir Flash
	flash.color.a = lerp(flash.color.a, 0, 0.20);
	
	# Atualizar cor da barra
	if len(line.colliders) > 0:
		line.polygon.color = Color(0.408,0.761,0.827)
	else:
		line.polygon.color = Color(0.294,0.502,0.792)
	
	# Atualizar Angulo global
	globalAngle += delta * 0.20
	if globalAngle > 360: globalAngle -= 360;
	
	# Receber Input do Jogador: Botão de Confirmar
	var confirmKey = Input.is_action_just_pressed("ui_accept");
	if confirmKey and !success:
		# Checar se está certo
		var _array = line.numbers
		print("O valor de line.numbers é: " + str(_array))
		if get_sum(_array) == desired_number:
			# Vitória
			print("Acertou!"); 
			flashScreen();
			var _timeBonus = 5
			timer.start(min(timer.time_left + _timeBonus, MAX_TIME))
			timer.paused = true
			startTimer.start()
			success = true
			audio.stream = completedSound;
			audio.pitch_scale = min(0.80 + 0.05 * actualLevel, 2);
			audio.play()
			
			# Deletar numeros errados
			for nmb in numbersArray:
				var wr = weakref(nmb)
				if wr.get_ref():
					if !(nmb in line.colliders):
						nmb.queue_free()
					else:
						nmb.succeeded = true
		else:
			if len(line.colliders) > 0:
				# Resultado Errado
				print("ErRRRRRrrou!")
				audio.stream = wrongSound;
				audio.pitch_scale = rand_range(0.95, 1.05);
				audio.play()
				for nmb in numbersArray:
					if nmb in line.colliders:
						nmb.queue_free()
				
	
	# Exibir Instrução
	instructionLabel.text = "A soma desejada é: " + str(desired_number)
	
	# Atualizar texto da barra:
	barNumberLabel.text = str(barNumber)
	var _lx = line.global_position.x - 16;
	var _ly = line.global_position.y - 16;
	operator1.rect_position = Vector2(
		_lx - cos(deg2rad(line.rotation_degrees)) * 60,
		_ly - sin(deg2rad(line.rotation_degrees)) * 60
	)
	operator2.rect_position = Vector2(
		_lx + cos(deg2rad(line.rotation_degrees)) * 60,
		_ly + sin(deg2rad(line.rotation_degrees)) * 60
	)
	
	# Highlighted collided numbers:
	for nmb in numbersArray:
		var wr = weakref(nmb)
		if wr.get_ref():
			nmb.highlighted = false;

	for nmb in line.colliders:
		var wr = weakref(nmb)
		if wr.get_ref():
			nmb.highlighted = true

	# Redefinir array de números atuais
	line.numbers.clear()
	
	# Reiniciar Scene
	if Input.is_action_just_pressed("ui_up"):
		get_tree().reload_current_scene()
		
	# Tremer Barra
	if Input.is_action_pressed("ui_down"):
		line.global_position.x = 480 + randi() % 12;
		line.global_position.y = 270 + randi() % 12;
	else: 
		line.global_position.x = 480 
		line.global_position.y = 270 
		
	# Atualizar Tempo
	var _diff = timer.time_left - timerValue
	if abs(_diff) > 0:
		timerValue += _diff / 10
	else:
		timerValue = timer.time_left
	
	timerValue = ceil(timerValue * 10) / 10; 
	progressBar.value = 100 * timerValue / MAX_TIME
	progressBar.get_node("TimerLabel").text = str(timerValue)
	

func spawn_number(x):
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var number = NumberScene.instance()
	add_child(number)
	number.my_number = x
	number.global_position = Vector2(
		480, 270
	)
	print("Spawnando numero: " + str(number.my_number))
	number.my_index = len(numbersArray)
	number.add_to_group("numbers")


func generate_bar_number():
	return 2 + randi() % 4;
	

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
	return number1.my_number + number2.my_number + barNumber
	
	
func new_level():
	print("Iniciando um novo nível: " + str(actualLevel))
	
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	for number in numbersArray:
		number.remove_from_group("numbers")
		number.queue_free()
	numbersArray = []
	
	var totalNumbers = 4 + floor(actualLevel / 3) * 2
	print("Com " + str(totalNumbers) + " bolotas.")
	for _i in range(totalNumbers):
		spawn_number(1 + randi() % 8)
	actualLevel += 1
	barNumber = generate_bar_number()
	desired_number = generate_desired_number()
	
	timer.paused = false
	timer.start()
	
	success = false
	

func get_sum(array):
	var acc = barNumber
	for i in array:
		acc += i
	return acc
	

func flashScreen():
	flash.color.a = 1.0;
		

func _on_TimerToStart_timeout():
	print("Tempo acabou. Começando um novo level.")
	new_level()


func _on_Timer_timeout():
	# Game Over
	print("Fim de jogo")
	get_tree().reload_current_scene()
	pass # Replace with function body.


func _on_CreatePolygonTimer_timeout() -> void:
	var _pol = polygonDeco.instance();
	_pol.global_position = Vector2(
		960 + 32,
		randi() % 480
	)
	add_child(_pol)
	pass # Replace with function body.
