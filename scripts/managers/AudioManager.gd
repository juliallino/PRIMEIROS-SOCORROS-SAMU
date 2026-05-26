extends Node

@onready var music_player = AudioStreamPlayer.new()
@onready var sfx_player = AudioStreamPlayer.new()
@onready var ambient_player = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(music_player)
	add_child(sfx_player)
	add_child(ambient_player)
	
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	ambient_player.bus = "Ambient"
	
	EventBus.music_change_requested.connect(play_music)
	EventBus.sfx_played.connect(play_sfx)

func play_music(track_path: String) -> void:
	var stream = load(track_path)
	if stream:
		music_player.stream = stream
		music_player.play()

func play_sfx(sfx_path: String) -> void:
	var stream = load(sfx_path)
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func play_ambient(ambient_path: String) -> void:
	var stream = load(ambient_path)
	if stream:
		ambient_player.stream = stream
		ambient_player.play()
