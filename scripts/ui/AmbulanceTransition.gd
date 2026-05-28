extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var radio_timer: Timer = $RadioTimer
@onready var rain_particles: GPUParticles2D = $RainParticles
@onready var smoke_particles: GPUParticles2D = $SmokeParticles
@onready var siren_red: ColorRect = $SirenRed
@onready var siren_blue: ColorRect = $SirenBlue
@onready var ambulance_audio: AudioStreamPlayer = $AmbulanceAudio
@onready var rain_audio: AudioStreamPlayer = $RainAudio

var radio_dialogues = [
	"Central para unidade móvel. Prossigam com cautela.",
	"Nova ocorrência registrada no setor 4. Prioridade Alfa.",
	"Paciente em estado crítico. ETA de dois minutos.",
	"Equipe, mantenham foco. O trânsito está pesado à frente.",
	"Unidade 03, confirme recebimento da coordenada.",
	"Suporte avançado solicitado no local.",
	"Informações preliminares indicam parada cardiorrespiratória.",
	"Atenção equipe, tempo estimado de chegada: 3 minutos."
]

@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	# Mensagem padrão cinematográfica
	message_label.text = "A CAMINHO DO PRÓXIMO CHAMADO"
	message_label.modulate.a = 0
	
	# Iniciar efeitos
	animation_player.play("ambulance_loop")
	_start_cinematic_effects()
	_start_radio_chatter()

func _start_cinematic_effects() -> void:
	# Pulsação lenta da mensagem (legibilidade)
	var tween = create_tween().set_loops()
	tween.tween_property(message_label, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(message_label, "modulate:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)
	
	# Adicionar flashes mais espaçados para a nova duração
	_trigger_random_flicker()

func _trigger_random_flicker() -> void:
	if not is_inside_tree(): return
	
	# Menor frequência para não cansar o jogador em 6 segundos
	if randf() > 0.85:
		EventBus.sfx_played.emit("res://assets/audio/sfx/electrical_zap.wav")
		animation_player.play("flicker")
		await animation_player.animation_finished
		animation_player.play("ambulance_loop")
	
	get_tree().create_timer(randf_range(1.0, 2.0)).timeout.connect(_trigger_random_flicker)

func _start_radio_chatter() -> void:
	_play_random_radio()
	radio_timer.wait_time = randf_range(3.0, 5.0)
	radio_timer.timeout.connect(_play_random_radio)
	radio_timer.start()

func _play_random_radio() -> void:
	var msg = radio_dialogues.pick_random()
	print("[RADIO SAMU]: ", msg)
	# Aqui poderíamos emitir um sinal para o DialogueManager ou UIManager mostrar legenda
	# EventBus.notification_triggered.emit(msg, "radio")
	
	# Efeito sonoro de rádio (bip/estática)
	# EventBus.sfx_played.emit("res://assets/audio/sfx/radio_static.wav")

func stop_all() -> void:
	radio_timer.stop()
	animation_player.stop()
