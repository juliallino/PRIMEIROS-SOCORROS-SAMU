extends Node2D

@onready var charge_progress = $UILayer/ChargeProgress
@onready var feedback_label = $UILayer/FeedbackLabel
@onready var camera = $Camera2D
@onready var timing_bar = $UILayer/TimingSystem/Bar
@onready var timing_indicator = $UILayer/TimingSystem/Indicator
@onready var timing_zone = $UILayer/TimingSystem/GreenZone
@onready var flash_overlay = $UILayer/FlashOverlay
@onready var shock_particles = $ShockParticles

@onready var error_label = $UILayer/ErrorCounter
@onready var defeat_overlay = $UILayer/DefeatOverlay
@onready var victory_overlay = $UILayer/VictoryOverlay
@onready var phase_audio = $PhaseAudio

# Configurações de Gameplay
var is_charging: bool = false
var charge_value: float = 0.0
var max_charge: float = 100.0
var is_timing_active: bool = false
var indicator_pos: float = 0.0
var indicator_direction: int = 1
var indicator_speed: float = 400.0

var error_count: int = 0
var max_errors: int = 5
var game_active: bool = true

func _ready() -> void:
	EventBus.phase_started.emit("desfibrilador")
	EventBus.phase_restart_requested.connect(_on_restart_requested)
	charge_progress.value = 0
	$UILayer/TimingSystem.hide()
	flash_overlay.modulate.a = 0
	_update_ui()
	if phase_audio:
		phase_audio.play()

func _process(delta: float) -> void:
	if not game_active: return
	_handle_charging(delta)
	_handle_timing(delta)
	_update_audio_effects(delta)

func _update_audio_effects(_delta: float) -> void:
	if not phase_audio or not phase_audio.playing: return
	
	# Tensão crescente baseada no carregamento e erros
	var target_pitch = 1.0 + (charge_value / max_charge) * 0.15 + (float(error_count) / max_errors) * 0.2
	var target_volume = -6.0 + (charge_value / max_charge) * 6.0 # Começa baixo (-6dB) e sobe até 0dB no pico
	
	# Interpolação suave para evitar cliques
	phase_audio.pitch_scale = lerp(phase_audio.pitch_scale, target_pitch, 0.1)
	phase_audio.volume_db = lerp(phase_audio.volume_db, target_volume, 0.1)
	
	# Simulação de distorção elétrica leve (vibrato rápido aleatório)
	if is_charging:
		phase_audio.pitch_scale += randf_range(-0.02, 0.02)
		phase_audio.volume_db += randf_range(-0.5, 0.5)

func _reset_attempt() -> void:
	print("[DEBUG] Reiniciando tentativa de choque. Resetando flags.")
	is_charging = false
	is_timing_active = false
	charge_value = 0.0
	charge_progress.value = 0.0
	indicator_pos = 0.0
	indicator_direction = 1
	$UILayer/TimingSystem.hide()
	
	# Garantir que o overlay de feedback visual não trave
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)

func _handle_charging(delta: float) -> void:
	var s_pressed = Input.is_key_pressed(KEY_S)
	var k_pressed = Input.is_key_pressed(KEY_K)
	
	if s_pressed and k_pressed:
		if not is_timing_active:
			if not is_charging:
				print("[DEBUG] Iniciando carregamento...")
			is_charging = true
			charge_value += 35 * delta
			charge_progress.value = charge_value
			_show_feedback("CARREGANDO...", Color.YELLOW)
			_shake_camera(charge_value * 0.05)
			
			if charge_value >= max_charge:
				_start_timing_phase()
	elif s_pressed or k_pressed:
		if is_charging:
			is_charging = false
			charge_value = max(0, charge_value - 20 * delta)
			charge_progress.value = charge_value
	else:
		if is_charging and not is_timing_active:
			is_charging = false
			charge_value = max(0, charge_value - 50 * delta)
			charge_progress.value = charge_value

func _start_timing_phase() -> void:
	print("[DEBUG] Desfibrilador carregado! Iniciando fase de timing.")
	is_charging = false
	is_timing_active = true
	$UILayer/TimingSystem.show()
	_show_feedback("AGORA! CLIQUE NO VERDE!", Color.CYAN)
	EventBus.sfx_played.emit("res://assets/audio/sfx/defib_ready.wav")

func _handle_timing(delta: float) -> void:
	if not is_timing_active: return
	
	indicator_pos += indicator_speed * indicator_direction * delta
	var bar_width = timing_bar.size.x
	
	if indicator_pos >= bar_width:
		indicator_pos = bar_width
		indicator_direction = -1
	elif indicator_pos <= 0:
		indicator_pos = 0
		indicator_direction = 1
	
	timing_indicator.position.x = indicator_pos

