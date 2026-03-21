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


# Kill gold scales with wave: +10% per wave for waves 1-10, +8% per wave for waves 11+
# Wave 1: 1.0x, Wave 10: 1.9x, Wave 25: ~6x
func wave_gold_multiplier(wave_num: int) -> float:
	if wave_num <= 1:
		return 1.0
	if wave_num <= 10:
		return 1.0 + (wave_num - 1) * 0.10
	else:
		return 1.9 * pow(1.08, wave_num - 10)


func award_kill_gold(enemy_type: String, wave_num: int = 1) -> void:
	var base: int = KILL_GOLD.get(enemy_type, 5) as int
	var amount: int = int(floor(base * wave_gold_multiplier(wave_num)))
	GameManager.add_gold(amount)


func award_wave_bonus(wave_num: int) -> void:
	# Plan A: income-starved — 15 % compound growth per wave from a 50-gold base
	# Wave 1: 50g | Wave 5: ~87g | Wave 10: ~175g  (vs old linear 75/175/300)
	var bonus: int = int(floor(WAVE_BONUS_BASE * pow(WAVE_BONUS_SCALE, wave_num - 1)))
	GameManager.add_gold(bonus)
