extends Node2D

const INPUT_COOLDOWN = 16;
var inputCooldown = -1;
var selected = 0;
var options = [];
var optionScene = preload("res://MenuOption.tscn");
onready var createPolygonTimer = get_node("createPolygonTimer");
onready var polygonDeco = preload("res://Polygon.tscn");
var changingScene = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
		add_child(_pol)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Reload Input Cooldown
	if inputCooldown >= 0: inputCooldown -= 1;
	
	# Get Input
	var xAxis = Input.get_axis("ui_left", "ui_right");
	if (xAxis != 0 and inputCooldown < 0 and !changingScene):
		selected += sign(xAxis);
		selected = clamp(selected, 0, len(options) - 1);
		inputCooldown = INPUT_COOLDOWN;
		
	# Highlight
	for option in options:
		option.highlighted = (option.no == selected);
		
	# Confirm Option
	var confirmKey = Input.is_action_just_pressed("ui_accept");
	if confirmKey and !changingScene:
		var _callback = options[selected].callback;
		if _callback.is_valid():
			_callback.call_func();
			changingScene = true			


func _on_CreatePolygonTimer_timeout() -> void:
	var _pol = polygonDeco.instance();
	_pol.global_position = Vector2(
		960 + 32,
		randi() % 480
	)
	add_child(_pol)
