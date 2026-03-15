extends "res://scripts/towers/tower_base.gd"


func _ready() -> void:
	damage = 40
	range_px = 192.0
	attack_speed = 0.4
	projectile_color = Color(0.90, 0.90, 0.78)
	super._ready()
