extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_complete
signal enemy_count_changed(count: int)

# Plan A: spawn interval linearly interpolated from 1.2s (wave 1) to 0.45s (wave 10)
const SPAWN_INTERVAL_W1: float = 1.2
const SPAWN_INTERVAL_W10: float = 0.45

# Plan A: base HP per wave (indices 0-9 = waves 1-10)
const WAVE_HP: Array[int] = [60, 70, 85, 100, 120, 145, 175, 210, 255, 300]

# Plan A: speed multiplier per wave (indices 0-9 = waves 1-10)
const WAVE_SPEED_MULT: Array[float] = [1.0, 1.0, 1.05, 1.1, 1.1, 1.15, 1.2, 1.25, 1.3, 1.4]

# Plan A wave compositions (waves 1-10) + continuation (waves 11-25)
# Scouts are ~20-25% of total from wave 5 onward; reuse EnemyBasic scene with modified stats
const WAVE_DATA: Array = [
	# Wave 1: 8 total
	{"basic": 8},
	# Wave 2: 12 total
	{"basic": 12},
	# Wave 3: 18 total
	{"basic": 18},
	# Wave 4: 25 total
	{"basic": 25},
	# Wave 5: 35 total — 9 scouts (~26%), 26 basic
	{"basic": 26, "scout": 9},
	# Wave 6: 48 total — 10 scouts (~21%), 38 basic
	{"basic": 38, "scout": 10},
	# Wave 7: 64 total — 14 scouts (~22%), 50 basic
	{"basic": 50, "scout": 14},
	# Wave 8: 85 total — 17 scouts (~20%), 68 basic  [burst mode starts]
	{"basic": 68, "scout": 17},
	# Wave 9: 110 total — 24 scouts (~22%), 86 basic
	{"basic": 86, "scout": 24},
	# Wave 10: 150 total — 38 scouts (~25%), 112 basic
	{"basic": 112, "scout": 38},
	# Waves 11-25: continuation with post-plan-A exponential scaling
	{"basic": 15, "fast": 8},
	{"fast": 10, "tank": 5},
	{"basic": 12, "fast": 8, "tank": 4},
	{"fast": 12, "tank": 8},
	{"basic": 20, "fast": 10, "tank": 8},
	{"fast": 15, "tank": 6},
	{"basic": 10, "fast": 15, "tank": 5},
	{"fast": 10, "tank": 12},
	{"basic": 15, "fast": 12, "tank": 10},
	{"basic": 25, "fast": 15, "tank": 10},
	{"fast": 15, "tank": 10},
	{"basic": 20, "fast": 20, "tank": 8},
	{"fast": 20, "tank": 15},
	{"basic": 25, "fast": 20, "tank": 15},
	{"basic": 30, "fast": 25, "tank": 20},
]

const ENEMY_SCENES: Dictionary = {
	"basic": "res://scenes/enemies/EnemyBasic.tscn",
	"fast":  "res://scenes/enemies/EnemyFast.tscn",
	"tank":  "res://scenes/enemies/EnemyTank.tscn",
	"scout": "res://scenes/enemies/EnemyBasic.tscn",  # reuses basic scene with modified stats
}

# Burst spawning constants (wave 8+)
const BURST_SIZE_MIN: int = 3
const BURST_SIZE_MAX: int = 4
const BURST_PAUSE: float = 0.9  # seconds between bursts

var _alive_count: int = 0
var _total_to_spawn: int = 0
var _total_spawned: int = 0
var _spawn_queue: Array[String] = []
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _wave_done: bool = false
var _enemies_parent: Node = null
var _current_spawn_interval: float = SPAWN_INTERVAL_W1


func set_enemies_parent(parent: Node) -> void:
	_enemies_parent = parent


func get_alive_count() -> int:
	return _alive_count


func start_wave(wave_num: int) -> void:
	if wave_num < 1 or wave_num > GameManager.TOTAL_WAVES:
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
	_current_spawn_interval = _get_spawn_interval(wave_num)
	wave_started.emit(wave_num)


func _get_spawn_interval(wave_num: int) -> float:
	if wave_num <= 1:
		return SPAWN_INTERVAL_W1
	if wave_num >= 10:
		return SPAWN_INTERVAL_W10
	var t: float = float(wave_num - 1) / 9.0
	return SPAWN_INTERVAL_W1 + t * (SPAWN_INTERVAL_W10 - SPAWN_INTERVAL_W1)


func _process(delta: float) -> void:
	if not _is_spawning or _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	var wave_num: int = GameManager.current_wave
	if wave_num >= 8:
		# Burst mode: spawn a cluster of 3-4 simultaneously, then pause
		var burst_size: int = randi_range(BURST_SIZE_MIN, BURST_SIZE_MAX)
		var i: int = 0
		while i < burst_size and not _spawn_queue.is_empty():
			_do_spawn(_spawn_queue.pop_front())
			i += 1
		_spawn_timer = BURST_PAUSE
	else:
		_do_spawn(_spawn_queue.pop_front())
		_spawn_timer = _current_spawn_interval

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
	var wave_num: int = GameManager.current_wave

	if wave_num <= 10:
		# Plan A: apply per-wave HP and speed multiplier
		var base_hp: int = WAVE_HP[wave_num - 1]
		var speed_mult: float = WAVE_SPEED_MULT[wave_num - 1]
		if enemy_type == "scout":
			# Scout: 2x the wave's normal speed, 40% of wave base HP
			enemy._hp = int(base_hp * 0.4)
			enemy.speed = enemy.speed * speed_mult * 2.0
			enemy._enemy_type = "scout"
		else:
			enemy._hp = base_hp
			enemy.speed = enemy.speed * speed_mult
	else:
		# Waves 11+: exponential scaling from base enemy stats
		var multiplier_steps: int = wave_num - 10
		var speed_scale: float = pow(1.05, multiplier_steps)
		var hp_scale: float = pow(1.10, multiplier_steps)
		enemy.speed *= speed_scale
		enemy._hp = int(enemy._hp * hp_scale)

	enemy.position = _get_random_edge_position()
	_enemies_parent.add_child(enemy)
	_alive_count += 1
	enemy_count_changed.emit(_alive_count)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	_alive_count -= 1
	enemy_count_changed.emit(_alive_count)
	_check_wave_complete()


func _check_wave_complete() -> void:
	if _wave_done:
		return
	if _total_spawned >= _total_to_spawn and _alive_count <= 0:
		_wave_done = true
		var wave_num: int = GameManager.current_wave
		wave_completed.emit(wave_num)
		if wave_num >= GameManager.TOTAL_WAVES:
			all_waves_complete.emit()
		GameManager.end_wave()


func _get_random_edge_position() -> Vector2:
	var edge: int = randi() % 4
	var tile: Vector2i
	match edge:
		0: tile = Vector2i(randi() % PathfindingManager.GRID_COLS, 0)
		1: tile = Vector2i(randi() % PathfindingManager.GRID_COLS, PathfindingManager.GRID_ROWS - 1)
		2: tile = Vector2i(0, randi() % PathfindingManager.GRID_ROWS)
		3: tile = Vector2i(PathfindingManager.GRID_COLS - 1, randi() % PathfindingManager.GRID_ROWS)
		_: tile = Vector2i(0, 0)
	return PathfindingManager.tile_to_world(tile)
