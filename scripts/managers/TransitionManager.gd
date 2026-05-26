extends CanvasLayer

@onready var color_rect = ColorRect.new()
@onready var animation_player = AnimationPlayer.new()

func _ready() -> void:
	layer = 128 # Garante que está acima de tudo
	color_rect.color = Color.BLACK
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0
	add_child(color_rect)
	
	add_child(animation_player)
	var library = AnimationLibrary.new()
	animation_player.add_animation_library("", library)
	
	# Criar animação de fade programaticamente
	_create_fade_animations(library)
	
	EventBus.transition_started.connect(change_scene)

func _create_fade_animations(library: AnimationLibrary) -> void:
	var fade_out = Animation.new()
	var track = fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(track, "color_rect:modulate:a")
	fade_out.track_insert_key(track, 0.0, 0.0)
	fade_out.track_insert_key(track, 0.5, 1.0)
	library.add_animation("fade_out", fade_out)
	
	var fade_in = Animation.new()
	track = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(track, "color_rect:modulate:a")
	fade_in.track_insert_key(track, 0.0, 1.0)
	fade_in.track_insert_key(track, 0.5, 0.0)
	library.add_animation("fade_in", fade_in)

func change_scene(target_path: String) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	get_tree().change_scene_to_file(target_path)
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.transition_finished.emit()
