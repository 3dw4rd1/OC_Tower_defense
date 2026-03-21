extends "res://scripts/towers/tower_base.gd"

const SPLASH_RADIUS: float = 48.0


func _ready() -> void:
	damage = 15
	range_px = 64.0
	attack_speed = 1.0
	projectile_color = Color(0.78, 0.31, 0.08)
	projectile_aoe_radius = SPLASH_RADIUS
	range_color = Color(1.0, 0.4, 0.15, 1.0)  # orange-red
	super._ready()


func _attack_target(target: Node2D) -> void:
	if debug_attacks:
		var hit_count: int = 0
		for enemy: Node2D in _enemies_in_range:
			if is_instance_valid(enemy) and target.global_position.distance_to(enemy.global_position) <= SPLASH_RADIUS:
				hit_count += 1
		print("[%s] AoE fired — hit %d enemies" % [name, hit_count])
	_spawn_projectile(target)
