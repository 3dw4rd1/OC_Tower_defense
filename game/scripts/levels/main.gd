extends Node2D

@onready var _enemies_container: Node2D = $EnemiesContainer
@onready var _towers_container: Node2D = $TowersContainer
@onready var _obstacles_container: Node2D = $ObstaclesContainer
@onready var _game_map: TileMap = $GameMap


func _ready() -> void:
	WaveManager.set_enemies_parent(_enemies_container)
	_game_map.set_towers_container(_towers_container)
	TerrainManager.initialise(_game_map, _obstacles_container)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var s: GameManager.GameState = GameManager.state
		if s == GameManager.GameState.SETUP or s == GameManager.GameState.WAVE_COMPLETE:
			GameManager.start_next_wave()
