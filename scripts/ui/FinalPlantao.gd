extends Control

@onready var stats_label = $UIIayer/StatsContainer/StatsText
@onready var title_label = $UIIayer/CenterContainer/VBoxContainer/Title
@onready var message_label = $UIIayer/CenterContainer/VBoxContainer/Message
@onready var back_button = $UIIayer/CenterContainer/VBoxContainer/HBoxContainer/BackButton
@onready var new_shift_button = $UIIayer/CenterContainer/VBoxContainer/HBoxContainer/NewShiftButton

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.GAME_OVER)
	_calculate_and_display_stats()
	_save_total_completion()
	
	back_button.pressed.connect(_on_back_pressed)
	new_shift_button.pressed.connect(_on_new_shift_pressed)
	
	# Efeitos sonoros de encerramento
	# AudioManager.play_ambient("res://assets/audio/chuva_suave_fim.ogg")
	# AudioManager.play_sfx("res://assets/audio/sirene_longe.wav")

func _calculate_and_display_stats() -> void:
	# Aqui buscaríamos dados reais acumulados no GameManager ou SaveManager
	var phases_done = SaveManager.game_data.get("completed_phases", []).size()
	var total_errors = 0 # Placeholder para lógica de contagem global
	var precision = "92%" # Placeholder
	
	var stats_text = "ESTATÍSTICAS DO PLANTÃO\n\n"
	stats_text += "Fases Concluídas: %d / 4\n" % phases_done
	stats_text += "Erros Cometidos: %d\n" % total_errors
	stats_text += "Precisão Médica: %s\n" % precision
	
	stats_label.text = stats_text

func _save_total_completion() -> void:
	SaveManager.game_data["game_finished"] = true
	SaveManager.save_game()

func _on_back_pressed() -> void:
	EventBus.transition_started.emit("res://scenes/ui/MainMenu.tscn")

func _on_new_shift_pressed() -> void:
	# Reiniciar progresso e ir para a primeira fase
	SaveManager.game_data["completed_phases"] = []
	SaveManager.save_game()
	EventBus.transition_started.emit("res://scenes/phases/Asfixia_Intro.tscn")
