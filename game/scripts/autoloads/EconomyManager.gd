extends Node

const KILL_GOLD: Dictionary = {
	"basic": 5,
	"fast":  8,
	"tank":  20,
	"scout": 4,  # Plan A: scouts are quick, low-reward targets
}

# Plan A: wave bonus scales at 15% per wave (income-starved)
# Formula: floor(50 * 1.15^(wave_num - 1))
const WAVE_BONUS_BASE: int = 50
const WAVE_BONUS_SCALE: float = 1.15


func award_kill_gold(enemy_type: String) -> void:
	var amount: int = KILL_GOLD.get(enemy_type, 5) as int
	GameManager.add_gold(amount)


func award_wave_bonus(wave_num: int) -> void:
	var bonus: int = int(floor(WAVE_BONUS_BASE * pow(WAVE_BONUS_SCALE, wave_num - 1)))
	GameManager.add_gold(bonus)
