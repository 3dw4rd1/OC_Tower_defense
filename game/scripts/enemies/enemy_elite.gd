extends "res://scripts/enemies/enemy_basic.gd"


func _ready() -> void:
	speed = 96.0   # 1.2× basic
	_hp = 80
	_max_hp = 80
	_enemy_type = "elite"
	super._ready()
	$Sprite2D.material.set_shader_parameter("hue_shift", 60.0)  # yellow-green tint
