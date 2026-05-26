extends Node2D

@onready var charge_progress = $UILayer/ChargeProgress
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var camera = $Camera2D
@onready var timing_bar = $UILayer/TimingSystem/Bar
@onready var timing_indicator = $UILayer/TimingSystem/Indicator
@onready var timing_zone = $UILayer/TimingSystem/GreenZone
@onready var flash_overlay = $UILayer/FlashOverlay
@onready var shock_particles = $ShockParticles

# Configurações de Gameplay
var is_charging: bool = false
var charge_value: float = 0.0
var max_charge: float = 100.0
var is_timing_active: bool = false
var indicator_pos: float = 0.0
var indicator_direction: int = 1
var indicator_speed: float = 400.0

func _ready() -> void:
	charge_progress.value = 0
	$UILayer/TimingSystem.hide()
	flash_overlay.modulate.a = 0

func _process(delta: float) -> void:
	_handle_charging(delta)
	_handle_timing(delta)

func _handle_charging(delta: float) -> void:
	if Input.is_key_pressed(KEY_S) and Input.is_key_pressed(KEY_K):
		if not is_timing_active:
			is_charging = true
			charge_value += 30 * delta
			charge_progress.value = charge_value
			_show_feedback("CARREGANDO...", Color.YELLOW)
			_shake_camera(charge_value * 0.05)
			
			if charge_value >= max_charge:
				_start_timing_phase()
	else:
		if is_charging and not is_timing_active:
			is_charging = false
			charge_value = max(0, charge_value - 50 * delta)
			charge_progress.value = charge_value

func _start_timing_phase() -> void:
	is_charging = false
	is_timing_active = true
	$UILayer/TimingSystem.show()
	_show_feedback("AGORA! CLIQUE NO VERDE COM O MOUSE!", Color.CYAN)

func _handle_timing(delta: float) -> void:
	if not is_timing_active: return
	
	indicator_pos += indicator_speed * indicator_direction * delta
	var bar_width = timing_bar.size.x
	
	if indicator_pos >= bar_width or indicator_pos <= 0:
		indicator_direction *= -1
	
	timing_indicator.position.x = indicator_pos

func _input(event: InputEvent) -> void:
	if is_timing_active and event is InputEventMouseButton and event.pressed:
		_check_timing_hit()

func _check_timing_hit() -> void:
	var indicator_center = timing_indicator.position.x
	var zone_start = timing_zone.position.x
	var zone_end = zone_start + timing_zone.size.x
	
	if indicator_center >= zone_start and indicator_center <= zone_end:
		_on_successful_shock()
	else:
		_on_failed_shock()

func _on_successful_shock() -> void:
	is_timing_active = false
	_apply_shock_effects()
	_show_feedback("CHOQUE APLICADO!", Color.GREEN)
	
	SaveManager.game_data["completed_phases"].append("desfibrilador")
	SaveManager.save_game()
	
	await get_tree().create_timer(3.0).timeout
	EventBus.transition_started.emit("res://scenes/phases/FinalPlantao.tscn")

func _on_failed_shock() -> void:
	is_timing_active = false
	$UILayer/TimingSystem.hide()
	charge_value = 0
	charge_progress.value = 0
	_show_feedback("TEMPO ERRADO!", Color.RED)
	_shake_camera(20.0)
	# Opcional: registrar erro no PhaseManager

func _apply_shock_effects() -> void:
	# Flash branco
	flash_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 1.5)
	
	# Shake violento
	_shake_camera(40.0)
	
	# Partículas elétricas
	shock_particles.emitting = true
	
	# Som explosivo (Se houver)
	# AudioManager.play_sfx("res://assets/audio/defib_shock.wav")

func _shake_camera(intensity: float) -> void:
	var tween = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity
		tween.tween_property(camera, "offset", offset, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5).set_delay(0.5)
