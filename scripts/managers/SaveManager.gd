extends Node

const SAVE_PATH = "user://savegame.json"

var game_data = {
	"current_phase": "phase_01",
	"completed_phases": [],
	"checkpoints": {},
	"settings": {
		"volume_master": 0.8,
		"volume_music": 0.7,
		"volume_sfx": 1.0
	}
}

func _ready() -> void:
	load_game()
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.phase_completed.connect(_on_phase_completed)

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(game_data)
		file.store_string(json_string)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			game_data = json.data
		file.close()

func _on_checkpoint_reached(checkpoint_id: String) -> void:
	game_data["checkpoints"][GameManager.current_state] = checkpoint_id # Exemplo simplificado
	save_game()

func _on_phase_completed(phase_id: String, success: bool) -> void:
	if success and not phase_id in game_data["completed_phases"]:
		game_data["completed_phases"].append(phase_id)
		save_game()
