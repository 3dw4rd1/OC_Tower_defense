extends Node2D

var target: Node2D = null
var speed: float = 200.0
var damage: int = 10
var aoe_radius: float = 0.0
var slow_duration: float = 0.0
@export var color: Color = Color(0.86, 0.63, 0.24)

@onready var _rect: ColorRect = $ColorRect


func _ready() -> void:
	_rect.color = color


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	if global_position.distance_to(target.global_position) < 8.0:
		_on_hit()


func _on_hit() -> void:
	var hit_pos: Vector2 = global_position
	if is_instance_valid(target):
		hit_pos = target.global_position
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if slow_duration > 0.0 and target.has_method("apply_slow"):
			target.apply_slow(0.5, slow_duration)
	if aoe_radius > 0.0:
		_apply_aoe(hit_pos)
	queue_free()


func _apply_aoe(hit_pos: Vector2) -> void:
	_damage_in_radius(get_tree().current_scene, hit_pos)


func _damage_in_radius(node: Node, hit_pos: Vector2) -> void:
	for child in node.get_children():
		if child != target and child.has_method("take_damage"):
			if hit_pos.distance_to(child.global_position) <= aoe_radius:
				child.take_damage(damage)
		if child.get_child_count() > 0:
			_damage_in_radius(child, hit_pos)
