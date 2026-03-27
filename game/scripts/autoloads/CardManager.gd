extends Node

signal card_draft_started(cards: Array)
signal card_picked(card: Dictionary)

# Specialisation score per tower type
var specialisation: Dictionary = { "basic": 0, "sniper": 0, "splash": 0, "slow": 0, "wall": 0 }

# Accumulated additive multiplier bonuses per tower type per stat
# get_tower_multipliers() returns 1.0 + these values
var _tower_multipliers: Dictionary = {
	"basic":  { "attack_speed": 0.0, "damage": 0.0, "range": 0.0 },
	"sniper": { "attack_speed": 0.0, "damage": 0.0, "range": 0.0 },
	"splash": { "attack_speed": 0.0, "damage": 0.0, "range": 0.0 },
	"slow":   { "attack_speed": 0.0, "damage": 0.0, "range": 0.0 },
	"wall":   { "attack_speed": 0.0, "damage": 0.0, "range": 0.0 },
}

# General active effect flags and values (for complex effects in later steps)
var active_effects: Dictionary = {}

# Rarity weight bonus from Survivor's Instinct (additive to base Rare/Legendary weights)
var rare_weight_bonus: float = 0.0

# Card pool loaded from JSON: rarity string -> Array of card dicts
var _card_pool: Dictionary = {}

var _curse_next_wave_double_draw: bool = false

var _effect_registry: Node = null


func _ready() -> void:
	_effect_registry = load("res://scripts/cards/card_effect_registry.gd").new()
	_load_card_pool()


func _load_card_pool() -> void:
	var rarities: Array = ["common", "uncommon", "rare", "legendary"]
	for rarity in rarities:
		var path: String = "res://data/cards/%s.json" % rarity
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("CardManager: failed to open %s" % path)
			_card_pool[rarity] = []
			continue
		var json_text: String = file.get_as_text()
		file.close()
		var result: Variant = JSON.parse_string(json_text)
		if result == null or not result is Array:
			push_error("CardManager: failed to parse %s" % path)
			_card_pool[rarity] = []
			continue
		_card_pool[rarity] = result
	# Print pool sizes to verify loading
	print("CardManager loaded — common:%d uncommon:%d rare:%d legendary:%d" % [
		_card_pool["common"].size(),
		_card_pool["uncommon"].size(),
		_card_pool["rare"].size(),
		_card_pool["legendary"].size(),
	])


# Called by GameManager when a wave ends (Step 4)
func start_draft() -> void:
	var cards: Array = draw_cards(3)
	card_draft_started.emit(cards)
	# Step 4 placeholder: auto-pick first card. Remove this block in Step 6 when UI is wired.
	if cards.size() > 0:
		var auto_id: String = cards[0]["id"]
		print("CardManager [placeholder]: auto-picking '%s'" % auto_id)
		pick_card(auto_id)


# Weighted random draw of `count` unique cards.
# Rarity weights: Common 0.60, Uncommon 0.28, Rare 0.10, Legendary 0.02 (base)
# Rare/Legendary for a tower type are locked until specialisation meets threshold.
func draw_cards(count: int) -> Array:
	var drawn: Array = []
	var attempts: int = 0
	while drawn.size() < count and attempts < 200:
		attempts += 1
		var rarity: String = _pick_rarity()
		var pool: Array = _get_available_pool(rarity)
		if pool.is_empty():
			continue
		var card: Dictionary = _weighted_pick(pool)
		# Avoid duplicates in this draw
		var already: bool = false
		for d: Dictionary in drawn:
			if d["id"] == card["id"]:
				already = true
				break
		if not already:
			drawn.append(card)
	return drawn


func _pick_rarity() -> String:
	var w_common: float    = 0.60
	var w_uncommon: float  = 0.28
	var w_rare: float      = 0.10 + rare_weight_bonus
	var w_legendary: float = 0.02 + rare_weight_bonus
	var total: float = w_common + w_uncommon + w_rare + w_legendary
	var roll: float = randf() * total
	if roll < w_common:
		return "common"
	roll -= w_common
	if roll < w_uncommon:
		return "uncommon"
	roll -= w_uncommon
	if roll < w_rare:
		return "rare"
	return "legendary"


# Returns cards eligible to be drawn for a given rarity.
# Rare/Legendary cards are locked behind specialisation thresholds per tower type.
func _get_available_pool(rarity: String) -> Array:
	var all_cards: Array = _card_pool.get(rarity, [])
	if rarity != "rare" and rarity != "legendary":
		return all_cards
	var threshold: int = 3 if rarity == "rare" else 6
	var available: Array = []
	for card: Dictionary in all_cards:
		var affinity = card.get("tower_affinity", null)
		if affinity == null:
			# Economy/map cards have no affinity — always available
			available.append(card)
		elif specialisation.get(affinity, 0) >= threshold:
			available.append(card)
	return available


# Within a pool, cards whose affinity matches higher-specialisation tower types get more weight.
func _weighted_pick(pool: Array) -> Dictionary:
	var top_spec: int = 0
	for v: int in specialisation.values():
		if v > top_spec:
			top_spec = v

	var weights: Array = []
	var total_weight: float = 0.0
	for card: Dictionary in pool:
		var affinity = card.get("tower_affinity", null)
		var w: float = 1.0
		if affinity != null and top_spec > 0:
			var spec_score: int = specialisation.get(affinity, 0)
			# Up to 3x weight for the highest-specialised tower type
			w = 1.0 + 2.0 * (float(spec_score) / float(top_spec))
		weights.append(w)
		total_weight += w

	var roll: float = randf() * total_weight
	for i: int in range(pool.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[pool.size() - 1]


# Look up card by id across all pools
func _find_card(card_id: String) -> Dictionary:
	for rarity: String in _card_pool:
		for card: Dictionary in _card_pool[rarity]:
			if card["id"] == card_id:
				return card
	return {}


# Pick a card: increment specialisation, apply effect, emit signal
func pick_card(card_id: String) -> void:
	var card: Dictionary = _find_card(card_id)
	if card.is_empty():
		push_error("CardManager.pick_card: unknown card id '%s'" % card_id)
		return
	var affinity = card.get("tower_affinity", null)
	if affinity != null and specialisation.has(affinity):
		specialisation[affinity] += 1
	var effect: String = card.get("effect", "")
	var params: Dictionary = card.get("effect_params", {})
	if effect != "":
		_effect_registry.apply(effect, params, self)
	print("CardManager: picked '%s' | specialisation: %s" % [card.get("name", card_id), specialisation])
	card_picked.emit(card)


# Returns total multipliers for a tower type (base 1.0 + accumulated bonuses).
# tower_base.gd calls this to recalculate stats.
func get_tower_multipliers(tower_type: String) -> Dictionary:
	var base: Dictionary = _tower_multipliers.get(tower_type, {})
	return {
		"attack_speed": 1.0 + base.get("attack_speed", 0.0),
		"damage":       1.0 + base.get("damage", 0.0),
		"range":        1.0 + base.get("range", 0.0),
	}


# Check if a complex effect flag is active (used by projectile/enemy scripts in later steps)
func has_effect(effect_id: String) -> bool:
	return active_effects.has(effect_id)


# Internal: accumulate a tower stat multiplier bonus (called by card_effect_registry)
func _add_tower_multiplier(tower_type: String, stat: String, value: float) -> void:
	if _tower_multipliers.has(tower_type):
		_tower_multipliers[tower_type][stat] = _tower_multipliers[tower_type].get(stat, 0.0) + value
