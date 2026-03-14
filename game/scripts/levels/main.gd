extends Node2D

@onready var _enemies_container: Node2D = $EnemiesContainer


func _ready() -> void:
	WaveManager.set_enemies_parent(_enemies_container)
	_run_test_spawner()


func _run_test_spawner() -> void:
	# TODO: Remove after pathfinding verified
	var packed: PackedScene = load("res://scenes/enemies/EnemyBasic.tscn")
	for i: int in range(3):
		if i > 0:
			await get_tree().create_timer(0.5).timeout
		var enemy: CharacterBody2D = packed.instantiate() as CharacterBody2D
		enemy.position = PathfindingManager.tile_to_world(Vector2i(0, 0))
		_enemies_container.add_child(enemy)
