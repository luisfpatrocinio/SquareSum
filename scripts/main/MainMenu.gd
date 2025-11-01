## Manages the main menu screen, including navigation, option selection, and scene transitions.
##
## This script is the main controller for the title screen. It dynamically creates menu
## options, handles player input for navigation (keyboard and a custom 'Esplora' controller),
## displays the high score, and manages the fade-in/fade-out transitions. It also spawns
## decorative polygons in the background for visual effect.
extends Node2D

#region Constants
## The cooldown period in frames between directional inputs to prevent excessively fast scrolling.
const INPUT_COOLDOWN = 16
#endregion

#region Scene & Resource Preloads
## The scene for a single, instantiable menu option button.
var optionScene = preload("res://scenes/ui/MenuOption.tscn")
## The scene for the decorative polygons that float in the background.
onready var polygonDeco = preload("res://scenes/game_elements/Polygon.tscn")
#endregion

#region Node References
## Timer used to periodically spawn new decorative polygons.
onready var createPolygonTimer = get_node("CreatePolygonTimer")
## The ColorRect node used for the screen fade-out transition effect.
onready var transAlpha = get_node("CanvasLayer/TransitionFadeOut")
## The AudioStreamPlayer responsible for playing menu sound effects.
onready var audioSFX = get_node("AudioSFX")
## The Label node that displays the player's highest score.
onready var highScoreLabel = get_node("HighScore")
## Reference to the CommControl node for handling custom hardware input.
onready var Esplora = get_node("CommControl")
#endregion

#region State Variables
## A counter to manage the delay between inputs. See [constant INPUT_COOLDOWN].
var inputCooldown: int = -1
## The index of the currently selected menu option in the [member options] array.
var selected: int = 0
## An array containing the instanced menu option nodes.
var options: Array = []
## A flag to disable input while a scene transition is in progress.
var changingScene: bool = false
## A flag used to prevent a crash related to polygon handling.
var success: bool = false
## A flag that is true when the credits screen is being displayed.
var showingCredits: bool = false
## The current alpha (transparency) value of the credits screen.
var creditsAlpha: float = 0.0
#endregion


## Called when the node enters the scene tree for the first time.
##
## This function initializes the main menu. It loads saved data, starts the fade-in
## effect, centers the game window, and dynamically creates the menu buttons. It also
## populates the screen with initial decorative polygons.
func _ready() -> void:
	Global.load_data()
	transAlpha.visible = true
	# Adjust window position
	OS.center_window()
	
	# Create Options
	var _optionsIds: Array = ["start", "credits", "exit"]

	# Remove "exit" option on HTML5 builds
	if OS.get_name() == "HTML5":
		_optionsIds.erase("exit")

	var _spac = 960 / (_optionsIds.size() + 1)
	for i in range(_optionsIds.size()):
		var _op = optionScene.instance()
		_op.no = i;
		_op.global_position = Vector2(_spac + _spac * i, 270)
		_op.optionId = _optionsIds[i];
		get_node("Buttons").add_child(_op)
		options.append(_op)
		
	# Create Decoration Polygons
	for _i in range(5):
		var _pol = polygonDeco.instance()
		_pol.global_position = Vector2(
			randi() % 960,
			randi() % 480
		)
		_pol.controller = self
		add_child(_pol)
		

## Called every frame. 'delta' is the elapsed time since the previous frame.
##
## The main loop handles all real-time logic:
## - Listens for screenshot input.
## - Updates the fade transition alpha.
## - Processes player input for menu navigation and selection.
## - Highlights the currently selected option.
## - Displays and animates the high score label.
## - Manages the visibility of the credits screen.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("take_screenshot"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("user://screenshot" + str(OS.get_ticks_msec() % 1000) + ".png")
		print("Screenshot saved!")
	
	debug()
	# Fade Out Transition
	transAlpha.color.a = lerp(transAlpha.color.a, 0, 0.068)
	
	# Reload Input Cooldown
	if inputCooldown >= 0: inputCooldown -= 1
	
	# Get Input
	var xAxis = Input.get_axis("ui_left", "ui_right")
	if xAxis == 0:
		xAxis = Esplora.get_tilt()
	
	if abs(xAxis) < 0.30:
		xAxis = 0.0
	
	if (xAxis != 0 and inputCooldown < 0 and !changingScene):
		# Handling to prevent the cursor sound from repeating even when the option doesn't change
		var _newSelected: int = selected + int(sign(xAxis))
		if _newSelected != selected:
			Sounds.play_sfx("sfx_menu_click")
			selected = int(clamp(_newSelected, 0, len(options) - 1))
			inputCooldown = INPUT_COOLDOWN
		
	# Highlight selected option
	for option in options:
		option.highlighted = (option.no == selected)
		
	# Confirm Option
	var confirmKey = Input.is_action_just_pressed("ui_accept") or Esplora.get_button_pressed("DOWN")
	if confirmKey and !changingScene:
		var _callback = options[selected].callback
		if _callback.is_valid():
			_callback.call_func()
			Sounds.play_sfx("sfx_confirm")
			changingScene = true
			confirmKey = false
			
	# Show HighScore
	var _greatest_score = Global.data_dict["greatest_score"]
	highScoreLabel.visible = _greatest_score > 0
	highScoreLabel.text = tr("highscore.prefix") + " " + str(_greatest_score)
	var _angle = OS.get_ticks_msec() / 200.0
	highScoreLabel.set_position(Vector2(
	highScoreLabel.get_position().x,
	 highScoreLabel.get_position().y + sin(_angle) * 0.5)
	)
	
	# Show Credits
	get_node("Credits").modulate.a = move_toward(get_node("Credits").modulate.a, int(showingCredits), 0.168)
	get_node("Buttons").visible = !showingCredits
	get_node("HighScore").visible = !showingCredits
	if (showingCredits):
		if confirmKey:
			showingCredits = false
			changingScene = false
			
	# Move title during credits
	get_node("SquareSum").rect_position.y = move_toward(get_node("SquareSum").rect_position.y, 90 - int(showingCredits) * 45, 12)
	

## Called when the [member createPolygonTimer] times out.
##
## Instantiates a new decorative polygon off-screen to the right, which will then
## move across the screen.
func _on_CreatePolygonTimer_timeout() -> void:
	var _pol = polygonDeco.instance()
	_pol.global_position = Vector2(
		960 + 32,
		randi() % 480
	)
	add_child(_pol)

## Contains debug-only functionality.
##
## When the "reset_data" input action is pressed, this function will erase the
## saved game data from the [code]Global[/code] singleton.
func debug() -> void:
	if Input.is_action_just_pressed("reset_data"):
		Global.data_dict = {
		"last_score": 0,
		"greatest_score": 0,
		"times_played": 0
		}
		print("[ Debug ]: Saved data has been deleted!")
