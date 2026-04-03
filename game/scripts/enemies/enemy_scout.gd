extends "res://scripts/enemies/enemy_basic.gd"

## Scout enemy — fast and fragile, introduced at wave 5.
## 2x wave speed, 40% wave HP. Stats are overridden at spawn by WaveManager.


func _ready() -> void:
	speed = 160.0   # default; overridden by WaveManager for Plan A waves
	_hp = 12
	_max_hp = 12
	_enemy_type = "scout"
	super._ready()
