extends CharacterBody2D

signal died

var speed: float = 80.0
var damage: int = 1
var _hp: int = 30
var _max_hp: int = 30
var _last_hit_tower_type: String = ""
var _enemy_type: String = "basic"
var _path: Array[Vector2] = []
var _path_index: int = 0
var _speed_multiplier: float = 1.0
var _slow_timer: float = 0.0
var _is_frozen: bool = false
var _freeze_timer: float = 0.0
var _in_killbox: bool = false
var _killbox_timer: float = 0.0

var BASE_TILE: Vector2i = PathfindingManager.BASE_TILE


func _ready() -> void:
	_max_hp = _hp
	PathfindingManager.obstacle_changed.connect(_recalculate_path)




func _physics_process(delta: float) -> void:
	# Freeze overrides all movement
	if _is_frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0.0:
			_is_frozen = false
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Killbox timer — clear flag when expired
	if _in_killbox:
		_killbox_timer -= delta
		if _killbox_timer <= 0.0:
			_in_killbox = false

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


func freeze(duration: float) -> void:
	_is_frozen = true
	_freeze_timer = duration


func apply_killbox(duration: float) -> void:
	_in_killbox = true
	_killbox_timer = duration


func reach_base() -> void:
	# Enemy reached the base — no kill gold awarded
	died.emit()
	queue_free()


func _die() -> void:
	EconomyManager.award_kill_gold(_enemy_type, GameManager.current_wave)
	# rifle_kill_chain: track basic tower kills; fire volley at threshold
	if _last_hit_tower_type == "basic" and CardManager.has_effect("rifle_kill_chain"):
		CardManager.kill_chain_counter += 1
		var stack: int = CardManager.active_effects.get("rifle_kill_chain_stack", 1)
		var threshold: int = max(2, 10 - (stack - 1) * 2)
		if CardManager.kill_chain_counter >= threshold:
			CardManager.kill_chain_counter = 0
			_fire_basic_volley()
	died.emit()
	queue_free()


func _fire_basic_volley() -> void:
	print("[rifle_kill_chain] Kill chain triggered — all basic towers fire!")
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower.get("_tower_type") == "basic":
			tower.call("_do_attack")


func _recalculate_path() -> void:
	if not is_inside_tree():
		return
	var my_tile: Vector2i = PathfindingManager.world_to_tile(global_position)
	_path = PathfindingManager.get_astar_path(my_tile, BASE_TILE)
	_path_index = 0
