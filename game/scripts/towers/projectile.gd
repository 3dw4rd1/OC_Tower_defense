extends Node2D

const FIRE_TILE_SCRIPT = preload("res://scripts/towers/fire_tile.gd")
const SLOW_DOT_SCRIPT = preload("res://scripts/towers/slow_dot.gd")

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

		# sniper_one_shot: 25% chance to instantly kill basic enemies
		if tower_type == "sniper" and CardManager.has_effect("sniper_one_shot") \
				and target.get("_enemy_type") == "basic" and randf() < 0.25:
			actual_damage = 9999
			print("[sniper_one_shot] one-shot triggered")

		# sniper_execute: instantly kill enemies at or below 10% max HP
		if tower_type == "sniper" and CardManager.has_effect("sniper_execute"):
			var max_hp = target.get("_max_hp")
			var cur_hp = target.get("_hp")
			if max_hp != null and cur_hp != null and int(cur_hp) <= int(int(max_hp) * 0.10):
				actual_damage = 9999
				print("[sniper_execute] execute at %d/%d hp" % [cur_hp, max_hp])

		# Set last-hit tower type so kill-chain tracking works in _die()
		if target.get("_last_hit_tower_type") != null:
			target._last_hit_tower_type = tower_type

		if target.has_method("take_damage"):
			target.take_damage(actual_damage)

		# Post-hit effects that require target still alive
		if is_instance_valid(target):
			if slow_duration > 0.0 and target.has_method("apply_slow"):
				target.apply_slow(0.5, slow_duration)

			# slow_dot: if slow tower hits an already-slowed enemy, apply DoT
			if tower_type == "slow" and CardManager.has_effect("slow_dot") and target_slowed:
				if target.find_child("SlowDoT") == null:
					var dot: Node2D = SLOW_DOT_SCRIPT.new()
					target.add_child(dot)
					print("[slow_dot] applied DoT to %s" % target.name)

			# sniper_suppress: slow the primary hit target
			if tower_type == "sniper" and CardManager.has_effect("sniper_suppress") \
					and target.has_method("apply_slow"):
				target.apply_slow(0.30, 2.0)
				print("[sniper_suppress] suppressed target")

		# sniper_chain_suppress: also slow enemies within 80px of hit position
		if tower_type == "sniper" and CardManager.has_effect("sniper_chain_suppress"):
			var chain_enemies: Array = []
			_collect_enemies_near(get_tree().current_scene, hit_pos, 80.0, chain_enemies, target)
			for e: Node2D in chain_enemies:
				if is_instance_valid(e) and e.has_method("apply_slow"):
					e.apply_slow(0.30, 2.0)
			if chain_enemies.size() > 0:
				print("[sniper_chain_suppress] chain-suppressed %d enemies" % chain_enemies.size())

		# rifle_ricochet: bounce a new projectile to the nearest enemy within 64px
		if tower_type == "basic" and CardManager.has_effect("rifle_ricochet"):
			var ricochet_target: Node2D = _find_nearest_enemy_near(
					get_tree().current_scene, hit_pos, 64.0, target)
			if ricochet_target != null:
				var proj: Node2D = load("res://scenes/towers/Projectile.tscn").instantiate()
				proj.target = ricochet_target
				proj.damage = damage
				proj.color = color
				proj.tower_type = tower_type
				proj.global_position = hit_pos
				get_parent().add_child(proj)
				print("[rifle_ricochet] ricocheted to nearby enemy")

	if aoe_radius > 0.0:
		_apply_aoe(hit_pos)
	queue_free()


func _apply_aoe(hit_pos: Vector2) -> void:
	_damage_in_radius(get_tree().current_scene, hit_pos)
	if CardManager.has_effect("synergy_frost_fire") or CardManager.has_effect("synergy_killbox"):
		var aoe_enemies: Array = []
		_collect_enemies_in_radius(get_tree().current_scene, hit_pos, aoe_enemies)
		_apply_aoe_synergies(aoe_enemies)

	# splash_knockback / splash_shockwave
	if CardManager.has_effect("splash_knockback"):
		var kb_enemies: Array = []
		_collect_enemies_in_radius(get_tree().current_scene, hit_pos, kb_enemies)
		for e: Node2D in kb_enemies:
			if not is_instance_valid(e):
				continue
			if CardManager.has_effect("splash_shockwave"):
				# shockwave replaces velocity knockback with a freeze
				if e.has_method("freeze"):
					e.freeze(0.5)
			else:
				var vel_val = e.get("velocity")
				if vel_val != null:
					e.velocity += (e.global_position - hit_pos).normalized() * 150.0

	# splash_fire_dot: leave a burning zone at impact point
	if CardManager.has_effect("splash_fire_dot"):
		_spawn_fire_tile(hit_pos)


func _spawn_fire_tile(hit_pos: Vector2) -> void:
	var tile: Node2D = FIRE_TILE_SCRIPT.new()
	tile.radius = aoe_radius
	tile.tick_damage = max(1, damage / 4)
	tile.global_position = hit_pos
	get_parent().add_child(tile)


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


func _collect_enemies_near(node: Node, pos: Vector2, radius: float, result: Array, exclude: Node2D) -> void:
	for child in node.get_children():
		if child != exclude and child.has_method("take_damage"):
			if pos.distance_to(child.global_position) <= radius:
				result.append(child)
		if child.get_child_count() > 0:
			_collect_enemies_near(child, pos, radius, result, exclude)


func _find_nearest_enemy_near(node: Node, pos: Vector2, radius: float, exclude: Node2D) -> Node2D:
	var candidates: Array = []
	_collect_enemies_near(node, pos, radius, candidates, exclude)
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for e in candidates:
		if is_instance_valid(e):
			var d: float = pos.distance_to(e.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = e
	return nearest
