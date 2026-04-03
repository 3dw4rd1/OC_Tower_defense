extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_complete
signal enemy_count_changed(count: int)

# ── Plan A: waves 1–10 (The Swarm) ────────────────────────────────────────────
const PLAN_A_COUNTS: Array[int]       = [8, 12, 18, 25, 35, 48, 64, 85, 110, 150]
const PLAN_A_HP: Array[int]           = [60, 70, 85, 100, 120, 145, 175, 210, 255, 300]
const PLAN_A_SPEED_MULT: Array[float] = [1.0, 1.0, 1.05, 1.1, 1.1, 1.15, 1.2, 1.25, 1.3, 1.4]
const PLAN_A_BASE_SPEED: float        = 80.0  # enemy_basic default speed
const BURST_INNER_DELAY: float        = 0.1   # gap between enemies inside a burst cluster

# ── Legacy wave data: waves 11–25 ─────────────────────────────────────────────
const LEGACY_WAVE_DATA: Array = [
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
	"basic":    "res://scenes/enemies/EnemyBasic.tscn",
	"scout":    "res://scenes/enemies/EnemyScout.tscn",
	"fast":     "res://scenes/enemies/EnemyFast.tscn",
	"tank":     "res://scenes/enemies/EnemyTank.tscn",
	"boss":     "res://scenes/enemies/EnemyBoss.tscn",
	"elite":    "res://scenes/enemies/EnemyElite.tscn",
	"armored":  "res://scenes/enemies/EnemyArmored.tscn",
}

# Boss wave gold by tier (waves 5/10/15/20/25)
const BOSS_GOLD: Array[int] = [50, 75, 100, 125, 150]

var _alive_count: int = 0
var _total_to_spawn: int = 0
var _total_spawned: int = 0
var _spawn_queue: Array[String] = []
var _spawn_delays: Array[float] = []  # delay after each spawn before the next
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _wave_done: bool = false
var _enemies_parent: Node = null
var _plan_a_wave: bool = false
var _current_wave_hp: int = 0
var _current_wave_speed_mult: float = 1.0
# Boss wave state
var _current_boss_hp: int = 0
var _current_boss_speed: float = 0.0
var _current_boss_gold: int = 0
# Endless mode state
var _is_endless_wave: bool = false
var _endless_hp_mult: float = 1.0
var _endless_speed_mult: float = 1.0


func set_enemies_parent(parent: Node) -> void:
	_enemies_parent = parent


func get_alive_count() -> int:
	return _alive_count


func start_wave(wave_num: int) -> void:
	if wave_num < 1:
		return

	_spawn_queue.clear()
	_spawn_delays.clear()
	_total_spawned = 0
	_alive_count = 0
	_spawn_timer = 0.0
	_is_spawning = true
	_wave_done = false
	_current_boss_hp = 0
	_current_boss_speed = 0.0
	_current_boss_gold = 0
	_is_endless_wave = false
	_endless_hp_mult = 1.0
	_endless_speed_mult = 1.0

	if wave_num <= 10:
		_start_plan_a_wave(wave_num)
	elif wave_num <= 25:
		_plan_a_wave = false
		_start_legacy_wave(wave_num)
	else:
		_plan_a_wave = false
		_start_endless_wave(wave_num)

	_total_to_spawn = _spawn_queue.size()
	wave_started.emit(wave_num)


