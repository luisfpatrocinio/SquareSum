extends Polygon2D

onready var vel = rand_range(1.0, 2.0)
var controller = null

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _sc = rand_range(0.50, 2.0)
	scale = Vector2(_sc, _sc)
	pass # Replace with function body.

func _process(_delta: float) -> void:
	var _accel = false;
	if controller != null:
		_accel = controller.success;
		rotation_degrees += int(_accel) * 5
		global_position.x -= 1
	global_position.x -= vel
	rotation_degrees += 2
	if (global_position.x < -32):
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
