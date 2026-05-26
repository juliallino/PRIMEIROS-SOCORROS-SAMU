# PLANTÃO PRIMEIROS SOCORROS SAMU - Guia de Desenvolvimento

Este projeto utiliza **Godot 4.3+** com uma arquitetura baseada em **EventBus** para desacoplamento de sistemas.

## Arquitetura de Comunicação (EventBus)
Toda a comunicação entre sistemas globais (Managers) e cenas de fases deve ser feita através do singleton `EventBus`.
Exemplo:
```gdscript
EventBus.emit_signal("phase_completed", "asfixia", true)
```

## Sistemas Globais (Autoloads)
1. **EventBus**: Central de sinais.
2. **GameManager**: Estado global (Menu, Jogando, Pausado).
3. **SaveManager**: Persistência em `user://savegame.json`.
4. **AudioManager**: Controle de trilha sonora e efeitos.
5. **TransitionManager**: Fades e carregamento de cenas.
6. **DialogueManager**: Lógica de diálogos.
7. **PhaseManager**: Lógica específica da missão atual.
8. **UIManager**: Overlays globais.

## Convenções de Código
- Use **GDScript** com tipagem estática sempre que possível (`var x: int = 0`).
- Sinais globais devem ser definidos no `EventBus.gd`.
- Cenas de fases não devem carregar outras cenas diretamente; use `EventBus.transition_started.emit(path)`.

## Visual e Atmosfera
- Use `WorldEnvironment` para efeitos de **Glow** e **Color Correction**.
- Partículas de chuva devem ser instanciadas via `GPUParticles2D`.
- Sirenes devem ser simuladas com `PointLight2D` (vermelho/azul) e `AnimationPlayer`.
