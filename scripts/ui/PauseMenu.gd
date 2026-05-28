extends CanvasLayer

@onready var blur_rect = $Control/BlurRect
@onready var menu_container = $Control/MenuContainer
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	blur_rect.modulate.a = 0
	menu_container.modulate.a = 0
	menu_container.scale = Vector2(0.9, 0.9)

func open() -> void:
	visible = true
	GameManager.set_state(GameManager.GameState.PAUSED)
	
	# Animação de entrada
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 1.0, 0.3)
	tween.tween_property(menu_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(menu_container, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	# Animação de saída
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 0.0, 0.2)
	tween.tween_property(menu_container, "modulate:a", 0.0, 0.2)
	tween.tween_property(menu_container, "scale", Vector2(0.9, 0.9), 0.2)
	
	await tween.finished
	
	# Restaurar estado
	GameManager.set_state(GameManager.GameState.PLAYING)
	
	visible = false

func force_close() -> void:
	# Limpeza instantânea sem animações para trocas de cena
	get_tree().paused = false
	visible = false
	
	# Garantir que todos os componentes visuais estão resetados
	if blur_rect:
		blur_rect.modulate.a = 0
	if menu_container:
		menu_container.modulate.a = 0
		menu_container.scale = Vector2(0.9, 0.9)
	
	print("[PauseMenu] UI de pause encerrada forçadamente e limpa.")

func _on_continue_pressed() -> void:
	print("[PauseMenu] Botão Continuar pressionado.")
	close()

func _on_menu_pressed() -> void:
	print("[PauseMenu] Botão Menu pressionado.")
	UIManager.return_to_main_menu()

func _on_quit_pressed() -> void:
	print("[PauseMenu] Botão Sair pressionado.")
	get_tree().quit()
