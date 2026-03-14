extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_complete

const TOTAL_WAVES: int = 10
const SPAWN_DELAY: float = 0.5

const WAVE_DATA: Array = [
	{"basic": 5},
	{"basic": 8},
	{"basic": 10},
	{"basic": 8, "fast": 4},
	{"fast": 10},
	{"basic": 6, "fast": 6, "tank": 1},
	{"tank": 4},
	{"basic": 10, "fast": 6},
	{"tank": 4, "fast": 8},
	{"basic": 10, "fast": 10, "tank": 6},
]

const ENEMY_SCENES: Dictionary = {
	"basic": "res://scenes/enemies/EnemyBasic.tscn",
	"fast":  "res://scenes/enemies/EnemyFast.tscn",
	"tank":  "res://scenes/enemies/EnemyTank.tscn",
}

var _alive_count: int = 0
var _total_to_spawn: int = 0
var _total_spawned: int = 0
var _spawn_queue: Array[String] = []
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _wave_done: bool = false
var _enemies_parent: Node = null


func set_enemies_parent(parent: Node) -> void:
	_enemies_parent = parent


func start_wave(wave_num: int) -> void:
	if wave_num < 1 or wave_num > TOTAL_WAVES:
		return
	var data: Dictionary = WAVE_DATA[wave_num - 1]
	_spawn_queue.clear()
	for enemy_type: String in data:
		for _i: int in range(data[enemy_type]):
			_spawn_queue.append(enemy_type)
	_spawn_queue.shuffle()
	_total_to_spawn = _spawn_queue.size()
	_total_spawned = 0
	_alive_count = 0
	_spawn_timer = 0.0
	_is_spawning = true
	_wave_done = false
	wave_started.emit(wave_num)


func _process(delta: float) -> void:
	if not _is_spawning or _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_DELAY
		_do_spawn(_spawn_queue.pop_front())
		if _spawn_queue.is_empty():
			_is_spawning = false


func _do_spawn(enemy_type: String) -> void:
	_total_spawned += 1
	if _enemies_parent == null:
		push_warning("WaveManager: enemies parent not set")
		_check_wave_complete()
		return
	var scene_path: String = ENEMY_SCENES.get(enemy_type, "") as String
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("WaveManager: missing scene for enemy type: " + enemy_type)
		_check_wave_complete()
		return
	var packed: PackedScene = load(scene_path)
	var enemy: Node2D = packed.instantiate() as Node2D
	enemy.position = _get_random_edge_position()
	_enemies_parent.add_child(enemy)
	_alive_count += 1
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	_alive_count -= 1
	_check_wave_complete()


func _check_wave_complete() -> void:
	if _wave_done:
		return
	if _total_spawned >= _total_to_spawn and _alive_count <= 0:
		_wave_done = true
		var wave_num: int = GameManager.current_wave
		wave_completed.emit(wave_num)
		if wave_num >= TOTAL_WAVES:
			all_waves_complete.emit()
		GameManager.end_wave()


func _get_random_edge_position() -> Vector2:
	var edge: int = randi() % 4
	var tile: Vector2i
	match edge:
		0: tile = Vector2i(randi() % 32, 0)
		1: tile = Vector2i(randi() % 32, 31)
		2: tile = Vector2i(0, randi() % 32)
		3: tile = Vector2i(31, randi() % 32)
		_: tile = Vector2i(0, 0)
	return PathfindingManager.tile_to_world(tile)
