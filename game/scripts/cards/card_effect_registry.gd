extends RefCounted
# Plain script — not an autoload. Instantiated and owned by CardManager.
# Steps 1-5: tower_attack_speed, tower_damage, tower_range fully implemented.
# Step 7: economy and map effects implemented.
# Step 8: curse effects implemented.


func apply(effect: String, params: Dictionary, card_manager: Node) -> void:
	match effect:
		# ── Simple tower stat multipliers (Step 5) ────────────────────────────
		"tower_attack_speed":
			var tower_type: String = params.get("tower_type", "")
			var mult: float = params.get("multiplier", 0.0)
			card_manager._add_tower_multiplier(tower_type, "attack_speed", mult)
			print("  → [card effect] %s attack_speed +%.0f%% (total: %.0f%%)" % [tower_type, mult * 100, (1.0 + card_manager._tower_multipliers[tower_type]["attack_speed"]) * 100])

		"tower_damage":
			var tower_type: String = params.get("tower_type", "")
			var mult: float = params.get("multiplier", 0.0)
			card_manager._add_tower_multiplier(tower_type, "damage", mult)
			print("  → [card effect] %s damage +%.0f%% (total: %.0f%%)" % [tower_type, mult * 100, (1.0 + card_manager._tower_multipliers[tower_type]["damage"]) * 100])

		"tower_range":
			var tower_type: String = params.get("tower_type", "")
			var mult: float = params.get("multiplier", 0.0)
			card_manager._add_tower_multiplier(tower_type, "range", mult)
			print("  → [card effect] %s range +%.0f%% (total: %.0f%%)" % [tower_type, mult * 100, (1.0 + card_manager._tower_multipliers[tower_type]["range"]) * 100])

		# ── Meta ──────────────────────────────────────────────────────────────
		"rare_weight_boost":
			card_manager.rare_weight_bonus += 0.08
			print("  → [card effect] rare_weight_boost: bonus now %.2f" % card_manager.rare_weight_bonus)

		# ── Tower stat variants (Step 5 extension — stubs) ────────────────────
		"tower_aoe_radius", "tower_slow_intensity":
			pass  # TODO Step 5 extension

		# ── Economy effects (Step 7) ───────────────────────────────────────────
		"wave_bonus_flat":
			var amount: int = int(params.get("amount", 0))
			EconomyManager.card_wave_bonus += amount
			print("  → [card effect] wave_bonus_flat +%dg (total card bonus: %dg per wave)" % [amount, EconomyManager.card_wave_bonus])

		"kill_gold_flat":
			var amount: int = int(params.get("amount", 0))
			EconomyManager.card_kill_bonus += amount
			print("  → [card effect] kill_gold_flat +%dg per kill (total card bonus: %dg)" % [amount, EconomyManager.card_kill_bonus])

		"tower_cost_reduction":
			var amount: float = params.get("amount", 0.0)
			card_manager.card_cost_multiplier *= (1.0 - amount)
			print("  → [card effect] tower_cost_reduction %.0f%% off — cost multiplier now %.2f" % [amount * 100, card_manager.card_cost_multiplier])

		# ── Map effects (Step 7) ───────────────────────────────────────────────
		"remove_obstacles":
			var count: int = int(params.get("count", 3))
			print("  → [card effect] remove_obstacles: clearing %d obstacle tiles" % count)
			TerrainManager.remove_random_obstacles(count)

		"spawn_obstacles":
			var count: int = int(params.get("count", 4))
			print("  → [card effect] spawn_obstacles: placing %d new obstacle tiles" % count)
			TerrainManager.spawn_random_obstacles(count)

		"spawn_slow_tile":
			print("  → [card effect] spawn_slow_tile: placing difficult terrain tile")
			TerrainManager.spawn_random_slow_tile()

		# ── Curse effects (Step 8) ─────────────────────────────────────────────
		"curse_next_wave_horde":
			card_manager.next_wave_horde = true
			card_manager._curse_next_wave_double_draw = true
			print("  → [card effect] curse_next_wave_horde: next wave +40%% enemies; next end-of-wave draws 2 cards")

		"curse_temp_damage_penalty":
			card_manager.curse_damage_penalty = 0.20
			card_manager.curse_damage_waves_remaining = 2
			GameManager.add_gold(150)
			print("  → [card effect] curse_temp_damage_penalty: towers deal 20%% less damage for 2 waves; gained 150g")

		"curse_brute_gold_boost":
			EconomyManager.brute_gold_boost_waves = 3
			print("  → [card effect] curse_brute_gold_boost: tanks drop 3× gold for 3 waves")

		"curse_remove_affinity":
			_apply_curse_remove_affinity(card_manager)

		# ── Synergy flags (Step 9) ────────────────────────────────────────────
		"synergy_slow_sniper_bonus":
			card_manager.active_effects["synergy_slow_sniper_bonus"] = \
				card_manager.active_effects.get("synergy_slow_sniper_bonus", 0.0) + params.get("bonus", 0.0)
		"synergy_slow_all_bonus":
			card_manager.active_effects["synergy_slow_all_bonus"] = \
				card_manager.active_effects.get("synergy_slow_all_bonus", 0.0) + params.get("bonus", 0.0)
		"synergy_frost_fire":
			card_manager.active_effects["synergy_frost_fire"] = true
		"synergy_killbox":
			card_manager.active_effects["synergy_killbox"] = true

		# ── Rifle mechanics (Step 10) ─────────────────────────────────────────
		"rifle_kill_chain", "rifle_overcharge", "rifle_ricochet", "rifle_double_tap":
			card_manager.active_effects[effect] = true

		# ── Sniper mechanics (Step 10) ────────────────────────────────────────
		"sniper_execute", "sniper_suppress", "sniper_chain_suppress", "sniper_one_shot":
			card_manager.active_effects[effect] = true

		# ── Splash mechanics (Step 10) ────────────────────────────────────────
		"splash_fire_dot", "splash_knockback", "splash_napalm", "splash_shockwave":
			card_manager.active_effects[effect] = true

		# ── Slow mechanics (Step 10) ──────────────────────────────────────────
		"slow_aura", "slow_dot", "slow_plague_pulse", "slow_full_stop":
			card_manager.active_effects[effect] = true

		_:
			push_warning("CardEffectRegistry: unhandled effect '%s'" % effect)


