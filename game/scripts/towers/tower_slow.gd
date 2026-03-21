extends "res://scripts/towers/tower_base.gd"

const SLOW_DURATION: float = 2.0


func _ready() -> void:
	damage = 5
	range_px = 96.0
	attack_speed = 2.0
	projectile_color = Color(0.31, 0.63, 0.90)
	projectile_slow_duration = SLOW_DURATION
	range_color = Color(0.7, 0.3, 1.0, 1.0)  # purple
	super._ready()


func _attack_target(target: Node2D) -> void:
	if debug_attacks:
		print("[%s] Slowed %s for %.0fs" % [name, target.name, SLOW_DURATION])
	_spawn_projectile(target)
