extends "res://scripts/enemies/enemy_basic.gd"


func _ready() -> void:
	speed = 144.0  # 1.8x basic
	_hp = 15
	_enemy_type = "fast"
	super._ready()
