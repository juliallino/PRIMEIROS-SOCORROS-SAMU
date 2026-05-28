extends Node2D

# --- Referências ---
@onready var rhythm_circles = $RhythmCircles
@onready var progress_bar = $UILayer/ProgressBar
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var error_label = $UILayer/ErrorCounter
@onready var monitor_anim = $UILayer/Monitor/MonitorAnim
@onready var heartbeat_player = $HeartbeatPlayer
@onready var fx_player = $FXPlayer
@onready var victory_overlay = $UILayer/VictoryOverlay
@onready var camera = $Camera2D

# --- Configurações de Ritmo (RCP Real ~110 BPM) ---
var bpm: float = 110.0
var beat_interval: float = 60.0 / bpm # ~0.545s por batida
var current_beat_time: float = 0.0

# --- Círculos (Draw Logic) ---
var target_radius: float = 60.0
var max_external_radius: float = 180.0
var current_external_radius: float = 180.0
var circle_color: Color = Color(0, 1, 1, 0.6) # Ciano médico
var target_color: Color = Color(1, 1, 1, 0.3)

# --- Janelas de Acerto (em segundos de diferença) ---
var window_perfect: float = 0.06
var window_good: float = 0.12
var window_early_late: float = 0.20

# --- Estado do Jogo ---
var stabilization_progress: float = 0.0
var error_count: int = 0
var max_errors: int = 5
var game_active: bool = true
var cpr_started: bool = false
var first_success_done: bool = false
var time_since_last_click: float = 0.0
var inactivity_threshold: float = 1.5 # Tempo em segundos antes de começar a cair
var decay_rate: float = 4.0 # Velocidade da queda por segundo

func _ready() -> void:
	EventBus.phase_started.emit("parada_cardiaca")
	EventBus.phase_restart_requested.connect(_on_restart_requested)
	rhythm_circles.set_script(load("res://scripts/phases/CircleDrawer.gd")) # Script auxiliar para desenho
	_update_ui()
	_start_heartbeat_audio()

func _process(delta: float) -> void:
	if not game_active: return
	
	# Monitorar Inatividade
	if cpr_started:
		time_since_last_click += delta
		if time_since_last_click > inactivity_threshold:
			_apply_inactivity_decay(delta)
	
	# Progresso do batimento (0.0 a 1.0)
	current_beat_time += delta
	
	# Se passou do tempo da batida e o jogador não clicou, resetamos o ciclo
	if current_beat_time >= beat_interval:
		current_beat_time = 0.0
		# Opcional: penalizar se o jogador ignorar batidas demais
	
	# Calcular escala visual do círculo externo
	var t = current_beat_time / beat_interval
	current_external_radius = lerp(max_external_radius, target_radius, t)
	
	# Notificar o drawer para redesenhar
	if rhythm_circles.has_method("update_circles"):
		rhythm_circles.update_circles(target_radius, current_external_radius, circle_color)

func _apply_inactivity_decay(delta: float) -> void:
	# Diminuir progresso gradualmente
	stabilization_progress = max(0, stabilization_progress - decay_rate * delta)
	_update_ui()
	
	# Feedback visual de piora
	var flash = $UILayer/FlashOverlay
	flash.color.a = lerp(flash.color.a, 0.2, delta * 2.0)
	
	if Engine.get_frames_drawn() % 30 == 0:
		_show_feedback("PACIENTE PIORANDO", Color.DARK_RED)
		EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_warning_short.wav")

func _input(event: InputEvent) -> void:
	if not game_active: return
	
	if event is InputEventMouseButton and event.pressed:
		cpr_started = true
		time_since_last_click = 0.0
		# Resetar overlay de piora suavemente
		var tween = create_tween()
		tween.tween_property($UILayer/FlashOverlay, "color:a", 0.0, 0.3)
		
		_check_timing()

func _check_timing() -> void:
	# O momento perfeito é quando current_beat_time chega no beat_interval
	# Ou seja, a diferença (beat_interval - current_beat_time) é pequena
	var diff = abs(beat_interval - current_beat_time)
	
	# Consideramos também o início da próxima batida (clicou um pouco depois)
	if current_beat_time < window_early_late:
		diff = current_beat_time
		
	if diff <= window_perfect:
		_handle_hit("PERFEITO!", Color.CYAN, 5.0)
	elif diff <= window_good:
		_handle_hit("BOM", Color.GREEN, 3.0)
	elif current_beat_time < beat_interval * 0.5:
		_handle_hit("ATRASADO", Color.ORANGE, -1.0)
	else:
		_handle_hit("PRECEDENTE", Color.ORANGE, -1.0)

