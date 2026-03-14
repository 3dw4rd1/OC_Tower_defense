extends "res://scripts/towers/tower_base.gd"

const SPLASH_RADIUS: float = 48.0


func _ready() -> void:
	damage = 15
	range_px = 64.0
	attack_speed = 1.0
	super._ready()


func _attack_target(target: Node2D) -> void:
	# AoE: damage all enemies within splash radius of the target
	for enemy: Node2D in _enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		if target.global_position.distance_to(enemy.global_position) <= SPLASH_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
