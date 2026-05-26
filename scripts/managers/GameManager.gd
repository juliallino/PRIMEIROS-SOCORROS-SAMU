extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	CUTSCENE,
	GAME_OVER
}

var current_state: GameState = GameState.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.phase_started.connect(_on_phase_started)
	EventBus.phase_completed.connect(_on_phase_completed)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	# Aqui você pode emitir um sinal se quiser que a UI mude automaticamente
	match current_state:
		GameState.PAUSED:
			get_tree().paused = true
		_:
			get_tree().paused = false

func _on_phase_started(_phase_id: String) -> void:
	set_state(GameState.PLAYING)

func _on_phase_completed(_phase_id: String, _success: bool) -> void:
	# Lógica pós fase (ex: mostrar tela de resultados)
	pass
