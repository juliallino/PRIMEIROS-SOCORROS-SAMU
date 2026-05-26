extends Control

@onready var start_button = $UIIayer/MainContainer/Buttons/StartButton
@onready var info_button = $UIIayer/MainContainer/Buttons/InfoButton
@onready var reset_button = $UIIayer/MainContainer/Buttons/ResetButton
@onready var info_popup = $UIIayer/InfoPopup
@onready var medical_report_list = $UIIayer/MainContainer/MedicalReport/StatsList

func _ready() -> void:
	# Conectar botões
	start_button.pressed.connect(_on_start_pressed)
	info_button.pressed.connect(_on_info_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# Efeito de hover suave para todos os botões no container
	for btn in $UIIayer/MainContainer/Buttons.get_children():
		if btn is Button:
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.mouse_exited.connect(_on_button_exit.bind(btn))

	# Atualizar o prontuário com dados do SaveManager
	_update_medical_report()
	
	# Iniciar sons ambientes (Se os assets existirem)
	# AudioManager.play_ambient("res://assets/audio/chuva_ambiente.ogg")
	# AudioManager.play_sfx("res://assets/audio/sirene_distante.wav")
	
	print("Menu Principal carregado.")

func _update_medical_report() -> void:
	# Limpar lista placeholder e popular com dados reais
	for child in medical_report_list.get_children():
		child.queue_free()
		
	var phases = ["Asfixia", "Parada Cardíaca", "Hemorragia", "Desfibrilador"]
	var completed = SaveManager.game_data.get("completed_phases", [])
	
	for phase in phases:
		var hbox = HBoxContainer.new()
		var lbl_name = Label.new()
		lbl_name.text = phase
		lbl_name.size_flags_horizontal = SIZE_EXPAND_FILL
		
		var lbl_status = Label.new()
		if phase in completed:
			lbl_status.text = "CONCLUÍDO"
			lbl_status.modulate = Color.GREEN
		else:
			lbl_status.text = "BLOQUEADO"
			lbl_status.modulate = Color.GRAY
			
		hbox.add_child(lbl_name)
		hbox.add_child(lbl_status)
		medical_report_list.add_child(hbox)

func _on_start_pressed() -> void:
	print("Iniciando Plantão...")
	# Acionar transição cinematográfica
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")

func _on_info_pressed() -> void:
	info_popup.popup_centered()

func _on_reset_pressed() -> void:
	# Lógica para resetar o progresso
	SaveManager.game_data["completed_phases"] = []
	SaveManager.save_game()
	_update_medical_report()
	print("Progresso resetado.")

func _on_button_hover(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
	# Adicionar um leve glow via modulate se desejar
	btn.modulate = Color(1.2, 1.2, 1.5) 

func _on_button_exit(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	btn.modulate = Color.WHITE
