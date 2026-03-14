extends CharacterBody2D

signal died

const SPEED: float = 80.0
const DAMAGE: int = 1

var _hp: int = 30
var _path: Array[Vector2] = []
var _path_index: int = 0

const BASE_TILE: Vector2i = Vector2i(16, 16)


func _physics_process(_delta: float) -> void:
	if _path.is_empty():
		_recalculate_path()
		return
	if _path_index >= _path.size():
		return

	var target: Vector2 = _path[_path_index]
	if global_position.distance_to(target) < 4.0:
		_path_index += 1
		return

	velocity = (target - global_position).normalized() * SPEED
	move_and_slide()


func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()


func reach_base() -> void:
	# Enemy reached the base — no kill gold awarded
	died.emit()
	queue_free()


func _die() -> void:
	EconomyManager.award_kill_gold("basic")
	died.emit()
	queue_free()


func _recalculate_path() -> void:
	var my_tile: Vector2i = PathfindingManager.world_to_tile(global_position)
	_path = PathfindingManager.get_path(my_tile, BASE_TILE)
	_path_index = 0
