extends Node

var is_dialogue_active: bool = false
var current_dialogue_data = []
var current_line_index: int = 0

func _ready() -> void:
	EventBus.dialogue_started.connect(start_dialogue)

func start_dialogue(dialogue_id: String) -> void:
	# Aqui você carregaria um JSON ou similar baseado no ID
	is_dialogue_active = true
	current_line_index = 0
	# Placeholder
	current_dialogue_data = [
		{"speaker": "Rádio", "text": "Atenção equipe 01, temos um código azul na rua 10."},
		{"speaker": "Parceiro", "text": "Entendido, central. Estamos a caminho."}
	]
	show_next_line()

func show_next_line() -> void:
	if current_line_index < current_dialogue_data.size():
		var line = current_dialogue_data[current_line_index]
		# Emitir para a UI mostrar
		# UIManager.show_dialogue(line.speaker, line.text)
		current_line_index += 1
	else:
		finish_dialogue()

func finish_dialogue() -> void:
	is_dialogue_active = false
	EventBus.dialogue_finished.emit()
