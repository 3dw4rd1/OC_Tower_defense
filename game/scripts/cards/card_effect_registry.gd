extends RefCounted
# Plain script — not an autoload. Instantiated and owned by CardManager.
# Only tower_attack_speed, tower_damage, and tower_range are fully implemented (Steps 1-5).
# All other effect IDs are stubs that will be filled in later steps.


func apply(effect: String, params: Dictionary, card_manager: Node) -> void:
	match effect:
		# --- Simple tower stat multipliers (Step 5) ---
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

		# --- Meta ---
		"rare_weight_boost":
			card_manager.rare_weight_bonus += 0.08

		# --- Stubs: economy (Step 7) ---
		"wave_bonus_flat", "kill_gold_flat", "tower_cost_reduction":
			pass  # TODO Step 7

		# --- Stubs: tower stat variants (Step 5 extension) ---
		"tower_aoe_radius", "tower_slow_intensity":
			pass  # TODO Step 5 extension

		# --- Stubs: synergy flags (Step 9) ---
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

		# --- Stubs: rifle mechanics (Step 10) ---
		"rifle_kill_chain", "rifle_overcharge", "rifle_ricochet", "rifle_double_tap":
			card_manager.active_effects[effect] = true

		# --- Stubs: sniper mechanics (Step 10) ---
		"sniper_execute", "sniper_suppress", "sniper_chain_suppress", "sniper_one_shot":
			card_manager.active_effects[effect] = true

		# --- Stubs: splash mechanics (Step 10) ---
		"splash_fire_dot", "splash_knockback", "splash_napalm", "splash_shockwave":
			card_manager.active_effects[effect] = true

		# --- Stubs: slow mechanics (Step 10) ---
		"slow_aura", "slow_dot", "slow_plague_pulse", "slow_full_stop":
			card_manager.active_effects[effect] = true

		# --- Stubs: map (Step 7) ---
		"spawn_slow_tile", "remove_obstacles", "spawn_obstacles":
			pass  # TODO Step 7

		# --- Stubs: curses (Step 8) ---
		"curse_next_wave_horde", "curse_temp_damage_penalty", \
		"curse_brute_gold_boost", "curse_remove_affinity":
			pass  # TODO Step 8

		_:
			push_warning("CardEffectRegistry: unhandled effect '%s'" % effect)
