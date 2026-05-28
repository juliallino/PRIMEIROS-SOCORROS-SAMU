extends Control

@onready var start_button = $UIIayer/MainContainer/Buttons/StartButton
@onready var quit_button = $UIIayer/MainContainer/Buttons/QuitButton
@onready var info_button = $UIIayer/MainContainer/Buttons/InfoButton
@onready var info_popup = $UIIayer/InfoPopup

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MENU)
	AudioManager.play_ambient("res://assets/audios/audio_ambiente.mp3")
	
	# Conectar botões
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	info_button.pressed.connect(_on_info_pressed)
	
	# Efeito de hover suave para todos os botões no container
	for btn in $UIIayer/MainContainer/Buttons.get_children():
		if btn is Button:
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_exit.bind(btn))

	print("Menu Principal carregado.")

func _on_start_pressed() -> void:
	print("Iniciando Plantão...")
	GameManager.reset_stats()
	# Acionar transição cinematográfica
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")

func _on_info_pressed() -> void:
	info_popup.popup_centered()

func _on_quit_pressed() -> void:
	print("Saindo do jogo...")
	get_tree().quit()

func _on_button_hover(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	# Adicionar um leve glow via modulate se desejar
	btn.modulate = Color(1.2, 1.2, 1.5) 

func _on_button_exit(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	btn.modulate = Color.WHITE
