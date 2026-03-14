extends "res://scripts/towers/tower_base.gd"

const SLOW_FACTOR: float = 0.5
const SLOW_DURATION: float = 2.0


func _ready() -> void:
	damage = 5
	range_px = 96.0
	attack_speed = 2.0
	super._ready()


func _attack_target(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target.has_method("apply_slow"):
		target.apply_slow(SLOW_FACTOR, SLOW_DURATION)
