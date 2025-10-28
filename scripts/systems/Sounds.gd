extends Node

# A dictionary to hold all preloaded sound effects and music, indexed by a key.
var sounds = {
	"music_title": preload("res://assets/music/mscTitle.mp3"),
	"music_game": preload("res://assets/music/mscGame.mp3"),
	"sfx_menu_click": preload("res://assets/sfx/menuSelectionClick.wav"),
	"sfx_confirm": preload("res://assets/sfx/pickedCoinEcho.wav"),
	"sfx_error": preload("res://assets/sfx/errorItem.wav"),
	"sfx_phaser": preload("res://assets/sfx/phaserUp5.mp3")
}

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
	# Create and add audio players as children of this singleton.
	# This way, we don't need to add them manually in the scene editor.
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	add_child(sfx_player)

# Plays a music track from the 'sounds' dictionary.
# Music will loop by default.
func play_music(key: String, loop: bool = true):
	if not sounds.has(key):
		print("Sound key not found: ", key)
		return
		
	music_player.stream = sounds[key]
	music_player.play()
	if loop:
		music_player.connect("finished", music_player, "play")
	else:
		if music_player.is_connected("finished", music_player, "play"):
			music_player.disconnect("finished", music_player, "play")

# Plays a sound effect from the 'sounds' dictionary with an optional pitch scale.
func play_sfx(key: String, pitch_scale: float = 1.0):
	if not sounds.has(key):
		print("Sound key not found: ", key)
		return
	
	sfx_player.pitch_scale = pitch_scale
	sfx_player.stream = sounds[key]
	sfx_player.play()
