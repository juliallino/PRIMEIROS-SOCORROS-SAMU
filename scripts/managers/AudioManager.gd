extends Node

@onready var music_player = AudioStreamPlayer.new()
@onready var sfx_player = AudioStreamPlayer.new()
@onready var ambient_player = AudioStreamPlayer.new()

var gameplay_players = []

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

func play_ambient(ambient_path: String, fade_in_time: float = 1.0) -> void:
	var stream = load(ambient_path)
	if stream:
		ambient_player.stream = stream
		ambient_player.volume_db = -40
		ambient_player.play()
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", -5.0, fade_in_time) # Volume leve para ser silencioso/atmosférico

func pause_gameplay_audio() -> void:
	# Encontrar todos os AudioStreamPlayers ativos na cena atual (gameplay)
	gameplay_players.clear()
	_find_active_players(get_tree().root, gameplay_players)
	
	for player in gameplay_players:
		if player.playing:
			player.stream_paused = true

func resume_gameplay_audio() -> void:
	for player in gameplay_players:
		if is_instance_valid(player):
			player.stream_paused = false

func stop_all_sounds(exceptions: Array = []) -> void:
	music_player.stop()
	sfx_player.stop()
	ambient_player.stop()
	
	# Parar quaisquer outros AudioStreamPlayers órfãos
	var all_players = []
	_find_active_players(get_tree().root, all_players)
	for player in all_players:
		if is_instance_valid(player) and not player in exceptions:
			player.stop()

func _find_active_players(node: Node, list: Array) -> void:
	for child in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			list.append(child)
		_find_active_players(child, list)
