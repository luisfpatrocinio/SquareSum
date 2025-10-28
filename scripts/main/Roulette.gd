## Manages the core gameplay loop, including level generation, player input, and scoring.
##
## This script controls the main game scene. It is responsible for spawning numbers,
## generating the mathematical challenge for each level, handling the rotation of the
## selection bar via player input, and tracking game state such as score, combos,
## and the game over condition. It also dynamically adjusts the game's color palette
## and visual feedback based on player performance and level progression.
extends Node

#region Game Configuration & Constants
## The maximum time in seconds the player has to complete a level.
const MAX_TIME = 15
## The duration in seconds a combo streak remains active before resetting.
const COMBO_TIMER = 6
#endregion

#region Scene & Resource Preloads
## The scene for a single, instantiable number object.
onready var NumberScene = preload("res://scenes/game_elements/Number.tscn")
## The scene for the decorative polygons in the background.
onready var polygonDeco = preload("res://scenes/game_elements/Polygon.tscn")
## The scene for the "+Score" text that appears on successful plays.
onready var scorePlusScene = preload("res://scenes/game_elements/ScorePlus.tscn")
#endregion

#region Node References
# Main Gameplay Elements
onready var Controller = get_parent()
onready var line = get_node("Line")
onready var Esplora = get_parent().get_node("CommControl")
onready var background = get_node("ColorRect")

# Timers
onready var timer = get_node("Timer")
onready var startTimer = get_node("TimerToStart")
onready var createPolygonTimer = get_node("CreatePolygonTimer")
onready var canExitTimer = get_node("canExitTimer")
onready var comboTimer = get_node("ComboTimer")

# UI Labels & Displays
onready var instructionLabel = get_node("InstructionLabel")
onready var barNumberLabel = get_node("BarNumber")
onready var operator1 = get_node("Operator1")
onready var operator2 = get_node("Operator2")
onready var scoreDisplay = get_node("ScoreDisplay")
onready var comboDisplay = get_node("ComboArea")
onready var progressBar = get_node("TimerBar")

# Visual Effects
onready var insideDiamond = line.get_node("Polygon2D_Fundo")
onready var flash = get_node("FlashScreen")
onready var audioSFX = get_node("AudioSFX")
#endregion

#region Game State Variables
## Flag to indicate if the game is over.
var gameOver: bool = false
## Flag to allow the player to exit to the main menu from the game over screen.
var can_exit: bool = false
## Flag to track if player data has been saved after a game over.
var saved: bool = false
## The player's current score.
var score: int = 0
## The current level number, which influences difficulty.
var actualLevel: int = 0
## The current combo multiplier.
var combo: int = 0
## The target sum the player needs to achieve for the current level.
var desired_number: int = 0
## The fixed number displayed on the rotating bar.
var barNumber: int = 0
## The rotational direction of the number ring (1 for clockwise, -1 for counter-clockwise).
var direction: int = 1
## A flag indicating if the current level has been successfully completed.
var success: bool = false
## An array holding references to all number nodes currently in the scene.
var numbersArray: Array = []
## The penalty in seconds applied to the timer for a wrong answer.
var penaltyTimer: int = 3
#endregion

#region UI & Visual State Variables
## The base hue for the game's dynamic color palette. Changes with the level.
var globalColorH: float = 0.0
## The current rotation of the number ring in radians.
var globalAngle: float = 0.0
## A smoothed value of the score for display purposes, preventing jittery text updates.
var score_draw: float = 0.0
## A timer to control the duration of the "wrong answer" visual effect.
var wrong_timer: float = 0.0
## The current value of the timer used for smooth progress bar animation.
var timerValue: float = 0.0
## The angle used for the "pop" animation of the combo display.
var visual_combo_angle: float = 0.0
## The rotation speed of the player-controlled bar.
var barAngSpd: int = 12
## A flag used to enable the fade-in transition after a short delay.
var canFadeTransition: bool = false
#endregion


#region Godot Engine Callbacks
## Initializes the game on node entry.
##
## Sets up the initial game state, increments the total number of games played,
## spawns initial background decorations, and starts the first level by calling [method new_level].
func _ready() -> void:
	randomize()
	Global.data_dict["times_played"] += 1
	get_parent().get_node("CanvasLayer").visible = true
	
	for i in range(10):
		var _pol = createDecoPolygon()
		_pol.global_position = Vector2(randi() % 960 / 5.0 * i / 2.0, randi() % 480)
	
	new_level()
	
		
