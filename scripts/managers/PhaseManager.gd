extends Node

var current_phase_data = {
	"id": "",
	"time_left": 60.0,
	"fail_count": 0,
	"max_fails": 3
}

func _ready() -> void:
	EventBus.phase_started.connect(_on_phase_started)

func _on_phase_started(phase_id: String) -> void:
	current_phase_data["id"] = phase_id
	current_phase_data["time_left"] = 60.0 # Reset
	current_phase_data["fail_count"] = 0

func register_fail() -> void:
	current_phase_data["fail_count"] += 1
	if current_phase_data["fail_count"] >= current_phase_data["max_fails"]:
		EventBus.phase_completed.emit(current_phase_data["id"], false)

func complete_phase() -> void:
	EventBus.phase_completed.emit(current_phase_data["id"], true)
