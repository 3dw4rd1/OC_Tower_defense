extends "res://scripts/towers/tower_base.gd"


func _ready() -> void:
	_tower_type = "sniper"
	damage = 40
	range_px = 192.0
	attack_speed = 0.4
	projectile_color = Color(0.90, 0.90, 0.78)
	range_color = Color(0.3, 0.6, 1.0, 1.0)  # cold blue
	super._ready()