func _start_plan_a_wave(wave_num: int) -> void:
	_plan_a_wave = true
	var idx: int = wave_num - 1
	var total_count: int = PLAN_A_COUNTS[idx]
	# Step 8: horde surge curse — 40% more enemies this wave
	if CardManager.next_wave_horde:
		total_count = int(ceil(total_count * 1.4))
		CardManager.next_wave_horde = false
		print("WaveManager: horde surge active — spawning %d enemies this wave" % total_count)
	_current_wave_hp = PLAN_A_HP[idx]
	_current_wave_speed_mult = PLAN_A_SPEED_MULT[idx]
	# Spawn interval: 1.2 s at wave 1, 0.45 s at wave 10, linear interpolation
	var spawn_interval: float = lerpf(1.2, 0.45, float(idx) / 9.0)
	var use_scouts: bool = wave_num >= 5
	var use_bursts: bool = wave_num >= 8

	var enemy_list: Array[String] = []
	if use_scouts:
		# ~22.5 % scouts, rest regular
		var scout_count: int = int(round(total_count * 0.225))
		var regular_count: int = total_count - scout_count
		for _i: int in range(regular_count):
			enemy_list.append("basic")
		for _i: int in range(scout_count):
			enemy_list.append("scout")
	else:
		for _i: int in range(total_count):
			enemy_list.append("basic")
	# Elite injection on wave 10 (~10% of spawns)
	if wave_num == 10:
		var elite_count_a: int = int(round(enemy_list.size() * 0.10))
		for i: int in range(elite_count_a):
			var replace_idx: int = randi() % enemy_list.size()
			enemy_list[replace_idx] = "elite"

	enemy_list.shuffle()

	_build_spawn_queue(enemy_list, spawn_interval, use_bursts)

	# Boss on every 5th wave — prepend to queue with 1.5s lead-in gap
	if wave_num % 5 == 0:
		var boss_tier: int = (wave_num / 5) - 1  # 0=wave5, 1=wave10, 2=wave15, 3=wave20, 4=wave25
		_current_boss_hp = PLAN_A_HP[idx] * 8
		_current_boss_speed = PLAN_A_BASE_SPEED * _current_wave_speed_mult * 0.7
		_current_boss_gold = BOSS_GOLD[clamp(boss_tier, 0, BOSS_GOLD.size() - 1)]
		_inject_boss(1.5)
		print("WaveManager: boss wave %d — HP:%d speed:%.1f gold:%dg" % [wave_num, _current_boss_hp, _current_boss_speed, _current_boss_gold])


func _start_legacy_wave(wave_num: int) -> void:
	var legacy_idx: int = wave_num - 11
	var data: Dictionary = LEGACY_WAVE_DATA[legacy_idx]
	var multiplier_steps: int = wave_num - 10
	# Priority 1: count scaling — 8% more enemies per wave above wave 10
	var count_mult: float = pow(1.08, multiplier_steps)
	# Priority 2: spawn interval compression — 5% faster per wave, floors ~0.22s by wave 25
	var spawn_interval: float = 0.5 * pow(0.95, multiplier_steps)
	# Step 8: horde surge curse — 40% more enemies this wave
	var horde_active: bool = CardManager.next_wave_horde
	if horde_active:
		CardManager.next_wave_horde = false
	var enemy_list: Array[String] = []
	for enemy_type: String in data:
		var count: int = int(ceil(data[enemy_type] * count_mult))
		if horde_active:
			count = int(ceil(count * 1.4))
		for _i: int in range(count):
			enemy_list.append(enemy_type)
	if horde_active:
		print("WaveManager: horde surge active — spawning %d enemies this wave" % enemy_list.size())
	# Elite injection: wave 10+ mixes in elites (10% → 25% by wave 20)
	var elite_ratio: float = lerpf(0.10, 0.25, float(clamp(wave_num - 10, 0, 10)) / 10.0)
	var elite_count: int = int(round(enemy_list.size() * elite_ratio))
	for i: int in range(elite_count):
		var replace_idx: int = randi() % enemy_list.size()
		enemy_list[replace_idx] = "elite"

	# Armored injection: wave 13+ introduces armored enemies (5% → 15% by wave 25)
	if wave_num >= 13:
		var armored_ratio: float = lerpf(0.05, 0.15, float(clamp(wave_num - 13, 0, 12)) / 12.0)
		var armored_count: int = int(round(enemy_list.size() * armored_ratio))
		for i: int in range(armored_count):
			var replace_idx: int = randi() % enemy_list.size()
			enemy_list[replace_idx] = "armored"

	print("WaveManager: wave %d — %d enemies (%.0f%% elites), spawn interval %.2fs (count_mult=%.2f)" % [wave_num, enemy_list.size(), elite_ratio * 100, spawn_interval, count_mult])
	enemy_list.shuffle()
	_build_spawn_queue(enemy_list, spawn_interval, false)

	# Boss on every 5th wave — prepend to queue with 1.5s lead-in gap
	if wave_num % 5 == 0:
		var boss_tier: int = (wave_num / 5) - 1  # 2=wave15, 3=wave20, 4=wave25
		var multiplier_steps_boss: int = wave_num - 10
		var hp_mult: float = pow(1.10, multiplier_steps_boss)
		_current_boss_hp = int(120 * hp_mult * 8)  # tank baseline × legacy hp_mult × 8
		var speed_mult_boss: float = pow(1.05, multiplier_steps_boss)
		_current_boss_speed = 40.0 * speed_mult_boss * 0.7  # tank baseline × legacy speed_mult × 0.7
		_current_boss_gold = BOSS_GOLD[clamp(boss_tier, 0, BOSS_GOLD.size() - 1)]
		_inject_boss(1.5)
		print("WaveManager: boss wave %d — HP:%d speed:%.1f gold:%dg" % [wave_num, _current_boss_hp, _current_boss_speed, _current_boss_gold])


