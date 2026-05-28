extends Node2D

@onready var player_trail = $PlayerTrail
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var progress_bar = $UILayer/ProgressBar
@onready var error_counter_label = $UILayer/ErrorCounter
@onready var defeat_overlay = $UILayer/DefeatOverlay
@onready var victory_overlay = $UILayer/VictoryOverlay
@onready var spark_particles = $SparkParticles
@onready var camera = $Camera2D
@onready var asfixia_audio_player = $AsfixiaAudioPlayer

# Configurações de Gameplay
var points: PackedVector2Array = []
var is_drawing: bool = false
var draw_start_time: float = 0.0

var success_count: int = 0
var required_success: int = 5
var error_count: int = 0
var max_errors: int = 5
var is_phase_over: bool = false

func _ready() -> void:
	EventBus.phase_started.emit("asfixia")
	EventBus.phase_restart_requested.connect(_on_restart_requested)
	progress_bar.max_value = required_success
	progress_bar.value = 0
	_update_error_ui()
	
	if asfixia_audio_player and asfixia_audio_player.stream:
		asfixia_audio_player.stream.loop = true
		asfixia_audio_player.play()

func _input(event: InputEvent) -> void:
	if defeat_overlay.visible: return
	
	if event is InputEventMouseButton:
		if event.pressed:
			_start_drawing(event.position)
		else:
			_stop_drawing()
	
	if event is InputEventMouseMotion and is_drawing:
		_add_point(event.position)

func _start_drawing(pos: Vector2) -> void:
	is_drawing = true
	points = [pos]
	player_trail.points = points
	draw_start_time = Time.get_unix_time_from_system()

func _add_point(pos: Vector2) -> void:
	points.append(pos)
	player_trail.points = points
	if points.size() > 50:
		points.remove_at(0)

func _stop_drawing() -> void:
	if not is_drawing: return
	is_drawing = false
	
	var duration = Time.get_unix_time_from_system() - draw_start_time
	var result = _analyze_gesture(points, duration)
	
	_handle_result(result)
	
	var tween = create_tween()
	tween.tween_property(player_trail, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): 
		player_trail.points = []
		player_trail.modulate.a = 1.0
	)

func _analyze_gesture(gesture_points: PackedVector2Array, duration: float) -> String:
	if gesture_points.size() < 10: return "INVALID"
	
	if duration > 1.2: 
		return "TOO_SLOW"
	
	var start = gesture_points[0]
	var end = gesture_points[gesture_points.size() - 1]
	
	# Analisar a forma básica do "J"
	var max_y = start.y
	var found_down = false
	for p in gesture_points:
		if p.y > max_y + 80:
			found_down = true
			break
			
	var found_left = false
	for p in gesture_points:
		if found_down and p.x < start.x - 30:
			found_left = true
			break
			
	if found_down and found_left:
		return "CORRECT"
			
	return "RETRY"

func _handle_result(result: String) -> void:
	match result:
		"CORRECT":
			_on_success()
		"TOO_SLOW":
			_show_feedback("MUITO LENTO", Color.ORANGE)
			_on_error()
		"RETRY":
			_show_feedback("MOVIMENTO INCORRETO", Color.ORANGE)
			_on_error()
		"INVALID":
			_show_feedback("TENTE NOVAMENTE", Color.YELLOW)
			_on_error()

func _on_success() -> void:
	success_count += 1
	progress_bar.value = success_count
	_show_feedback("CORRETO!", Color.CYAN)
	_apply_effects()
	
	if success_count >= required_success:
		_win_game()

func _on_error() -> void:
	error_count += 1
	EventBus.error_reported.emit()
	_update_error_ui()
	_shake_camera(15.0)
	
	EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_error.wav")
	
	# Diminuir progresso levemente
	success_count = max(0, success_count - 1)
	progress_bar.value = success_count
	
	if error_count >= max_errors:
		_lose_game()

func _update_error_ui() -> void:
	error_counter_label.text = "ERROS: %d / %d" % [error_count, max_errors]
	if error_count >= max_errors - 1:
		error_counter_label.modulate = Color.RED
		_show_feedback("PACIENTE PIORANDO!", Color.DARK_RED)

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
	
	tween.set_parallel(false)
	tween.tween_interval(0.5)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.3)

func _apply_effects() -> void:
	_shake_camera(20.0)
	spark_particles.position = points[points.size() - 1]
	spark_particles.emitting = true
	
	var tween = create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.05, 1.05), 0.05)
	tween.tween_property(camera, "zoom", Vector2(1.0, 1.0), 0.1)

func _shake_camera(intensity: float) -> void:
	var tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
		tween.tween_property(camera, "offset", offset, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

func _lose_game() -> void:
	if is_phase_over: return
	is_phase_over = true
	
	# Esconder botões de interface durante a derrota
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	EventBus.phase_completed.emit("asfixia", false)
	defeat_overlay.show()
	defeat_overlay.modulate.a = 0
	
	var messages = [
		"O paciente ainda precisa de ajuda.",
		"Vamos tentar novamente.",
		"Precisamos agir mais rápido.",
		"Não desista do paciente."
	]
	var msg_label = defeat_overlay.get_node_or_null("Message")
	if msg_label:
		msg_label.text = messages.pick_random()
	
	var tween = create_tween()
	tween.tween_property(defeat_overlay, "modulate:a", 1.0, 1.5)
	
	await tween.finished
	await get_tree().create_timer(3.0).timeout
	# Voltar para a intro
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")

func _win_game() -> void:
	if is_phase_over: return
	is_phase_over = true
	
	# Parar áudio imediatamente com fade out curto
	if asfixia_audio_player:
		var audio_tween = create_tween()
		audio_tween.tween_property(asfixia_audio_player, "volume_db", -80.0, 0.5)
		audio_tween.finished.connect(asfixia_audio_player.stop)
	
	# Esconder botões de interface durante a vitória
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	# Desativar interações e esconder guia
	is_drawing = false
	player_trail.points = []
	if has_node("GestureGuide"):
		$GestureGuide.hide()
	
	# Desaceleração cinematográfica
	Engine.time_scale = 0.5
	
	feedback_label.text = "PACIENTE SALVO!"
	feedback_label.modulate = Color.CYAN
	feedback_label.modulate.a = 1.0
	
	# Mostrar Overlay de Vitória
	if victory_overlay:
		await victory_overlay.show_victory()
	
	# Restaurar tempo
	Engine.time_scale = 1.0
	
	EventBus.phase_completed.emit("asfixia", true)
	SaveManager.game_data["completed_phases"].append("asfixia")
	SaveManager.save_game()
	
	EventBus.cinematic_transition_requested.emit("res://scenes/phases/ParadaCardiaca_Intro.tscn")

func _on_restart_requested() -> void:
	if is_phase_over: return
	is_phase_over = true
	print("[Phase_Asfixia] Reiniciando fase...")
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")
