extends "res://scripts/towers/tower_base.gd"


func _ready() -> void:
	damage = 10
	range_px = 96.0
	attack_speed = 1.0
	projectile_color = Color(0.86, 0.63, 0.24)
	super._ready()
