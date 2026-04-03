extends Node

enum GameState {
	SETUP,
	WAVE_ACTIVE,
	WAVE_COMPLETE,
	CARD_DRAFT,
	GAME_OVER,
	VICTORY
}

signal game_state_changed(new_state: GameState)
signal gold_changed(new_amount: int)
signal base_hp_changed(new_hp: int)
signal game_over
signal victory

const TOTAL_WAVES: int = 25
const MAX_BASE_HP: int = 50

var state: GameState = GameState.SETUP
var current_wave: int = 0
var base_hp: int = MAX_BASE_HP
var gold: int = 1000
var endless_mode: bool = false


func _ready() -> void:
	pass


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func heal_base(amount: int) -> void:
	base_hp = min(MAX_BASE_HP, base_hp + amount)
	base_hp_changed.emit(base_hp)


func damage_base(amount: int) -> void:
	base_hp = max(0, base_hp - amount)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		_set_state(GameState.GAME_OVER)
		game_over.emit()


func start_next_wave() -> void:
	if state == GameState.CARD_DRAFT:
		return  # Block wave start while draft is in progress
	current_wave += 1
	_set_state(GameState.WAVE_ACTIVE)
	WaveManager.start_wave(current_wave)


func end_wave() -> void:
	EconomyManager.award_wave_bonus(current_wave)
	if current_wave == TOTAL_WAVES and not endless_mode:
		endless_mode = true
		print("GameManager: wave 25 cleared — ENDLESS MODE begins!")
		_set_state(GameState.CARD_DRAFT)
		CardManager.start_draft()
	else:
		_set_state(GameState.CARD_DRAFT)
		CardManager.start_draft()


func _on_draft_complete() -> void:
	if state != GameState.CARD_DRAFT:
		return
	# Step 8: horde curse grants an extra card pick — chain another draft before completing
	if CardManager._extra_picks_remaining > 0:
		CardManager._extra_picks_remaining -= 1
		CardManager.start_draft()
	else:
		_set_state(GameState.WAVE_COMPLETE)


func _set_state(new_state: GameState) -> void:
	state = new_state
	game_state_changed.emit(state)