# Removes one random affinity from the card pool permanently,
# then boosts the highest-specialisation tower type's damage by 30%.
func _apply_curse_remove_affinity(card_manager: Node) -> void:
	# Gather affinities that actually have cards in the pool
	var affinities_with_cards: Array[String] = []
	for affinity: String in card_manager.specialisation.keys():
		for rarity: String in card_manager._card_pool:
			for card: Dictionary in card_manager._card_pool[rarity]:
				if card.get("tower_affinity", null) == affinity:
					if not affinities_with_cards.has(affinity):
						affinities_with_cards.append(affinity)
					break

	if affinities_with_cards.is_empty():
		push_warning("CardEffectRegistry: curse_remove_affinity — no affinities with cards remaining")
		return

	affinities_with_cards.shuffle()
	var removed_affinity: String = affinities_with_cards[0]

	# Strip all cards with the removed affinity from every rarity pool
	for rarity: String in card_manager._card_pool:
		var filtered: Array = []
		for card: Dictionary in card_manager._card_pool[rarity]:
			if card.get("tower_affinity", null) != removed_affinity:
				filtered.append(card)
		card_manager._card_pool[rarity] = filtered

	# Find highest-specialisation tower type (excluding the removed one)
	var top_type: String = ""
	var top_score: int = -1
	for t: String in card_manager.specialisation:
		if t == removed_affinity:
			continue
		if card_manager.specialisation[t] > top_score:
			top_score = card_manager.specialisation[t]
			top_type = t

	if top_type != "":
		card_manager._add_tower_multiplier(top_type, "damage", 0.30)
		print("  → [card effect] curse_remove_affinity: removed '%s' from card pool; boosted '%s' damage +30%%" % [removed_affinity, top_type])
	else:
		print("  → [card effect] curse_remove_affinity: removed '%s' from card pool (no other affinity to boost)" % removed_affinity)
