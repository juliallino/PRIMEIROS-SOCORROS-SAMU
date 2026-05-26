extends Node2D

@onready var interaction_area = $InteractionArea
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var progress_bar = $UILayer/ProgressBar
@onready var error_label = $UILayer/ErrorCounter
@onready var bpm_value_label = $UILayer/Monitor/BPMValue
@onready var monitor_anim = $UILayer/Monitor/MonitorAnim
@onready var fx_player = $FXPlayer
@onready var camera = $Camera2D

# Configurações de Ritmo
var target_bpm_min: float = 100.0
var target_bpm_max: float = 120.0
var target_interval_min: float = 60.0 / target_bpm_max # 0.5s
var target_interval_max: float = 60.0 / target_bpm_min # 0.6s

# Variáveis de Estado
var last_click_time: float = 0.0
var current_progress: float = 0.0
var error_count: int = 0
var max_errors: int = 5
var total_clicks: int = 0

func _ready() -> void:
	interaction_area.input_event.connect(_on_interaction_input)
	progress_bar.value = 0
	_update_ui()
	
	# Iniciar música de fundo (Stayin' Alive style placeholder)
	# AudioManager.play_music("res://assets/audio/cpr_rhythm_track.ogg")

func _on_interaction_input(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		_process_click()

func _process_click() -> void:
	var current_time = Time.get_unix_time_from_system()
	total_clicks += 1
	
	if last_click_time > 0:
		var interval = current_time - last_click_time
		var current_bpm = 60.0 / interval
		_check_rhythm(interval, current_bpm)
	else:
		_show_feedback("COMECE O RITMO!", Color.WHITE)
		
	last_click_time = current_time
	
	# Efeitos de impacto
	_apply_click_effects()

func _check_rhythm(interval: float, bpm: float) -> void:
	bpm_value_label.text = str(int(bpm))
	monitor_anim.play("ecg_pulse")
	
	if interval >= target_interval_min and interval <= target_interval_max:
		_on_success_beat()
	elif interval < target_interval_min:
		_on_fail_beat("MUITO RÁPIDO")
	else:
		_on_fail_beat("MUITO LENTO")

func _on_success_beat() -> void:
	current_progress += 2.0 # Ganha progresso por batida correta
	_show_feedback("PERFEITO!", Color.GREEN)
	
	if current_progress >= 100.0:
		_win_phase()
	_update_ui()

func _on_fail_beat(msg: String) -> void:
	current_progress -= 1.0 # Perde um pouco de progresso no erro
	error_count += 1
	_show_feedback(msg, Color.RED)
	_update_ui()
	
	if error_count >= max_errors:
		_lose_phase()

func _update_ui() -> void:
	current_progress = clamp(current_progress, 0.0, 100.0)
	progress_bar.value = current_progress
	error_label.text = "FALHAS: %d / %d" % [error_count, max_errors]

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5).set_delay(0.2)

func _apply_click_effects() -> void:
	# Shake de câmera
	var shake_tween = create_tween()
	for i in range(3):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		shake_tween.tween_property(camera, "offset", offset, 0.03)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)
	
	# Zoom rápido
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(1.02, 1.02), 0.05)
	zoom_tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.1)

func _win_phase() -> void:
	print("Vitória! Paciente estabilizado.")
	SaveManager.game_data["completed_phases"].append("parada_cardiaca")
	SaveManager.save_game()
	
	feedback_label.text = "PACIENTE ESTABILIZADO!"
	feedback_label.modulate = Color.CYAN
	feedback_label.modulate.a = 1.0
	
	await get_tree().create_timer(2.0).timeout
	EventBus.transition_started.emit("res://scenes/phases/Hemorragia_Intro.tscn")

func _lose_phase() -> void:
	print("Derrota por falhas excessivas.")
	fx_player.play("screen_darken")
	feedback_label.text = "VOCÊ PERDEU O RITMO..."
	feedback_label.modulate = Color.DARK_RED
	feedback_label.modulate.a = 1.0
	
	await get_tree().create_timer(2.5).timeout
	EventBus.transition_started.emit("res://scenes/phases/ParadaCardiaca_Intro.tscn")
