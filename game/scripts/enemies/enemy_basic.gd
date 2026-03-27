extends CharacterBody2D

signal died

var speed: float = 80.0
var damage: int = 1
var _hp: int = 30
var _enemy_type: String = "basic"
var _path: Array[Vector2] = []
var _path_index: int = 0
var _speed_multiplier: float = 1.0
var _slow_timer: float = 0.0

var BASE_TILE: Vector2i = PathfindingManager.BASE_TILE


func _ready() -> void:
	PathfindingManager.obstacle_changed.connect(_recalculate_path)


func _physics_process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_speed_multiplier = 1.0

	if _path.is_empty():
		_recalculate_path()
		return
	if _path_index >= _path.size():
		return

	var target: Vector2 = _path[_path_index]
	if global_position.distance_to(target) < 4.0:
		_path_index += 1
		return

	# Slow tile terrain check (Step 7): tiles placed by Dead Ground card slow to 70%
	var my_tile: Vector2i = PathfindingManager.world_to_tile(global_position)
	var terrain_mult: float = 0.7 if TerrainManager.is_slow_tile(my_tile) else 1.0
	velocity = (target - global_position).normalized() * speed * _speed_multiplier * terrain_mult
	move_and_slide()


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()


func apply_slow(factor: float, duration: float) -> void:
	_speed_multiplier = 1.0 - factor
	_slow_timer = duration


func reach_base() -> void:
	# Enemy reached the base — no kill gold awarded
	died.emit()
	queue_free()


func _die() -> void:
	EconomyManager.award_kill_gold(_enemy_type, GameManager.current_wave)
	died.emit()
	queue_free()


func _recalculate_path() -> void:
	if not is_inside_tree():
		return
	var my_tile: Vector2i = PathfindingManager.world_to_tile(global_position)
	_path = PathfindingManager.get_astar_path(my_tile, BASE_TILE)
	_path_index = 0