func _start_endless_wave(wave_num: int) -> void:
	var endless_step: int = wave_num - 25
	_endless_hp_mult = pow(1.18, endless_step)
	_endless_speed_mult = pow(1.07, endless_step)
	var count_mult: float = pow(1.12, endless_step)
	_is_endless_wave = true

	var base_count: int = 75  # wave 25 baseline
	var total_count: int = int(ceil(base_count * count_mult))
	var spawn_interval: float = max(0.15, 0.22 * pow(0.97, endless_step))

	# Mix: basic / fast / tank / elite / armored, ratios grow over time
	var elite_ratio: float    = min(0.30, 0.25 + endless_step * 0.01)
	var armored_ratio: float  = min(0.15, 0.10 + endless_step * 0.005)
	var tank_ratio: float     = 0.18
	var fast_ratio: float     = 0.22
	var enemy_list: Array[String] = []
	for _i: int in range(total_count):
		var roll: float = randf()
		if roll < elite_ratio:
			enemy_list.append("elite")
		elif roll < elite_ratio + armored_ratio:
			enemy_list.append("armored")
		elif roll < elite_ratio + armored_ratio + tank_ratio:
			enemy_list.append("tank")
		elif roll < elite_ratio + armored_ratio + tank_ratio + fast_ratio:
			enemy_list.append("fast")
		else:
			enemy_list.append("basic")

	# Horde surge curse
	if CardManager.next_wave_horde:
		CardManager.next_wave_horde = false
		var extra: int = int(ceil(total_count * 0.4))
		for _i: int in range(extra):
			enemy_list.append(enemy_list[randi() % enemy_list.size()])
		print("WaveManager: horde surge active — endless wave now %d enemies" % enemy_list.size())

	print("WaveManager: endless wave %d (step %d) — %d enemies, hp_mult=%.2f, speed_mult=%.2f, interval=%.2fs" % [wave_num, endless_step, enemy_list.size(), _endless_hp_mult, _endless_speed_mult, spawn_interval])
	enemy_list.shuffle()
	_build_spawn_queue(enemy_list, spawn_interval, endless_step >= 3)

	# Boss every 5th wave continues in endless
	if wave_num % 5 == 0:
		var boss_tier: int = clamp((wave_num / 5) - 1, 0, BOSS_GOLD.size() - 1)
		var ms: int = wave_num - 10
		_current_boss_hp = int(120 * pow(1.10, ms) * 8 * _endless_hp_mult)
		_current_boss_speed = 40.0 * pow(1.05, ms) * 0.7 * _endless_speed_mult
		_current_boss_gold = BOSS_GOLD[boss_tier] + (endless_step * 25)  # gold keeps scaling
		_inject_boss(1.5)
		print("WaveManager: endless boss wave %d — HP:%d speed:%.1f gold:%dg" % [wave_num, _current_boss_hp, _current_boss_speed, _current_boss_gold])


