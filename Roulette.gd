extends Node

# TODO: Colocar as cores dentro de um "dicionário" e mudar a paleta do jogo seguindo "Distâncias entre as cores"
var globalColorH = 0;

onready var NumberScene = preload("res://Number.tscn")
onready var Controller = get_parent()
onready var line = get_node("Line");
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
onready var audioSFX = get_node("AudioSFX")
onready var progressBar = get_node("TimerBar")
onready var background = get_node("ColorRect")
onready var scoreDisplay = get_node("ScoreDisplay")
onready var canExitTimer = get_node("canExitTimer")
onready var scorePlusScene = preload("res://ScorePlus.tscn") 
onready var gameOverOption = preload("res://MenuOption.tscn")
onready var Esplora = get_parent().get_node("CommControl")

var can_exit = false
var gameOver = false
var tutorial = false

var score = 0;
var direction = 1; # 1 ou -1 --- horario ou anti horario
var penaltyTimer = 3;

const MAX_TIME = 15;

var combo = 0;
onready var comboTimer = get_node("ComboTimer")
onready var comboDisplay = get_node("ComboArea");
const COMBO_TIMER = 6;

var canFadeTransition = false
var saved = false
var barAngSpd = 12;
var numbersArray = []
var desired_number = 0
var actualLevel = 0
onready var timerValue = 0
var barNumber = 2 + randi() % 3
var success = false
onready var globalAngle = 0
var wrong_timer = 0

var visual_combo_angle = 0
var score_draw = 0


func _ready() -> void:
	randomize()
	# Somando 1 ao total de jogos jogados
	Global.data_dict["times_played"] += 1
	# setando o canvasLayer como visível
	get_parent().get_node("CanvasLayer").visible = true
	
	for i in range(10):
		var _pol = createDecoPolygon();
		_pol.global_position = Vector2(
			randi() % 960/5 * i/2,
			randi() % 480
		)
	
	new_level()
	
		
