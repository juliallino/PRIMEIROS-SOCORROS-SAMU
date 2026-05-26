extends CanvasLayer

# Este Manager controlará telas sobrepostas e notificações
# Pode ser expandido para carregar cenas de UI dinamicamente

func _ready() -> void:
	EventBus.notification_triggered.connect(show_notification)

func show_notification(message: String, _type: String) -> void:
	# Implementar popup ou label temporário
	print("NOTIFICAÇÃO: ", message)

func open_pause_menu() -> void:
	# Instanciar cena de pause
	pass
