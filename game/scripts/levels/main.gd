extends Node2D

@onready var _enemies_container: Node2D = $EnemiesContainer


func _ready() -> void:
	WaveManager.set_enemies_parent(_enemies_container)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var s: GameManager.GameState = GameManager.state
		if s == GameManager.GameState.SETUP or s == GameManager.GameState.WAVE_COMPLETE:
			GameManager.start_next_wave()
