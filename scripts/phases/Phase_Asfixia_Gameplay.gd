extends Node2D

@onready var player_trail = $PlayerTrail
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var progress_bar = $UILayer/ProgressBar
@onready var error_counter_label = $UILayer/ErrorCounter
@onready var defeat_overlay = $UILayer/DefeatOverlay
@onready var spark_particles = $SparkParticles
@onready var camera = $Camera2D

# Configurações de Gameplay
var points: PackedVector2Array = []
var is_drawing: bool = false
var draw_start_time: float = 0.0

var success_count: int = 0
var required_success: int = 5
var error_count: int = 0
var max_errors: int = 3

# Limites para detecção do gesto "J"
# O "J" deve começar descendo (y aumenta), depois curvar para a esquerda (x diminui) e subir (y diminui)
# Simplificando: Detecção de 3 estágios
enum GestureState { START, DOWN, CURVE, UP }

func _ready() -> void:
	EventBus.phase_started.emit("asfixia")
	progress_bar.max_value = required_success
	progress_bar.value = 0
	_update_error_ui()

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
	# Limitar número de pontos para performance
	if points.size() > 50:
		points.remove_at(0)

func _stop_drawing() -> void:
	if not is_drawing: return
	is_drawing = false
	
	var duration = Time.get_unix_time_from_system() - draw_start_time
	var result = _analyze_gesture(points, duration)
	
	_handle_result(result)
	
	# Limpar rastro com fade
	var tween = create_tween()
	tween.tween_property(player_trail, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): 
		player_trail.points = []
		player_trail.modulate.a = 1.0
	)

func _analyze_gesture(gesture_points: PackedVector2Array, duration: float) -> String:
	if gesture_points.size() < 10: return "INVALID"
	if duration > 1.5: return "TOO_SLOW"
	
	var start = gesture_points[0]
	var end = gesture_points[gesture_points.size() - 1]
	
	# Analisar a forma básica do "J"
	# 1. Movimento descendente significativo
	var max_y = start.y
	var found_down = false
	for p in gesture_points:
		if p.y > max_y + 100:
			found_down = true
			break
			
	# 2. Curva para a esquerda no final
	var found_left = false
	for p in gesture_points:
		if found_down and p.x < start.x - 30:
			found_left = true
			break
			
	# 3. Finaliza subindo ou estabilizando
	var found_up = end.y < gesture_points[gesture_points.size() - 5].y
	
	if found_down and found_left:
		if duration < 0.8:
			return "CORRECT"
		else:
			return "TOO_SLOW"
			
	return "RETRY"

func _handle_result(result: String) -> void:
	match result:
		"CORRECT":
			_on_success()
		"TOO_SLOW":
			_show_feedback("MUITO LENTO", Color.YELLOW)
		"RETRY":
			_show_feedback("TENTE NOVAMENTE", Color.ORANGE)
			_on_error()
		"INVALID":
			pass

func _on_success() -> void:
	success_count += 1
	progress_bar.value = success_count
	_show_feedback("CORRETO!", Color.GREEN)
	_apply_effects()
	
	if success_count >= required_success:
		_win_game()

func _on_error() -> void:
	error_count += 1
	_update_error_ui()
	_shake_camera(10.0)
	
	if error_count >= max_errors:
		_lose_game()

func _update_error_ui() -> void:
	error_counter_label.text = "ERROS: %d / %d" % [error_count, max_errors]

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
	defeat_overlay.show()
	defeat_overlay.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(defeat_overlay, "modulate:a", 1.0, 1.0)
	await tween.finished
	await get_tree().create_timer(3.0).timeout
	# Voltar para a intro
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")

func _win_game() -> void:
	feedback_label.text = "PACIENTE SALVO!"
	feedback_label.modulate = Color.CYAN
	feedback_label.modulate.a = 1.0
	
	SaveManager.game_data["completed_phases"].append("asfixia")
	SaveManager.save_game()
	
	await get_tree().create_timer(2.0).timeout
	EventBus.cinematic_transition_requested.emit("res://scenes/phases/ParadaCardiaca_Intro.tscn")