func _handle_hit(msg: String, color: Color, gain: float) -> void:
	_show_feedback(msg, color)
	
	if gain > 0:
		stabilization_progress += gain
		_trigger_success_fx()
		# Resetar o tempo para sincronizar com o clique do jogador (ajuda a manter o ritmo)
		current_beat_time = 0.0
	else:
		_handle_error(msg)
	
	_update_ui()
	_check_conditions()

func _start_heartbeat_audio() -> void:
	if heartbeat_player and heartbeat_player.has_method("start_rhythm"):
		heartbeat_player.start_rhythm()

func _stop_heartbeat_audio() -> void:
	if heartbeat_player and heartbeat_player.has_method("stop_rhythm"):
		heartbeat_player.stop_rhythm()

func _handle_error(msg: String) -> void:
	stabilization_progress = max(0, stabilization_progress - 2.0)
	error_count += 1
	EventBus.error_reported.emit()
	_trigger_fail_fx()
	
	if msg == "": msg = "RITMO INCORRETO"
	_show_feedback(msg, Color.ORANGE)

func _trigger_success_fx() -> void:
	monitor_anim.play("ecg_pulse")
	_shake_camera(12.0)
	EventBus.sfx_played.emit("res://assets/audio/sfx/cpr_hit.wav")
	
	# Brilho temporário nos círculos
	circle_color = Color(1, 1, 1, 1)
	get_tree().create_timer(0.1).timeout.connect(func(): circle_color = Color(0, 1, 1, 0.6))

func _trigger_fail_fx() -> void:
	fx_player.play("screen_darken")
	_shake_camera(20.0)
	EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_error.wav")

func _update_ui() -> void:
	stabilization_progress = clamp(stabilization_progress, 0.0, 100.0)
	progress_bar.value = stabilization_progress
	error_label.text = "FALHAS: %d / %d" % [error_count, max_errors]

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.4).set_delay(0.2)

func _shake_camera(intensity: float) -> void:
	var tween = create_tween()
	for i in range(4):
		var off = Vector2(randf_range(-1,1), randf_range(-1,1)) * intensity
		tween.tween_property(camera, "offset", off, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

func _check_conditions() -> void:
	if stabilization_progress >= 100.0:
		_win()
	elif error_count >= max_errors:
		_lose()

func _win() -> void:
	game_active = false
	_stop_heartbeat_audio()
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	# Desaceleração cinematográfica
	Engine.time_scale = 0.5
	
	feedback_label.text = "PACIENTE ESTABILIZADO!"
	feedback_label.modulate = Color.CYAN
	feedback_label.modulate.a = 1.0
	
	# Mostrar Overlay de Vitória
	if victory_overlay:
		await victory_overlay.show_victory()
		
	# Restaurar tempo
	Engine.time_scale = 1.0
	
	EventBus.phase_completed.emit("parada_cardiaca", true)
	SaveManager.game_data["completed_phases"].append("parada_cardiaca")
	SaveManager.save_game()
	
	EventBus.cinematic_transition_requested.emit("res://scenes/phases/Hemorragia_Intro.tscn")

func _lose() -> void:
	game_active = false
	_stop_heartbeat_audio()
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	EventBus.phase_completed.emit("parada_cardiaca", false)
	var defeat_overlay = $UILayer.get_node_or_null("DefeatOverlay")
	if defeat_overlay:
		defeat_overlay.show()
		defeat_overlay.modulate.a = 0
		
		var messages = [
			"O paciente ainda precisa de ajuda.",
			"Vamos tentar novamente.",
			"Precisamos manter o ritmo.",
			"Não podemos parar agora."
		]
		var msg_label = defeat_overlay.get_node_or_null("Message")
		if msg_label:
			msg_label.text = messages.pick_random()
			
		var tween = create_tween()
		tween.tween_property(defeat_overlay, "modulate:a", 1.0, 1.5)
	
	# Abafar sons e deixar monitor instável
	monitor_anim.stop()
	
	await get_tree().create_timer(4.0).timeout
	# Voltar para a intro da Parada Cardíaca
	EventBus.transition_started.emit("res://scenes/phases/ParadaCardiaca_Intro.tscn")

func _on_restart_requested() -> void:
	if not game_active: return
	game_active = false
	print("[MassagemCardiaca] Reiniciando fase...")
	_stop_heartbeat_audio()
	EventBus.transition_started.emit("res://scenes/phases/ParadaCardiaca_Intro.tscn")
