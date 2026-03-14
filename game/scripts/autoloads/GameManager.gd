extends Node

enum GameState {
	SETUP,
	WAVE_ACTIVE,
	WAVE_COMPLETE,
	GAME_OVER,
	VICTORY
}

signal game_state_changed(new_state: GameState)
signal gold_changed(new_amount: int)
signal base_hp_changed(new_hp: int)
signal game_over
signal victory

const TOTAL_WAVES: int = 10

var state: GameState = GameState.SETUP
var current_wave: int = 0
var base_hp: int = 20
var gold: int = 100


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func damage_base(amount: int) -> void:
	base_hp = max(0, base_hp - amount)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		_set_state(GameState.GAME_OVER)
		game_over.emit()


func start_next_wave() -> void:
	current_wave += 1
	_set_state(GameState.WAVE_ACTIVE)


func end_wave() -> void:
	if current_wave >= TOTAL_WAVES:
		_set_state(GameState.VICTORY)
		victory.emit()
	else:
		_set_state(GameState.WAVE_COMPLETE)


func _set_state(new_state: GameState) -> void:
	state = new_state
	game_state_changed.emit(state)
