extends Node2D

@onready var progress_bar = $UILayer/ProgressBar
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var camera = $Camera2D
@onready var blood_overlay = $UILayer/BloodOverlay
@onready var defeat_overlay = $UILayer/DefeatOverlay

# Configurações de Gameplay
var bleeding_points = []
var active_pressure_points = 0
var current_stability: float = 0.0
var stability_target: float = 100.0
var decay_rate: float = 5.0 # Taxa de perda se não houver pressão
var recovery_rate: float = 8.0 # Taxa de ganho por ponto pressionado

func _ready() -> void:
	# Definir pontos de sangramento (Exemplo: Braço, Perna, Abdômen)
	_setup_bleeding_points()
	progress_bar.value = 0
	blood_overlay.modulate.a = 0.3

func _setup_bleeding_points() -> void:
	# Criar áreas de clique dinamicamente ou referenciar existentes
	for area in $BleedingPoints.get_children():
		if area is Area2D:
			area.input_event.connect(_on_point_input.bind(area))
			bleeding_points.append({"area": area, "is_pressed": false})

func _on_point_input(_viewport, event, _shape_idx, area_node) -> void:
	if event is InputEventMouseButton:
		var point_data = _get_point_data(area_node)
		if event.pressed:
			point_data["is_pressed"] = true
			_on_pressure_start(area_node)
		else:
			point_data["is_pressed"] = false
			_on_pressure_stop(area_node)

func _get_point_data(node) -> Dictionary:
	for p in bleeding_points:
		if p["area"] == node: return p
	return {}

func _on_pressure_start(node) -> void:
	active_pressure_points += 1
	node.get_node("Effect").emitting = false # Sangramento para visualmente
	_show_feedback("PRESSÃO APLICADA", Color.CYAN)

func _on_pressure_stop(node) -> void:
	active_pressure_points -= 1
	node.get_node("Effect").emitting = true # Sangue volta a jorrar
	_show_feedback("HEMORRAGIA VOLTOU!", Color.RED)

func _process(delta: float) -> void:
	if defeat_overlay.visible: return
	
	if active_pressure_points > 0:
		current_stability += recovery_rate * active_pressure_points * delta
		blood_overlay.modulate.a = lerp(blood_overlay.modulate.a, 0.0, delta * 0.5)
	else:
		current_stability -= decay_rate * delta
		blood_overlay.modulate.a = lerp(blood_overlay.modulate.a, 0.8, delta * 0.2)
		_shake_camera(2.0)
	
	current_stability = clamp(current_stability, 0.0, 110.0) # Buffer extra
	progress_bar.value = current_stability
	
	if current_stability >= stability_target:
		_win_phase()
	elif current_stability <= 0 and blood_overlay.modulate.a > 0.7:
		# Se a estabilidade zerar e o sangue estiver muito alto
		# _lose_phase()
		pass

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 1.0).set_delay(0.5)

func _shake_camera(intensity: float) -> void:
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity

func _win_phase() -> void:
	set_process(false)
	SaveManager.game_data["completed_phases"].append("hemorragia")
	SaveManager.save_game()
	
	feedback_label.text = "SANGRAMENTO ESTANCADO!"
	feedback_label.modulate = Color.GREEN
	feedback_label.modulate.a = 1.0
	
	await get_tree().create_timer(2.0).timeout
	EventBus.transition_started.emit("res://scenes/phases/Desfibrilador_Intro.tscn")

func _lose_phase() -> void:
	set_process(false)
	defeat_overlay.show()
	await get_tree().create_timer(3.0).timeout
	EventBus.transition_started.emit("res://scenes/phases/Hemorragia_Intro.tscn")
