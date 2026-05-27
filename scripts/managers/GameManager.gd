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
	EventBus.intro_started.connect(_on_intro_started)
	EventBus.phase_completed.connect(_on_phase_completed)
	EventBus.transition_started.connect(_on_transition_started)
	print("[GameManager] Inicializado e conectado aos sinais.")

func set_state(new_state: GameState) -> void:
	print("[GameManager] Mudando estado para: ", new_state)
	current_state = new_state
	
	match current_state:
		GameState.MENU:
			get_tree().paused = false
			UIManager.toggle_pause_button(false)
		GameState.PLAYING:
			get_tree().paused = false
			UIManager.toggle_pause_button(true)
		GameState.PAUSED:
			get_tree().paused = true
			UIManager.toggle_pause_button(false)
		GameState.CUTSCENE:
			get_tree().paused = false
			UIManager.toggle_pause_button(true)
		GameState.GAME_OVER:
			get_tree().paused = false
			UIManager.toggle_pause_button(false)

func _on_phase_started(_phase_id: String) -> void:
	print("[GameManager] Sinal phase_started recebido: ", _phase_id)
	set_state(GameState.PLAYING)

func _on_intro_started(_phase_id: String) -> void:
	print("[GameManager] Sinal intro_started recebido: ", _phase_id)
	set_state(GameState.CUTSCENE)

func _on_phase_completed(_phase_id: String, _success: bool) -> void:
	# Lógica pós fase
	pass

func _on_transition_started(_path: String) -> void:
	print("[GameManager] Transição iniciada para: ", _path)
	# O usuário solicitou que o pause apareça em transições também
	UIManager.toggle_pause_button(true)
