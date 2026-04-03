extends "res://scripts/enemies/enemy_basic.gd"

## Armored enemy — introduced at wave 13.
## Has damage reduction (armor) instead of raw high HP.
## Forces players to use high-DPS towers rather than relying on splash/slow.

var armor: float = 0.35  # blocks 35% of all incoming damage


func _ready() -> void:
	speed = 60.0
	_hp = 60
	_max_hp = 60
	_enemy_type = "armored"
	super._ready()


func take_damage(amount: int) -> void:
	# Reduce incoming damage by armor percentage; always deal at least 1
	var reduced: int = max(1, int(ceil(amount * (1.0 - armor))))
	super.take_damage(reduced)
