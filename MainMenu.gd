extends Node2D

const INPUT_COOLDOWN = 8;
var inputCooldown = -1;
var selected = 0;
var options = [];
var optionScene = preload("res://MenuOption.tscn");
onready var createPolygonTimer = get_node("createPolygonTimer");
onready var polygonDeco = preload("res://Polygon.tscn");
var changingScene = false;
var success = false; # Essa variável existe apenas para não crashar os polygons.
onready var transAlpha = get_node("CanvasLayer/TransitionFadeOut");

onready var audioSFX = get_node("AudioSFX");
var cursorSnd = preload("res://assets/menuSelectionClick.wav")
var confirmSnd = preload("res://assets/pickedCoinEcho.wav")

onready var highScoreLabel = get_node("HighScore")

onready var Esplora = get_node("CommControl")

func playSFX(snd):
	audioSFX.stream = snd
	audioSFX.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.load_data()
	transAlpha.visible = true
	# Ajustar posição da janela
	OS.center_window()
	
	# Create Options
	var _optionsNmb = 2;
	var _spac = 960 / (_optionsNmb + 1);
	for i in range(_optionsNmb):
		var _op = optionScene.instance();
		_op.global_position = Vector2(_spac + _spac * i, 270);
		_op.no = i
		add_child(_op);
		options.append(_op);
		
	# Create Decoration Polygons
	for _i in range(5):
		var _pol = polygonDeco.instance();
		_pol.global_position = Vector2(
			randi() % 960,
			randi() % 480
		)
		_pol.controller = self;
		add_child(_pol)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("take_screenshot"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("user://screenshot" + str(OS.get_ticks_msec() % 1000) + ".png")
		print("Screenshot saved!")
	
	debug()
	# Fade Out Transition
	transAlpha.color.a = lerp(transAlpha.color.a, 0, 0.068);
	
	# Reload Input Cooldown
	if inputCooldown >= 0: inputCooldown -= 1;
	
	# Get Input
	var xAxis = Input.get_axis("ui_left", "ui_right");
	if xAxis == 0:
		xAxis = Esplora.get_tilt();
	
	if abs(xAxis) < 0.30:
		xAxis = 0.0;
	
	if (xAxis != 0 and inputCooldown < 0 and !changingScene):
		# Tratamento para evitar que o som de cursor se repita mesmo quando não mudar a opção
		var _newSelected = selected + sign(xAxis);
		if _newSelected != selected:
			playSFX(cursorSnd)
			selected = clamp(_newSelected, 0, len(options) - 1);
			inputCooldown = INPUT_COOLDOWN;
		
	# Highlight
	for option in options:
		option.highlighted = (option.no == selected);
		
	print(Esplora.get_tilt())
		
	# Confirm Option
	var confirmKey = Input.is_action_just_pressed("ui_accept") or Esplora.get_button_pressed("DOWN");
	if confirmKey and !changingScene:
		var _callback = options[selected].callback;
		if _callback.is_valid():
			_callback.call_func();
			playSFX(confirmSnd)
			changingScene = true
			
	# Show HighScore
	var _greatest_score = Global.data_dict["greatest_score"]
	highScoreLabel.visible = _greatest_score > 0
	highScoreLabel.text = "MAIOR PONTUAÇÃO: " + str(_greatest_score)
	var _angle = OS.get_ticks_msec() / 200
	highScoreLabel.set_position(Vector2(
			highScoreLabel.get_position().x,
			 highScoreLabel.get_position().y + sin(_angle) * 0.5)
			)
	

func _on_CreatePolygonTimer_timeout() -> void:
	var _pol = polygonDeco.instance();
	_pol.global_position = Vector2(
		960 + 32,
		randi() % 480
	)
	add_child(_pol)
	
func debug():
	if Input.is_action_just_pressed("reset_data"):
		Global.data_dict = {
		"last_score": 0,
		"greatest_score": 0,
		"times_played": 0
		}
		print("[ Debug ]: Dados salvos apagados!")
