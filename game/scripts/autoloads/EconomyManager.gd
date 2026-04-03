extends Node

const KILL_GOLD: Dictionary = {
	"basic": 5,
	"fast":  8,
	"tank":  20,
	"scout": 4,   # Plan A: scouts are quick, low-reward targets
	"elite": 15,  # faster than basic, tankier than fast — mid-tier reward
}

# Plan A: wave bonus scales at 15% per wave (income-starved)
# Formula: floor(50 * 1.15^(wave_num - 1))
const WAVE_BONUS_BASE: int = 50
const WAVE_BONUS_SCALE: float = 1.15

# Card economy bonuses — set by CardEffectRegistry
var card_wave_bonus: int = 0      # flat gold added on top of every wave bonus
var card_kill_bonus: int = 0      # flat gold added to every kill award
var brute_gold_boost_waves: int = 0  # waves remaining where tanks drop 3× gold


func _ready() -> void:
	WaveManager.wave_started.connect(_on_wave_started)


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
	if enemy_type == "tank" and brute_gold_boost_waves > 0:
		amount *= 3
		print("[EconomyManager] brute gold boost: tank kill worth %dg (%d waves remaining)" % [amount, brute_gold_boost_waves])
	if card_kill_bonus > 0:
		amount += card_kill_bonus
	GameManager.add_gold(amount)


func award_wave_bonus(wave_num: int) -> void:
	# Plan A: income-starved — 15 % compound growth per wave from a 50-gold base
	# Wave 1: 50g | Wave 5: ~87g | Wave 10: ~175g  (vs old linear 75/175/300)
	var bonus: int = int(floor(WAVE_BONUS_BASE * pow(WAVE_BONUS_SCALE, wave_num - 1)))
	if card_wave_bonus > 0:
		print("[EconomyManager] wave bonus: %dg base + %dg card bonus = %dg total" % [bonus, card_wave_bonus, bonus + card_wave_bonus])
		bonus += card_wave_bonus
	GameManager.add_gold(bonus)


func _on_wave_started(_wave_num: int) -> void:
	if brute_gold_boost_waves > 0:
		brute_gold_boost_waves -= 1
		if brute_gold_boost_waves == 0:
			print("[EconomyManager] brute gold boost expired")
