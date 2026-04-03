extends "res://scripts/enemies/enemy_basic.gd"

## Boss enemy — appears every 5th wave.
## HP and speed are overridden at spawn by WaveManager.
## Awards boss_gold on death (also set by WaveManager).


func _ready() -> void:
	speed = 28.0    # default; overridden by WaveManager
	_hp = 500
	_max_hp = 500
	_enemy_type = "boss"
	super._ready()
