extends Area2D

var radius = 142;
onready var my_index = 0;
onready var my_number = 0;
onready var my_scale = 0;
onready var highlighted = false;
onready var polygon = get_node("Polygon2D")
onready var label = get_node("Label")
onready var controller = get_parent()
onready var succeeded = false;
onready var destroyParticles = preload("res://ExplosionParticles.tscn");
var getSound = preload("res://assets/menuSelectionClick.wav")

var shakeFactor = 3;

func _ready() -> void:
	pass


func _process(delta):
	if my_scale < 1:
		my_scale += 0.078
	else:
		my_scale = 1
		
	$CollisionShape2D.scale = Vector2(3 * my_scale, 3 * my_scale)
	
	label.text = str(my_number);
	var _n = len(controller.numbersArray)
	var angle = deg2rad(360 / _n * my_index) + controller.globalAngle
	var posx = 480 + cos(angle) * radius
	var posy = 270 + sin(angle) * radius
	
	if highlighted:
		posx += randi() % shakeFactor
		posy += randi() % shakeFactor
		polygon.color = Color(0.408,0.761,0.827)
		label.add_color_override("font_color", Color(0.94902, 0.941176, 0.898039, 1.0))
	else:
		polygon.color = Color(0.294,0.502,0.792)
		label.add_color_override("font_color", Color(0.722,0.71,0.725, 1.0))
		
	if succeeded:
		if posx < 480:
			posx = 480 - 140;
		else:
			posx = 480 + 140;
		posy = 270;
	
	var _spd = 5
	var _diffx = global_position.x - posx;
	if abs(_diffx) > _spd:
		global_position.x += _spd * sign(_diffx) * -1
	else:
		global_position.x = posx;
		
	var _diffy = global_position.y - posy;
	if abs(_diffy) > _spd:
		global_position.y += _spd * sign(_diffy) * -1
	else:
		global_position.y = posy;
		
#	global_position = Vector2(posx, posy)


func _on_Area2D2_tree_exiting() -> void:
	var _part = destroyParticles.instance();
	_part.position = global_position;
	_part.rotation = randi() % 360;
	_part.emitting = true;
	get_parent().add_child(_part);
	pass # Replace with function body.


func _on_Area2D2_area_entered(area: Area2D) -> void:
	if !controller.success:
		controller.audio.stream = getSound;
		controller.audio.pitch_scale = rand_range(0.80, 1.20)
		controller.audio.play()