func _input(event: InputEvent) -> void:
	if not game_active: return
	
	if event is InputEventMouseButton and event.pressed:
		print("[DEBUG] Clique detectado. State: timing=", is_timing_active, " charging=", is_charging)
		if is_timing_active:
			_check_timing_hit()
		elif is_charging:
			_handle_error("DESFIBRILADOR NÃO CARREGADO")
			_reset_attempt()
		else:
			# Clique aleatório sem estar carregando nada
			pass

func _check_timing_hit() -> void:
	var indicator_center = timing_indicator.position.x
	var zone_start = timing_zone.position.x
	var zone_end = zone_start + timing_zone.size.x
	
	print("[DEBUG] Checando timing. Pos: ", indicator_center, " Zone: ", zone_start, "-", zone_end)
	
	if indicator_center >= zone_start and indicator_center <= zone_end:
		_on_successful_shock()
	else:
		_on_failed_shock()

func _on_successful_shock() -> void:
	print("[DEBUG] Choque bem sucedido!")
	is_timing_active = false
	$UILayer/TimingSystem.hide()
	
	# Parar áudio imediatamente
	if phase_audio:
		var tween = create_tween()
		tween.tween_property(phase_audio, "volume_db", -80.0, 0.5)
		tween.finished.connect(func(): phase_audio.stop())
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	_apply_shock_effects()
	
	# Desaceleração cinematográfica
	Engine.time_scale = 0.5
	
	_show_feedback("CHOQUE APLICADO!", Color.GREEN)
	
	# Mostrar Overlay de Vitória
	if victory_overlay:
		await victory_overlay.show_victory()
		
	# Restaurar tempo
	Engine.time_scale = 1.0
	
	EventBus.phase_completed.emit("desfibrilador", true)
	SaveManager.game_data["completed_phases"].append("desfibrilador")
	SaveManager.save_game()
	
	game_active = false
	EventBus.transition_started.emit("res://scenes/ui/FinalPlantao.tscn")

func _on_restart_requested() -> void:
	if not game_active: return
	game_active = false
	print("[Desfibrilador] Reiniciando fase...")
	if phase_audio: phase_audio.stop()
	EventBus.transition_started.emit("res://scenes/phases/Desfibrilador_Intro.tscn")

func _on_failed_shock() -> void:
	print("[DEBUG] Choque falhou (timing incorreto).")
	_handle_error("TEMPO INCORRETO")
	_reset_attempt()

func _handle_error(msg: String) -> void:
	error_count += 1
	EventBus.error_reported.emit()
	print("[DEBUG] Erro contabilizado. Total: ", error_count, "/", max_errors)
	_update_ui()
	_shake_camera(20.0)
	_show_feedback(msg, Color.ORANGE)
	
	# Efeito visual de erro
	var tween = create_tween()
	flash_overlay.modulate = Color(1, 0, 0, 0.3)
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.4)
	
	EventBus.sfx_played.emit("res://assets/audio/sfx/monitor_error.wav")
	
	if error_count >= max_errors:
		_lose()

func _update_ui() -> void:
	error_label.text = "FALHAS: %d / %d" % [error_count, max_errors]
	if error_count >= max_errors - 1:
		error_label.modulate = Color.RED

func _lose() -> void:
	game_active = false
	
	# Esconder botões de interface
	UIManager.hide_restart_button()
	UIManager.toggle_pause_button(false)
	
	EventBus.phase_completed.emit("desfibrilador", false)
	
	if phase_audio:
		var tween = create_tween()
		tween.tween_property(phase_audio, "volume_db", -40.0, 0.5)
		tween.finished.connect(func(): phase_audio.stop())
		
	if defeat_overlay:
		defeat_overlay.show()
		defeat_overlay.modulate.a = 0
		
		var messages = [
			"Precisamos tentar novamente.",
			"O paciente ainda está em risco.",
			"Mantenha o foco.",
			"Prepare outro choque."
		]
		var msg_label = defeat_overlay.get_node_or_null("Message")
		if msg_label:
			msg_label.text = messages.pick_random()
			
		var tween = create_tween()
		tween.tween_property(defeat_overlay, "modulate:a", 1.0, 1.5)
	
	# Abafar sons
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 0, true)
	
	await get_tree().create_timer(4.0).timeout
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 0, false)
	# Voltar para a intro do Desfibrilador
	EventBus.transition_started.emit("res://scenes/phases/Desfibrilador_Intro.tscn")

func _apply_shock_effects() -> void:
	# Flash branco forte
	flash_overlay.modulate = Color.WHITE
	flash_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 1.5)
	
	# Shake violento
	_shake_camera(40.0)
	
	# Partículas elétricas
	shock_particles.restart()
	shock_particles.emitting = true
	
	# Som de choque
	EventBus.sfx_played.emit("res://assets/audio/sfx/defib_shock.wav")

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
