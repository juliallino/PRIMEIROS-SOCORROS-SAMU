extends Node2D

@onready var progress_bar = $UILayer/ProgressBar
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var camera = $Camera2D
@onready var blood_overlay = $UILayer/BloodOverlay
@onready var defeat_overlay = $UILayer/DefeatOverlay
@onready var victory_overlay = $UILayer/VictoryOverlay
@onready var status_label = $UILayer/Monitor/Status
@onready var monitor_panel = $UILayer/Monitor
@onready var blood_audio_player = $BloodAudioPlayer

# Configurações de Gameplay
var bleeding_points = []
var active_pressure_points = 0
var current_stability: float = 60.0 # Começa com estabilidade parcial
var stability_target: float = 100.0
var decay_rate: float = 15.0 # Taxa de perda se não houver pressão
var recovery_rate: float = 12.0 # Taxa de ganho por ponto pressionado

# Regra de Derrota (6 segundos)
var survival_timer: float = 6.0
var is_failing: bool = false
var game_active: bool = true

func _ready() -> void:
	EventBus.phase_started.emit("hemorragia")
	EventBus.phase_restart_requested.connect(_on_restart_requested)
	_setup_bleeding_points()
	progress_bar.value = current_stability
	blood_overlay.modulate.a = 0.3
	defeat_overlay.hide()
	
	if blood_audio_player and blood_audio_player.stream:
		if blood_audio_player.stream is AudioStreamWAV:
			blood_audio_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif blood_audio_player.stream is AudioStreamMP3:
			blood_audio_player.stream.loop = true
		blood_audio_player.volume_db = 0.0
	
	status_label.text = "INSTÁVEL"
	status_label.modulate = Color.YELLOW

func _setup_bleeding_points() -> void:
	for area in $BleedingPoints.get_children():
		if area is Area2D:
			area.input_event.connect(_on_point_input.bind(area))
			bleeding_points.append({"area": area, "is_pressed": false})

func _input(event: InputEvent) -> void:
	if not game_active: return
	
	# Consertar bug de 'pressão infinita' ao soltar o mouse fora da área
	if event is InputEventMouseButton and not event.pressed:
		for p in bleeding_points:
			if p["is_pressed"]:
				p["is_pressed"] = false
				_on_pressure_stop(p["area"])

func _on_point_input(_viewport, event, _shape_idx, area_node) -> void:
	if not game_active: return
	
	if event is InputEventMouseButton:
		var point_data = _get_point_data(area_node)
		if event.pressed:
			point_data["is_pressed"] = true
			_on_pressure_start(area_node)
		# O release agora é tratado globalmente no _input para segurança

func _get_point_data(node) -> Dictionary:
	for p in bleeding_points:
		if p["area"] == node: return p
	return {}

func _on_pressure_start(node) -> void:
	active_pressure_points += 1
	node.get_node("Effect").emitting = false
	_show_feedback("PRESSÃO APLICADA", Color.CYAN)
	_update_monitor_visuals()

func _on_pressure_stop(node) -> void:
	active_pressure_points -= 1
	node.get_node("Effect").emitting = true
	_show_feedback("PRESSÃO INSUFICIENTE!", Color.RED)
	_update_monitor_visuals()

func _process(delta: float) -> void:
	if not game_active: return
	
	# Lógica da Barra de Estancamento
	if active_pressure_points > 0:
		current_stability += recovery_rate * active_pressure_points * delta
		# Reduzir sangue visual conforme estabiliza
		blood_overlay.modulate.a = lerp(blood_overlay.modulate.a, 0.1, delta * 0.5)
		_update_blood_audio(false) # Fade out
	else:
		current_stability -= decay_rate * delta
		# Intensificar sangue visual
		blood_overlay.modulate.a = lerp(blood_overlay.modulate.a, 0.8, delta * 0.2)
		_shake_camera(2.0)
		_update_blood_audio(true) # Fade in
	
	current_stability = clamp(current_stability, 0.0, 100.0)
	progress_bar.value = current_stability
	
	# Regra de Derrota: Barra em 0 por 6 segundos
	if current_stability <= 0:
		_process_failure_timer(delta)
	else:
		_reset_failure_state()
	
	# Condição de Vitória
	if current_stability >= stability_target:
		_win_phase()

