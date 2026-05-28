extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	CUTSCENE,
	GAME_OVER
}

var current_state: GameState = GameState.MENU

# Estatísticas do Plantão
var total_errors: int = 0
var total_failures: int = 0
var completed_phases_count: int = 0
var _completed_phases_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.phase_started.connect(_on_phase_started)
	EventBus.intro_started.connect(_on_intro_started)
	EventBus.phase_completed.connect(_on_phase_completed)
	EventBus.transition_started.connect(_on_transition_started)
	EventBus.error_reported.connect(_on_error_reported)
	print("[GameManager] Inicializado e conectado aos sinais.")

func reset_stats() -> void:
	total_errors = 0
	total_failures = 0
	completed_phases_count = 0
	_completed_phases_ids.clear()
	print("[GameManager] Estatísticas resetadas para novo plantão.")

func _on_error_reported() -> void:
	total_errors += 1
	print("[GameManager] Erro global contabilizado: ", total_errors)

func set_state(new_state: GameState) -> void:
	print("[GameManager] Mudando estado para: ", new_state)
	current_state = new_state
	
	match current_state:
		GameState.MENU:
			get_tree().paused = false
			UIManager.toggle_pause_button(false)
			AudioManager.stop_all_sounds()
		GameState.PLAYING:
			get_tree().paused = false
			UIManager.toggle_pause_button(true)
			AudioManager.resume_gameplay_audio()
		GameState.PAUSED:
			get_tree().paused = true
			UIManager.toggle_pause_button(false)
			AudioManager.pause_gameplay_audio()
		GameState.CUTSCENE:
			get_tree().paused = false
			UIManager.toggle_pause_button(true)
			# Permitir áudio de transição da ambulância
			var exceptions = []
			var transition = get_tree().root.find_child("AmbulanceTransition", true, false)
			if transition:
				exceptions.append(transition.get_node_or_null("AmbulanceAudio"))
				exceptions.append(transition.get_node_or_null("RainAudio"))
			AudioManager.stop_all_sounds(exceptions)
		GameState.GAME_OVER:
			get_tree().paused = false
			UIManager.toggle_pause_button(false)
			AudioManager.stop_all_sounds()

func _on_phase_started(_phase_id: String) -> void:
	print("[GameManager] Sinal phase_started recebido: ", _phase_id)
	set_state(GameState.PLAYING)

func _on_intro_started(_phase_id: String) -> void:
	print("[GameManager] Sinal intro_started recebido: ", _phase_id)
	set_state(GameState.CUTSCENE)

func _on_phase_completed(_phase_id: String, _success: bool) -> void:
	if _success:
		if not _phase_id in _completed_phases_ids:
			_completed_phases_ids.append(_phase_id)
			completed_phases_count = _completed_phases_ids.size()
			print("[GameManager] Fase concluída: ", _phase_id, ". Total únicas: ", completed_phases_count)
	else:
		total_failures += 1
		print("[GameManager] Falha na fase: ", _phase_id, ". Total falhas: ", total_failures)
	
	# Lógica pós fase
	pass

func _on_transition_started(path: String) -> void:
	print("[GameManager] Transição iniciada para: ", path)
	
	# SEMPRE fechar o menu de pause ao trocar de cena para evitar UI residual
	UIManager.close_pause_menu()
	
	# Se estiver indo para o menu principal, esconder o botão de pause definitivamente
	if "MainMenu.tscn" in path:
		UIManager.toggle_pause_button(false)
	else:
		# Em outras transições (entre fases), o pause pode continuar visível se desejado
		UIManager.toggle_pause_button(true)
