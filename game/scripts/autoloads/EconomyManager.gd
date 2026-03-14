extends Node

const KILL_GOLD: Dictionary = {
	"basic": 5,
	"fast":  8,
	"tank":  20,
}


func award_kill_gold(enemy_type: String) -> void:
	var amount: int = KILL_GOLD.get(enemy_type, 5) as int
	GameManager.add_gold(amount)


func award_wave_bonus(wave_num: int) -> void:
	var bonus: int = 50 + (wave_num * 25)
	GameManager.add_gold(bonus)