func _process(delta: float) -> void:
	# Aproximando a pontuação:
	if Input.is_action_just_pressed("take_screenshot"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("user://screenshot" + str(OS.get_ticks_msec() % 1000) + ".png")
		print("Screenshot saved!")

	var _diff = score - score_draw
	if abs(_diff) > 5:
		score_draw += 1
	else:
		score_draw = score
	
	
	# Atualizar Textos
	if Global.usingEsplora:
		get_node("TutorialLabel").text 	= "Incline o controle para movimentar a barra.";
	else:
		get_node("TutorialLabel").text 	= "Use as setas para movimentar a barra.";
	get_node("TutorialLabel2").text = "Obtenha a soma desejada!";
	get_node("SwitchWarn").text 	= "Aperte %s para confirmar!" % ["SWITCH 1" if Global.usingEsplora else "ENTER"];
	
	
			
	if actualLevel <= 1:
		timer.paused = true
		get_node("SwitchWarn").visible = len(line.colliders) > 0
		get_node("TutorialLabel").visible = !len(line.colliders) > 0
		get_node("TutorialLabel2").visible = true
		scoreDisplay.visible = false
	else:
		get_node("SwitchWarn").visible = false
		get_node("TutorialLabel").visible = false
		scoreDisplay.visible = true
		get_node("TutorialLabel2").visible = false
		
		
		
		
		
	if gameOver:
		var _timer_started = false
		if canExitTimer.is_stopped(): canExitTimer.start();
		# Acessando arquivos da persistência
		var greatest_score = Global.data_dict["greatest_score"]
		var last_score = Global.data_dict["last_score"]
		var diff = greatest_score - score 
		instructionLabel.text = ""
		Global.data_dict["last_score"] = score
		
		# Declarando os objetos do level invisíveis
		barNumberLabel.visible = false;
		operator1.visible = false;
		operator2.visible = false;
		progressBar.visible = false;
		
		# Setar posição das mensagens finais
		scoreDisplay.text = "Sua pontuação foi de:\n" + str(floor(score_draw))
		scoreDisplay.margin_left = 0;
		scoreDisplay.margin_right = 960;
		scoreDisplay.align = Label.ALIGN_CENTER
		instructionLabel.margin_left = 0
		instructionLabel.margin_right = 960
		scoreDisplay.set_position(Vector2(0, 270 - 24))
		
		instructionLabel.set_position(Vector2(
			0, scoreDisplay.get_position().y + 100))
		instructionLabel.rect_size.x = 960
		
		if score > greatest_score or greatest_score == 0 or diff == 0:
			Global.data_dict["greatest_score"] = score
			instructionLabel.text = "Novo recorde!"
			var _hue = float(OS.get_ticks_msec() / 50 % 100)
			_hue = float(_hue / 100)
			instructionLabel.modulate = hsv_to_rgb(_hue, 1, 1);
		else:
			instructionLabel.text = "Vamos, faltam " + str(diff + 1) + " pontos \n para superar sua maior pontuação!"
		if not saved: Global.save_data(); saved = true
		
	else:
		scoreDisplay.text = str("Pontuação: " + str(score_draw))
		
	# Cor da paleta vai ser alterada conforme o nivel atual
	globalColorH = actualLevel * 0.168;
	
	# Efeito Colorido: FEVER
	if combo > 3:
		globalColorH = float(OS.get_ticks_msec() % 2000)/2000;
		comboDisplay.modulate = hsv_to_rgb(globalColorH, 1, 0.8)
		scoreDisplay.modulate = hsv_to_rgb((globalColorH), 1, 0.8 )	
	else:
		comboDisplay.modulate = Color(1,1,1,1)
		scoreDisplay.modulate = Color(1,1,1,1)
	
	var scoreP = get_node_or_null("ScorePlus")
	if scoreP != null:
		scoreP.modulate = scoreDisplay.modulate
		
	if (globalColorH > 1): globalColorH -= 1;
	background.color = hsv_to_rgb(globalColorH, 0.40, 0.80)
	
	# Atualizar cor do Esplora
#	var _esploraColor = hsv_to_rgb(globalColorH, 1, 1)
#	if success: _esploraColor = hsv_to_rgb(globalColorH, 0, 1)
#	esplora.red = _esploraColor.r;
#	esplora.green = _esploraColor.g;
#	esplora.blue = _esploraColor.b;
	
	# Cores dos quadrados da barra de Tempo
	var _bigSquare = progressBar.get_node("RecUP");
	_bigSquare.color = hsv_to_rgb(globalColorH, 0.80, 0.50);
	var _smallSquare = progressBar.get_node("RecDown");
	_smallSquare.color = hsv_to_rgb(globalColorH, 0.75, 0.75);
	
	# Reduzir Flash
	flash.color.a = lerp(flash.color.a, 0, 0.20);
	
	# Mostrar Pontuação
#	scoreDisplay.text = str(score);
	
	# Tempo de penalidade vai aumentar a cada quatro niveis
	penaltyTimer = 3 + floor(actualLevel / 4) * 1;
	
	wrong_timer -= 0.1
	# Reduzir transparência da transição
	if canFadeTransition:
		var _transAlpha = get_parent().get_node("CanvasLayer/TransitionFadeOut");
		_transAlpha.color.a = lerp(_transAlpha.color.a, 0, 0.068);
	
	# Receber Input do Jogador: Inclinar Barra
	var xAxis = Input.get_axis("ui_left", "ui_right");
	var tilt = Esplora.get_tilt();
	
	# Garantir que a linha existe antes de se rmanu
	var lwr = weakref(line);
	if lwr.get_ref():
		var _destAng = line.rotation_degrees;
		if !success:
			_destAng += xAxis * barAngSpd;
			# Player is tilting
			if tilt != 0 and xAxis == 0:
				_destAng = 90 - tilt * 180;
			insideDiamond.color = hsv_to_rgb(globalColorH, 1, 0.50);
		else:
			_destAng = 0 if line.rotation_degrees < 90 else 180
			insideDiamond.color = hsv_to_rgb(globalColorH, 1, 1);

		line.rotation_degrees = lerp(line.rotation_degrees, _destAng, 0.168)
		
		if line.rotation_degrees > 180: line.rotation_degrees -= 180
		if line.rotation_degrees < 0: line.rotation_degrees += 180
	
#		debugLabel.text = str(line.rotation_degrees);
	
		# Atualizar cor da barra
		if len(line.colliders) > 0:
			line.polygon.color = hsv_to_rgb(globalColorH, 0.80, 0.80)
		else:
			line.polygon.color = hsv_to_rgb(globalColorH, 0.80, 0.60)
	
	# Atualizar Angulo global conforme a dificuldade
	globalAngle += delta * min(0.20 + 0.025 * actualLevel, 0.50) * direction
	if globalAngle > 360: globalAngle -= 360;
	
	# Receber Input do Jogador: Botão de Confirmar
	var confirmKey = Input.is_action_just_pressed("ui_accept") or Esplora.get_button_pressed("DOWN")
#	var confirmKey = Esplora.get_button_pressed("DOWN");
	
#	print("Button Down: " + str(Esplora.BUTTON_DOWN))
	
	if confirmKey and !success:
		if gameOver and can_exit:
			get_tree().change_scene("res://MainMenu.tscn")
			return
		elif confirmKey and gameOver:
			return
		# Checar se está certo
		var _array = line.numbers
		print(" [ level_process ] O valor de line.numbers é: " + str(_array))
		if (len(_array) == 2):
			if get_sum(_array) == desired_number:
				# Vitória
				print(" [ level_process ] Acertou!"); 
				flashScreen();
				var _timeBonus = 5
				# Limitando com que o tempo máximo seja de 15 segundos
				timer.start(min(timer.time_left + _timeBonus, 15))
				timer.paused = true
				startTimer.start()
				success = true
				audioSFX.stream = completedSound;
				audioSFX.pitch_scale = min(0.80 + 0.05 * actualLevel, 2);
				audioSFX.play()
				
				if actualLevel > 1 or Global.data_dict["times_played"] > 1:
					combo += 1;
					var _scoreAdd = 10 + 10 * (combo - 1);
					var scorePlus = scorePlusScene.instance()
					scorePlus.get_node("Label").text = "+" + str(_scoreAdd)
					scorePlus.global_position = Vector2(
						scoreDisplay.rect_position.x + scoreDisplay.rect_size.x - len(str(score)) * 12,
						scoreDisplay.get_position().y)
					
					self.add_child(scorePlus)
					
					print("[ score ] _scoreAdd: " + str(_scoreAdd))
					score += _scoreAdd;
					visual_combo_angle = 200
					comboTimer.start(COMBO_TIMER);
					
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
					print(" [ level_process ] ErRRRRRrrou!")
					var new_time = max(0.5,timer.time_left - penaltyTimer)
					timer.start(new_time)
					wrong_timer = 5
					comboTimer.stop();
					combo = 0;
					
					audioSFX.stream = wrongSound;
					audioSFX.pitch_scale = rand_range(0.95, 1.05);
					audioSFX.play()
					for nmb in numbersArray:
						if nmb in line.colliders:
							var wr = weakref(nmb);
							if wr.get_ref():
								nmb.queue_free()
				
	
	# Exibir Instrução
	if !gameOver: instructionLabel.text = "= " + str(desired_number)
	# Adicionando o ? a cada escolha
	if !success:
		if lwr.get_ref():
			if len(line.colliders) > 0:
				instructionLabel.text += '?'
	else:
			instructionLabel.text += "!"
			
	# Exibir Combo
	
	var _angle = deg2rad(visual_combo_angle)  # ângulo para a escala do combo
	if visual_combo_angle > 0: 
		visual_combo_angle -= 6.168
	else: 
		if combo > 3:
			visual_combo_angle = 200
	comboDisplay.visible = combo > 1
	comboDisplay.get_node("Label").text = "Combo x" + str(combo) + "!";
	var _alpha = max(sin(visual_combo_angle), 0.75)
	comboDisplay.get_node("Label").modulate = Color(1, 1, 1, _alpha);
	if combo > 0:
		comboDisplay.scale = Vector2(
			max(1 + sin(_angle), 1),
			max(1 + sin(_angle), 1)
			)
	# Atualizar texto da barra:
	if lwr.get_ref():
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

	if lwr.get_ref():	
		for nmb in line.colliders:
			var wr = weakref(nmb)
			if wr.get_ref():
				nmb.highlighted = true

		# Redefinir array de números atuais
		line.numbers.clear()
	
	# Reiniciar Scene
	# Reiniciar Scene
	if Input.is_key_pressed(KEY_F1):
		get_tree().change_scene("res://MainMenu.tscn")
	if Input.is_key_pressed(KEY_F3):
		combo += 1
		
	# Atualizar Tempo
	var _diffTime = timer.time_left - timerValue
	if abs(_diffTime) > 0:
		timerValue += _diffTime / 12;
	else:
		timerValue = timer.time_left
	
	
	# Atualizando a barra de acordo com o tempo decorrido
	progressBar.get_node("TimerLabel").text = str(int(timerValue))
	progressBar.value = ((timerValue/MAX_TIME)) * 85 + 15
	
	# Os quadrados giram de acordo com o tempo
	progressBar.get_node("RecDown").rotation_degrees = timerValue * 100
	progressBar.get_node("RecUP").rotation_degrees = timerValue * -100
	
	# Piscando a barra enquanto aumenta o valor:
	if success:
		progressBar.tint_progress = hsv_to_rgb(globalColorH, 0.8, 0.8)
	elif wrong_timer > 0:
		progressBar.tint_progress = hsv_to_rgb(globalColorH, 0, 0)
	else:
		progressBar.tint_progress = hsv_to_rgb(globalColorH, 0.5, 0.5)
	

func spawn_number(x):
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var number = NumberScene.instance()
	add_child(number)
	number.my_number = x
	number.global_position = Vector2(
		480, 270
	)
	print("[ spawn_number ]: Spawnando numero: " + str(number.my_number))
	number.my_index = len(numbersArray)
	number.add_to_group("numbers")


func generate_bar_number():
	# Escolhe um número aleatório entre 1 e 3, caso nos primeiros níveis.
	# Aumentando até 1 a 9 em níveis posteriores.
	var _number = 1 + randi() % int(max(3, min(actualLevel, 8)));
	return _number
	

func generate_desired_number():
	# Obter quantidade de números gerados.
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	var _n = len(numbersArray)
	print("Tamanho do numbersArray: " + str(_n))
	
	# Obter uma soma selecionando um par aleatório.
	var randindex = randi() % (_n / 2)
	var number1 = numbersArray[randindex]
	var randindex2 = randindex + _n / 2
	var number2 = numbersArray[randindex2]
	print("Numeros escolhidos: ")
	print(str(number1.my_index) + " ::: " + str(number1.my_number))
	print(str(number2.my_index) + " ::: " + str(number2.my_number))
	
	# Retornar soma dos números, com o número da barra.
	return number1.my_number + number2.my_number + barNumber
	
	
func new_level():
	print("[ new_level ] Iniciando um novo nível: " + str(actualLevel))
	
	# Direção aleatória:
	var _val = randi() % 2;
	direction = -1 if _val == 0 else 1;
	
	var _transAlpha = get_parent().get_node("CanvasLayer/TransitionFadeOut");
	_transAlpha.color.a = 1;
	
	numbersArray =  get_tree().get_nodes_in_group("numbers")
	for number in numbersArray:
		number.remove_from_group("numbers")
		number.queue_free()
	numbersArray = []
	
	# Número de números que serão criados:
	var totalNumbers = 4 + floor(actualLevel / 3) * 2
	if actualLevel == 0: totalNumbers = 2
	print("[ new_level ] Com " + str(totalNumbers) + " números.")
	
	for _i in range(totalNumbers):
		var _a = 1 + actualLevel + 2;
		_a = min(_a, 8);
		var _maxNumber = 1 + randi() % _a;
		spawn_number(_maxNumber)
		
	actualLevel += 1
	barNumber = generate_bar_number()
	desired_number = generate_desired_number()
	
	timer.paused = false
	timer.start()
	
	success = false
	
	for _i in range(3):
		createDecoPolygon()
	

func get_sum(array):
	var acc = barNumber
	for i in array:
		acc += i
	return acc
	

func flashScreen():
	flash.color.a = 1.0;
		

func hsv_to_rgb(h, s, v, a = 1):
	var r
	var g
	var b

	var i = floor(h * 6)
	var f = h * 6 - i
	var p = v * (1 - s)
	var q = v * (1 - f * s)
	var t = v * (1 - (1 - f) * s)

	match (int(i) % 6):
		0:
			r = v
			g = t
			b = p
		1:
			r = q
			g = v
			b = p
		2:
			r = p
			g = v
			b = t
		3:
			r = p
			g = q
			b = v
		4:
			r = t
			g = p
			b = v
		5:
			r = v
			g = p
			b = q
	return Color(r, g, b, a)


func _on_TimerToStart_timeout():
	print(" [ ont_Timer_toStart_timeout ] Tempo acabou. Começando um novo level.")
	new_level()


func _on_Timer_timeout():
	# Game Over
	print(" [ on_Timer_timeout ] Fim de jogo")
	timer.stop();
	
	# destruir todos os numeros
	for nmb in numbersArray:
		var wr = weakref(nmb)
		if wr.get_ref():
			nmb.queue_free();
	
	var lwr = weakref(line)
	if lwr.get_ref():	
		line.queue_free();
	
	gameOver = true;
		
	

func createDecoPolygon(): 
	var _pol = polygonDeco.instance();
	_pol.global_position = Vector2(
		960 + 32,
		randi() % 480
	)
	_pol.controller = self;
	add_child(_pol)
	return _pol


func _on_CreatePolygonTimer_timeout() -> void:
	createDecoPolygon();


func _on_TransitionTimer_timeout() -> void:
	canFadeTransition = true;


func _on_ComboTimer_timeout() -> void:
	print("[ on_Combo_timeout ] Combo Resetado.")
	combo = 0;


func _on_canExitTimer_timeout():
	print("[ canExitTimer ] Pode sair para o menu principal")
	var exitWarn = get_node("exitWarn")
	exitWarn.visible = true
	can_exit = true
	
