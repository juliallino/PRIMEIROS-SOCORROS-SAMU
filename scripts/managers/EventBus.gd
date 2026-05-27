extends Node

# --- SINAIS GLOBAIS ---

# Transições e Fluxo
signal transition_started(scene_path: String)
signal cinematic_transition_requested(scene_path: String)
signal transition_finished

# Jogo e Fases
signal phase_started(phase_id: String)
signal intro_started(phase_id: String)
signal phase_completed(phase_id: String, success: bool)
signal checkpoint_reached(checkpoint_id: String)

# Narrativa
signal dialogue_started(dialogue_id: String)
signal dialogue_finished

# Feedback e UI
signal notification_triggered(message: String, type: String)
signal score_updated(new_score: int)

# Áudio
signal music_change_requested(track_name: String)
signal sfx_played(sfx_name: String)
