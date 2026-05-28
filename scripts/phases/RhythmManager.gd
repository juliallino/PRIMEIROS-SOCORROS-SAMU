extends AudioStreamPlayer

## Gerencia o áudio rítmico da RCP, sincronizando com o estado do paciente.

var is_playing_rhythm: bool = false

func _ready() -> void:
	if stream:
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif stream is AudioStreamMP3:
			stream.loop = true
	
	stop()
	volume_db = 0.0

func start_rhythm() -> void:
	if is_playing_rhythm: return
	is_playing_rhythm = true
	
	if not playing:
		play()
	
	print("[RhythmManager] Áudio rítmico iniciado.")

func stop_rhythm(smooth: bool = true) -> void:
	is_playing_rhythm = false
	stop()
	print("[RhythmManager] Áudio rítmico parado.")
