extends Node2D

var damage: int = 10
var range_px: float = 96.0
var attack_speed: float = 1.0  # attacks per second

var _attack_timer: float = 0.0
var _enemies_in_range: Array[Node2D] = []

@onready var _range_area: Area2D = $RangeArea


func _ready() -> void:
	_range_area.body_entered.connect(_on_body_entered)
	_range_area.body_exited.connect(_on_body_exited)
	var shape: CircleShape2D = _range_area.get_node("CollisionShape2D").shape as CircleShape2D
	if shape:
		shape.radius = range_px


func _process(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 1.0 / attack_speed
		_do_attack()


func _do_attack() -> void:
	var target: Node2D = _get_nearest_enemy()
	if target == null:
		return
	_attack_target(target)


func _attack_target(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy: Node2D in _enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		_enemies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)