func _process_failure_timer(delta: float) -> void:
	if not is_failing:
		is_failing = true
		_show_feedback("PACIENTE PERDENDO MUITO SANGUE", Color.DARK_RED)
	
	survival_timer -= delta
	
	# Feedback Visual de Urgência
	var urgency = 1.0 - (survival_timer / 6.0)
	
	# Piscar UI em vermelho
	if Engine.get_frames_drawn() % 15 == 0:
		monitor_panel.modulate = Color.RED if monitor_panel.modulate == Color.WHITE else Color.WHITE
		progress_bar.modulate = Color.RED if progress_bar.modulate == Color.WHITE else Color.WHITE
	
	status_label.text = "CRÍTICO: %.1fs" % survival_timer
	status_label.modulate = Color.RED
	
	_shake_camera(4.0 * urgency)
	
	# Intensificar sangue e escurecer tela
	blood_overlay.modulate.a = lerp(0.6, 1.0, urgency)
	
	# Alertas e batimentos com frequência crescente
	var alert_frequency = lerp(60.0, 20.0, urgency)
	if Engine.get_frames_drawn() % int(alert_frequency) == 0:
		if urgency > 0.5:
			var alerts = ["ESTABILIZE O FERIMENTO", "PRESSÃO INSUFICIENTE", "PACIENTE PIORANDO"]
			_show_feedback(alerts.pick_random(), Color.RED)
		EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_warning_short.wav")

	if survival_timer <= 0:
		_lose_phase()

func _reset_failure_state() -> void:
	if not is_failing: return
	is_failing = false
	survival_timer = 6.0
	monitor_panel.modulate = Color.WHITE
	progress_bar.modulate = Color.WHITE
	_update_monitor_visuals()

func _update_monitor_visuals() -> void:
	if is_failing: return
	
	if current_stability > 80:
		status_label.text = "ESTÁVEL"
		status_label.modulate = Color.GREEN
	elif current_stability > 40:
		status_label.text = "INSTÁVEL"
		status_label.modulate = Color.YELLOW
	else:
		status_label.text = "CRÍTICO"
		status_label.modulate = Color.ORANGE

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 1.0).set_delay(0.5)

func _update_blood_audio(is_bleeding: bool) -> void:
	if not blood_audio_player: return
	
	if is_bleeding:
		if not blood_audio_player.playing:
			if blood_audio_player.stream is AudioStreamWAV:
				blood_audio_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			blood_audio_player.play()
		blood_audio_player.volume_db = 0.0 # Volume máximo
	else:
		blood_audio_player.stop()

func _shake_camera(intensity: float) -> void:
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func _win_phase() -> void:
	game_active = false
	set_process(false)
	_update_blood_audio(false)
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	# Desaceleração cinematográfica
	Engine.time_scale = 0.5
	
	feedback_label.text = "SANGRAMENTO ESTANCADO!"
	feedback_label.modulate = Color.GREEN
	feedback_label.modulate.a = 1.0
	
	# Mostrar Overlay de Vitória
	if victory_overlay:
		await victory_overlay.show_victory()
		
	# Restaurar tempo
	Engine.time_scale = 1.0
	
	EventBus.phase_completed.emit("hemorragia", true)
	SaveManager.game_data["completed_phases"].append("hemorragia")
	SaveManager.save_game()
	
	EventBus.cinematic_transition_requested.emit("res://scenes/phases/Desfibrilador_Intro.tscn")

func _lose_phase() -> void:
	game_active = false
	set_process(false)
	_update_blood_audio(false)
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	EventBus.phase_completed.emit("hemorragia", false)
	
	# Sequência cinematográfica de derrota
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Escurecer tela totalmente
	tween.tween_property(blood_overlay, "color", Color.BLACK, 2.0)
	tween.tween_property(blood_overlay, "modulate:a", 1.0, 2.0)
	
	# Muffle sounds e abafar áudio (simulado por feedback visual aqui)
	EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_flatline.wav")
	
	defeat_overlay.show()
	defeat_overlay.modulate.a = 0
	
	var messages = [
		"O paciente ainda precisa de ajuda.",
		"Precisamos conter o sangramento.",
		"Não podemos desistir.",
		"Vamos tentar novamente."
	]
	
	var msg_label = defeat_overlay.get_node_or_null("Message")
	if msg_label:
		msg_label.text = messages.pick_random()
	
	tween.tween_property(defeat_overlay, "modulate:a", 1.0, 1.5)
	
	await get_tree().create_timer(4.0).timeout
	# Reiniciar intro da Hemorragia
	EventBus.transition_started.emit("res://scenes/phases/Hemorragia_Intro.tscn")

func _on_restart_requested() -> void:
	if not game_active: return
	game_active = false
	print("[Hemorragia] Reiniciando fase...")
	_update_blood_audio(false)
	EventBus.transition_started.emit("res://scenes/phases/Hemorragia_Intro.tscn")
