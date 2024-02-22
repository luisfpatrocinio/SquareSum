extends Sprite

var PORT 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PORT

func move():
	if PORT.get_avaliabe() > 0:
		return 1