# Prepends a boss to the front of an already-built spawn queue.
# boss_lead_in: gap (seconds) between boss spawn and the first regular enemy.
func _inject_boss(boss_lead_in: float) -> void:
	_spawn_queue.push_front("boss")
	_spawn_delays.push_front(boss_lead_in)


# Populates _spawn_queue and _spawn_delays.
# _spawn_delays[i] is the gap to wait AFTER spawning enemy i before spawning i+1.
func _build_spawn_queue(enemy_list: Array[String], spawn_interval: float, use_bursts: bool) -> void:
	var n: int = enemy_list.size()
	if n == 0:
		return

	if use_bursts:
		# Wave 8+: spawn in clusters of 3–4 with tight inner gaps, full interval between clusters
		var i: int = 0
		while i < n:
			var burst_size: int = randi_range(3, 4)
			var burst_end: int = mini(i + burst_size, n)
			for j: int in range(i, burst_end):
				_spawn_queue.append(enemy_list[j])
				if j < n - 1:
					if j < burst_end - 1:
						_spawn_delays.append(BURST_INNER_DELAY)
					else:
						_spawn_delays.append(spawn_interval)
			i = burst_end
	else:
		for i: int in range(n):
			_spawn_queue.append(enemy_list[i])
			if i < n - 1:
				_spawn_delays.append(spawn_interval)


func _process(delta: float) -> void:
	if not _is_spawning or _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_do_spawn(_spawn_queue.pop_front())
		if not _spawn_queue.is_empty() and not _spawn_delays.is_empty():
			_spawn_timer = _spawn_delays.pop_front()
		else:
			_spawn_timer = 0.0
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

	if enemy_type == "boss":
		enemy._hp = _current_boss_hp
		enemy._max_hp = _current_boss_hp
		enemy.speed = _current_boss_speed
		enemy._enemy_type = "boss"
		enemy._boss_gold = _current_boss_gold
	elif _plan_a_wave:
		# Apply Plan A per-wave stats before the node enters the scene tree
		enemy._hp = _current_wave_hp
		enemy.speed = PLAN_A_BASE_SPEED * _current_wave_speed_mult
		if enemy_type == "scout":
			# Scout: 2× wave speed, 40 % wave HP; awards scout kill-gold (4g)
			enemy._hp = int(_current_wave_hp * 0.4)
			enemy.speed = PLAN_A_BASE_SPEED * _current_wave_speed_mult * 2.0
			enemy._enemy_type = "scout"
	elif _is_endless_wave:
		# Endless waves: scale from wave-25 baselines
		var base_hp: int
		var base_speed: float
		match enemy_type:
			"basic":
				base_hp = 300; base_speed = 80.0 * 2.1
			"fast":
				base_hp = 150; base_speed = 144.0 * 2.1
			"tank":
				base_hp = 600; base_speed = 40.0 * 2.1
			"elite":
				base_hp = 400; base_speed = 96.0 * 2.1
			"armored":
				base_hp = 200; base_speed = 60.0 * 2.1  # armor handles effective HP
			_:
				base_hp = 300; base_speed = 80.0 * 2.1
		enemy._hp = int(base_hp * _endless_hp_mult)
		enemy._max_hp = enemy._hp
		enemy.speed = base_speed * _endless_speed_mult
	else:
		# Legacy waves 11-25: compound scaling from wave 10 baseline
		if GameManager.current_wave > 10:
			var multiplier_steps: int = GameManager.current_wave - 10
			var speed_mult: float = pow(1.05, multiplier_steps)
			var hp_mult: float = pow(1.10, multiplier_steps)
			enemy.speed *= speed_mult
			enemy._hp = int(enemy._hp * hp_mult)

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
