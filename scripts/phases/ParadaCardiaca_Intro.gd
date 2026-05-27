extends Control

@onready var dialogue_text = $UILayer/DialogueBox/Text
@onready var dialogue_speaker = $UILayer/DialogueBox/Speaker
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	EventBus.intro_started.emit("parada_cardiaca")
	# Iniciar efeitos sonoros e monitor
	# AudioManager.play_ambient("res://assets/audio/chuva_chuva_ritmica.ogg")
	# AudioManager.play_sfx("res://assets/audio/monitor_flatline.wav")
	pass

func update_dialogue(speaker: String, text: String) -> void:
	dialogue_speaker.text = speaker
	_type_text(text)

func _type_text(full_text: String) -> void:
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0
	for i in range(full_text.length()):
		dialogue_text.visible_characters += 1
		await get_tree().create_timer(0.03).timeout

func _start_mission() -> void:
	print("Transição para Gameplay: Massagem Cardíaca")
	EventBus.transition_started.emit("res://scenes/phases/MassagemCardiaca_Gameplay.tscn")