## Called every frame to process game logic.
##
## This is the main game loop. It handles:
## - UI updates (score, labels, combo display).
## - Game over screen logic.
## - Dynamic color palette updates.
## - Player input for rotating the selection bar.
## - Input for confirming a selection.
## - Checking for correct/incorrect answers and updating game state accordingly.
## - Visual feedback like screen flashes and progress bar animations.
func _process(delta: float) -> void:
	# --- General Updates ---
	if Input.is_action_just_pressed("take_screenshot"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("user://screenshot" + str(OS.get_ticks_msec() % 1000) + ".png")

	# Smoothly animate the score display
	var _diff = score - score_draw
	score_draw = ceil(lerp(score_draw, score, 0.1))

	# --- UI Text Updates ---
	if Global.usingEsplora:
		get_node("TutorialLabel").text = "Incline o controle para movimentar a barra."
	else:
		get_node("TutorialLabel").text = "Use as setas para movimentar a barra."
	get_node("TutorialLabel2").text = "Obtenha a soma desejada!"
	get_node("SwitchWarn").text = "Aperte %s para confirmar!" % ["SWITCH 1" if Global.usingEsplora else "ENTER"]
	
	# Tutorial visibility logic
	var is_tutorial_level = actualLevel <= 1
	timer.paused = is_tutorial_level
	get_node("SwitchWarn").visible = is_tutorial_level and len(line.colliders) > 0
	get_node("TutorialLabel").visible = is_tutorial_level and not len(line.colliders) > 0
	get_node("TutorialLabel2").visible = is_tutorial_level
	scoreDisplay.visible = not is_tutorial_level

	# Hide tutorial labels upon first success
	if success:
		get_node("TutorialLabel").visible = false
		get_node("TutorialLabel2").visible = false
		get_node("SwitchWarn").visible = false

	# --- Game Over Logic ---
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

	# --- Main Gameplay Loop ---
	scoreDisplay.text = str("Pontuação: " + str(int(score_draw)))
	
	# Update color palette based on level and combo "fever"
	globalColorH = fmod(actualLevel * 0.168, 1.0)
	if combo > 3:
		globalColorH = fmod(OS.get_ticks_msec() / 2000.0, 1.0)
		var fever_color = hsv_to_rgb(globalColorH, 1, 0.8)
		comboDisplay.modulate = fever_color
		scoreDisplay.modulate = fever_color
	else:
		comboDisplay.modulate = Color.white
		scoreDisplay.modulate = Color.white
	background.color = hsv_to_rgb(globalColorH, 0.40, 0.80)
	
	# Visual effects timers
	flash.color.a = lerp(flash.color.a, 0, 0.20)
	wrong_timer -= 0.1
	if canFadeTransition:
		var trans = get_parent().get_node("CanvasLayer/TransitionFadeOut")
		trans.color.a = lerp(trans.color.a, 0, 0.068)

	# Handle player input for bar rotation
	var xAxis = Input.get_axis("ui_left", "ui_right")
	var tilt = Esplora.get_tilt()
	var lwr = weakref(line)
	if lwr.get_ref():
		var destAng = line.rotation_degrees
		if not success:
			destAng += xAxis * barAngSpd
			if tilt != 0 and xAxis == 0: destAng = 90 - tilt * 180
			insideDiamond.color = hsv_to_rgb(globalColorH, 1, 0.50)
		else:
			destAng = 0 if line.rotation_degrees < 90 else 180
			insideDiamond.color = hsv_to_rgb(globalColorH, 1, 1)
		line.rotation_degrees = lerp(line.rotation_degrees, destAng, 0.168)
		
	# Handle confirmation input
	var confirmKey = Input.is_action_just_pressed("ui_accept") or Esplora.get_button_pressed("DOWN")
	if confirmKey and not success:
		check_answer()

	# --- UI and Visual Feedback Updates ---
	update_instruction_label()
	update_combo_display()
	update_bar_elements()
	update_bar_color()
	update_highlighted_numbers()
	update_timer_bar()
	
	# Update number ring rotation
	globalAngle += delta * min(0.20 + 0.025 * actualLevel, 0.50) * direction
#endregion


#region Core Gameplay Logic
	## Checks the player's submitted answer and updates the game state.
	## Called when the player presses the confirm button.
func check_answer():
	if not is_instance_valid(line):
		return
		
	if len(line.numbers) != 2: return

	if get_sum(line.numbers) == desired_number:
		# Correct answer
		success = true
		flashScreen()
		timer.start(min(timer.time_left + 5, MAX_TIME))
		timer.paused = true
		startTimer.start()
		
		# Sound and scoring
		var _pitch = min(0.80 + 0.05 * actualLevel, 2)
		Sounds.play_sfx("sfx_confirm", _pitch)
		
		if actualLevel > 1 or Global.data_dict["times_played"] > 1:
			combo += 1
			var score_add = 10 + 10 * (combo - 1)
			score += score_add
			show_score_plus(score_add)
			visual_combo_angle = 200
			comboTimer.start(COMBO_TIMER)
			
		# Clean up non-selected numbers
		for nmb in numbersArray:
			var wr = weakref(nmb)
			if wr.get_ref():
				if !(nmb in line.colliders):
					nmb.queue_free()
				else:
					nmb.succeeded = true
	else:
		# Incorrect answer
		if len(line.colliders) > 0:
			timer.start(max(0.5, timer.time_left - penaltyTimer))
			wrong_timer = 5
			combo = 0
			comboTimer.stop()
			
			var _pitch = rand_range(0.95, 1.05)
			Sounds.play_sfx("sfx_error", _pitch)
			
			# Remove wrongly selected numbers
			for nmb in line.colliders:
				if is_instance_valid(nmb): nmb.queue_free()

## Sets up a new level by clearing old numbers and generating a new challenge.
func new_level():
	success = false
	direction = 1 if randi() % 2 == 0 else -1
	
	# Clear old numbers
	numbersArray = get_tree().get_nodes_in_group("numbers")
	for number in numbersArray:
		if is_instance_valid(number): number.queue_free()
	numbersArray.clear()
	
	# Generate new numbers based on level
	var totalNumbers = 4 + floor(actualLevel / 3.0) * 2
	if actualLevel == 0: totalNumbers = 2
	
	for _i in range(totalNumbers):
		var max_val = min(1 + actualLevel + 2, 8)
		var num_val = 1 + randi() % max_val
		spawn_number(num_val)
		
	actualLevel += 1
	barNumber = generate_bar_number()
	desired_number = generate_desired_number()
	
	timer.paused = false
	timer.start(MAX_TIME)
	
	for _i in range(3): createDecoPolygon()

## Calculates the total sum of numbers in an array, plus the fixed bar number.
func get_sum(array: Array) -> int:
	var acc = barNumber
	for i in array:
		acc += i
	return acc
#endregion


#region Number & Level Generation
## Spawns a single number object in the center of the screen.
func spawn_number(value: int):
	var number = NumberScene.instance()
	add_child(number)
	number.my_number = value
	number.global_position = Vector2(480, 270)
	number.my_index = len(get_tree().get_nodes_in_group("numbers"))
	number.add_to_group("numbers")
	numbersArray.append(number)

## Generates the random number for the rotating bar.
## The range of possible numbers increases with the current level.
func generate_bar_number() -> int:
	var max_val = int(max(3, min(actualLevel, 8)))
	return 1 + randi() % max_val
	
## Generates the target number for the level.
## It randomly picks two generated numbers and adds them to the bar number.
func generate_desired_number() -> int:
	if numbersArray.size() < 2: return 0
	
	var half_size = int(numbersArray.size() / 2.0)
	var rand_index1 = randi() % half_size
	var rand_index2 = rand_index1 + half_size
	
	var number1 = numbersArray[rand_index1]
	var number2 = numbersArray[rand_index2]

	return number1.my_number + number2.my_number + barNumber
#endregion


#region UI & Visual Feedback
## Triggers a brief white flash effect on the screen.
func flashScreen():
	flash.color.a = 1.0

## Instantiates a "+Score" label that floats up from the score display.
func show_score_plus(value: int):
	var scorePlus = scorePlusScene.instance()
	scorePlus.get_node("Label").text = "+" + str(value)
	scorePlus.global_position = Vector2(
		scoreDisplay.rect_position.x + scoreDisplay.rect_size.x - 32,
		scoreDisplay.rect_position.y)
	add_child(scorePlus)
	
## Creates a single decorative polygon and adds it to the scene.
func createDecoPolygon():
	var poly = polygonDeco.instance()
	poly.global_position = Vector2(960 + 32, randi() % 480)
	poly.controller = self
	add_child(poly)
	return poly
	
## Updates the instruction label text (e.g., "= 10?" or "= 10!").
func update_instruction_label():
	if gameOver: return
	instructionLabel.text = "= " + str(desired_number)
	if not success:
		if len(line.colliders) > 0: instructionLabel.text += "?"
	else:
		instructionLabel.text += "!"
		
## Updates the combo display's visibility, text, and animation.
func update_combo_display():
	comboDisplay.visible = combo > 1
	if comboDisplay.visible:
		comboDisplay.get_node("Label").text = "Combo x" + str(combo) + "!"
		# Pop animation
		var angle = deg2rad(visual_combo_angle)
		if visual_combo_angle > 0:
			visual_combo_angle -= 6.168
		elif combo > 3: # "Fever" mode re-triggers animation
			visual_combo_angle = 200
		
		var scale_factor = max(1 + sin(angle), 1)
		comboDisplay.scale = Vector2(scale_factor, scale_factor)
		var alpha = max(sin(visual_combo_angle), 0.75)
		comboDisplay.get_node("Label").modulate.a = alpha

## Updates the position of the bar's number and operator labels.
func update_bar_elements():
	var lwr = weakref(line)
	if not lwr.get_ref(): return
	
	barNumberLabel.text = str(barNumber)
	var line_center = line.global_position - Vector2(16, 16)
	var angle_rad = line.rotation
	
	operator1.rect_position = line_center - Vector2(cos(angle_rad), sin(angle_rad)) * 60
	operator2.rect_position = line_center + Vector2(cos(angle_rad), sin(angle_rad)) * 60

## Updates the color of the bar and its elements based on game state.
func update_bar_color():
	var lwr = weakref(line)
	if not lwr.get_ref(): return
	if len(line.colliders) > 0:
		line.polygon.color = hsv_to_rgb(globalColorH, 0.80, 0.80)
	else:
		line.polygon.color = hsv_to_rgb(globalColorH, 0.80, 0.60)

## Updates which numbers are visually highlighted based on collision with the bar.
func update_highlighted_numbers():
	for nmb in numbersArray:
		if is_instance_valid(nmb): nmb.highlighted = false
	
	var lwr = weakref(line)
	if lwr.get_ref():
		for nmb in line.colliders:
			if is_instance_valid(nmb): nmb.highlighted = true
		line.numbers.clear()
		
## Updates the timer progress bar's value, color, and animation.
func update_timer_bar():
	# Animate bar into view
	var target_x = -90 if actualLevel == 1 else 90
	progressBar.rect_position.x = move_toward(progressBar.rect_position.x, target_x, 16)
	
	# Smoothly update timer value
	timerValue = lerp(timerValue, timer.time_left, 0.1)
	progressBar.get_node("TimerLabel").text = str(int(timerValue))
	progressBar.value = ((timerValue / MAX_TIME)) * 85 + 15
	
	# Animate squares
	progressBar.get_node("RecDown").rotation_degrees = timerValue * 100
	progressBar.get_node("RecUP").rotation_degrees = timerValue * -100
	
	# Update color based on state
	if success:
		progressBar.tint_progress = hsv_to_rgb(globalColorH, 0.8, 0.8)
	elif wrong_timer > 0:
		progressBar.tint_progress = Color.black
	else:
		progressBar.tint_progress = hsv_to_rgb(globalColorH, 0.5, 0.5)

	# Time bar square colors
	var _bigSquare = progressBar.get_node("RecUP");
	_bigSquare.color = hsv_to_rgb(globalColorH, 0.80, 0.50);
	var _smallSquare = progressBar.get_node("RecDown");
	_smallSquare.color = hsv_to_rgb(globalColorH, 0.75, 0.75);
#endregion


#region Utility Functions
## A utility function to convert HSV (Hue, Saturation, Value) color to RGB.
func hsv_to_rgb(h: float, s: float, v: float, a: float = 1.0) -> Color:
	var i = floor(h * 6)
	var f = h * 6 - i
	var p = v * (1 - s)
	var q = v * (1 - f * s)
	var t = v * (1 - (1 - f) * s)
	match int(i) % 6:
		0: return Color(v, t, p, a)
		1: return Color(q, v, p, a)
		2: return Color(p, v, t, a)
		3: return Color(p, q, v, a)
		4: return Color(t, p, v, a)
		5: return Color(v, p, q, a)
	return Color.white
#endregion


#region Signal Callbacks (Timers)
## Called after a correct answer to delay the start of the next level.
func _on_TimerToStart_timeout():
	new_level()

## Called when the main gameplay timer runs out. Ends the game.
func _on_Timer_timeout():
	gameOver = true
	timer.stop()
	# Clean up remaining nodes
	for nmb in numbersArray:
		if is_instance_valid(nmb): nmb.queue_free()
	if is_instance_valid(line): line.queue_free()

## Called periodically to spawn new decorative polygons in the background.
func _on_CreatePolygonTimer_timeout() -> void:
	createDecoPolygon()

## Called once at the start to enable the fade-in transition.
func _on_TransitionTimer_timeout() -> void:
	canFadeTransition = true

## Triggered when the combo window expires. Resets the combo counter.
func _on_ComboTimer_timeout() -> void:
	combo = 0

## Triggered after a delay on the game over screen to allow exiting.
func _on_canExitTimer_timeout():
	var exitWarn = get_node("exitWarn")
	exitWarn.visible = true
	exitWarn.text = "Aperte %s para sair." % ["SWITCH 1" if Global.usingEsplora else "ENTER"]
	can_exit = true
#endregion
