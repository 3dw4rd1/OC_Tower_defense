extends "res://scripts/towers/tower_base.gd"

var _shot_counter: int = 0

func _ready() -> void:
	_tower_type = "basic"
	damage = 10
	range_px = 96.0
	attack_speed = 1.0
	projectile_color = Color(0.86, 0.63, 0.24)
	range_color = Color(0.95, 0.75, 0.2, 1.0)  # warm gold
	super._ready()


func _attack_target(t: Node2D) -> void:
	_shot_counter += 1
	var proj_damage: int = damage
	if _shot_counter % 5 == 0 and CardManager.has_effect("rifle_overcharge"):
		proj_damage = damage * 3
		print("[rifle_overcharge] overcharge shot! damage: %d" % proj_damage)

	var proj: Node2D = PROJECTILE_SCENE.instantiate()
	proj.target = t
	proj.damage = proj_damage
	proj.color = projectile_color
	proj.aoe_radius = projectile_aoe_radius
	proj.slow_duration = projectile_slow_duration
	proj.tower_type = _tower_type
	proj.global_position = global_position
	get_parent().add_child(proj)

	# rifle_double_tap: fire a second projectile at a different enemy after 0.1s
	if CardManager.has_effect("rifle_double_tap"):
		var second_target: Node2D = null
		for enemy: Node2D in _enemies_in_range:
			if is_instance_valid(enemy) and enemy != t:
				second_target = enemy
				break
		if second_target == null:
			second_target = t
		if second_target != null:
			var captured := second_target
			get_tree().create_timer(0.1).timeout.connect(func():
				if is_instance_valid(self) and is_instance_valid(captured):
					var p2: Node2D = PROJECTILE_SCENE.instantiate()
					p2.target = captured
					p2.damage = damage
					p2.color = projectile_color
					p2.aoe_radius = projectile_aoe_radius
					p2.slow_duration = projectile_slow_duration
					p2.tower_type = _tower_type
					p2.global_position = global_position
					get_parent().add_child(p2)
					print("[rifle_double_tap] double-tap fired")
			)
