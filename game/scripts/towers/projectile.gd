extends Node2D

var target: Node2D = null
var speed: float = 200.0
var damage: int = 10
var aoe_radius: float = 0.0
var slow_duration: float = 0.0
var tower_type: String = ""
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
		var actual_damage: int = damage
		var slow_val = target.get("_slow_timer")
		var target_slowed: bool = slow_val != null and float(slow_val) > 0.0

		# synergy_slow_sniper_bonus: sniper hits slowed enemy → bonus damage
		if tower_type == "sniper" and target_slowed and CardManager.has_effect("synergy_slow_sniper_bonus"):
			var bonus: float = CardManager.active_effects.get("synergy_slow_sniper_bonus", 0.0)
			actual_damage = int(actual_damage * (1.0 + bonus))
			print("[synergy] slow_sniper_bonus: sniper dealt %d on slowed enemy" % actual_damage)

		# synergy_slow_all_bonus: any tower hits slowed enemy → bonus damage
		if target_slowed and CardManager.has_effect("synergy_slow_all_bonus"):
			var bonus: float = CardManager.active_effects.get("synergy_slow_all_bonus", 0.0)
			actual_damage = int(actual_damage * (1.0 + bonus))
			print("[synergy] slow_all_bonus: dealt %d on slowed enemy" % actual_damage)

		# synergy_killbox: sniper hits enemy marked in killbox → bonus damage
		if tower_type == "sniper" and target.get("_in_killbox") == true and CardManager.has_effect("synergy_killbox"):
			var bonus: float = CardManager.active_effects.get("synergy_killbox_bonus", 0.60)
			actual_damage = int(actual_damage * (1.0 + bonus))
			print("[synergy] killbox: sniper dealt %d on killbox-marked enemy" % actual_damage)

		if target.has_method("take_damage"):
			target.take_damage(actual_damage)
		if slow_duration > 0.0 and target.has_method("apply_slow"):
			target.apply_slow(0.5, slow_duration)
	if aoe_radius > 0.0:
		_apply_aoe(hit_pos)
	queue_free()


func _apply_aoe(hit_pos: Vector2) -> void:
	_damage_in_radius(get_tree().current_scene, hit_pos)
	if CardManager.has_effect("synergy_frost_fire") or CardManager.has_effect("synergy_killbox"):
		var aoe_enemies: Array = []
		_collect_enemies_in_radius(get_tree().current_scene, hit_pos, aoe_enemies)
		_apply_aoe_synergies(aoe_enemies)


func _damage_in_radius(node: Node, hit_pos: Vector2) -> void:
	for child in node.get_children():
		if child != target and child.has_method("take_damage"):
			if hit_pos.distance_to(child.global_position) <= aoe_radius:
				child.take_damage(damage)
		if child.get_child_count() > 0:
			_damage_in_radius(child, hit_pos)


func _collect_enemies_in_radius(node: Node, hit_pos: Vector2, result: Array) -> void:
	for child in node.get_children():
		if child.has_method("take_damage"):
			if hit_pos.distance_to(child.global_position) <= aoe_radius:
				result.append(child)
		if child.get_child_count() > 0:
			_collect_enemies_in_radius(child, hit_pos, result)


func _apply_aoe_synergies(enemies: Array) -> void:
	var frost_count: int = 0
	var killbox_count: int = 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# synergy_frost_fire: slowed enemy hit by AoE → freeze
		var enemy_slow_val = enemy.get("_slow_timer")
		if CardManager.has_effect("synergy_frost_fire") and enemy_slow_val != null and float(enemy_slow_val) > 0.0:
			if enemy.has_method("freeze"):
				var fdur: float = CardManager.active_effects.get("synergy_frost_fire_duration", 0.5)
				enemy.freeze(fdur)
				frost_count += 1
		# synergy_killbox: mark all enemies in blast for sniper bonus
		if CardManager.has_effect("synergy_killbox") and enemy.has_method("apply_killbox"):
			var kdur: float = CardManager.active_effects.get("synergy_killbox_duration", 3.0)
			enemy.apply_killbox(kdur)
			killbox_count += 1
	if frost_count > 0:
		print("[synergy] frost_fire: froze %d slowed enemies" % frost_count)
	if killbox_count > 0:
		print("[synergy] killbox: marked %d enemies in blast radius" % killbox_count)
