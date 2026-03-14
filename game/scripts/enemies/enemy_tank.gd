extends "res://scripts/enemies/enemy_basic.gd"


func _ready() -> void:
	speed = 40.0  # 0.5x basic
	_hp = 120
	_enemy_type = "tank"
	super._ready()
