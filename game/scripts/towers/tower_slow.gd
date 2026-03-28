extends "res://scripts/towers/tower_base.gd"

const SLOW_DURATION: float = 2.0

var _full_stopped: Dictionary = {}
var _plague_pulse_added: bool = false


func _ready() -> void:
	_tower_type = "slow"
	damage = 5
	range_px = 96.0
	attack_speed = 2.0
	projectile_color = Color(0.31, 0.63, 0.90)
	projectile_slow_duration = SLOW_DURATION
	range_color = Color(0.7, 0.3, 1.0, 1.0)  # purple
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	# slow_aura: keep all in-range enemies slowed while in range
	if CardManager.has_effect("slow_aura"):
		for enemy: Node2D in _enemies_in_range:
			if is_instance_valid(enemy) and enemy.has_method("apply_slow"):
				enemy.apply_slow(0.5, 0.3)
	# slow_plague_pulse: lazily add a 3s interval pulse
	if not _plague_pulse_added and CardManager.has_effect("slow_plague_pulse"):
		_plague_pulse_added = true
		var t: Timer = Timer.new()
		t.wait_time = 3.0
		t.autostart = true
		t.timeout.connect(_on_plague_pulse)
		add_child(t)


func _on_plague_pulse() -> void:
	var enemies: Array = []
	_collect_enemies_near_pos(get_tree().current_scene, global_position, 200.0, enemies)
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 2.0)
	if enemies.size() > 0:
		print("[slow_plague_pulse] pulsed %d enemies" % enemies.size())


func _on_body_entered(body: Node2D) -> void:
	super._on_body_entered(body)
	# slow_full_stop: freeze the first time an enemy enters range (needs slow_aura too)
	if CardManager.has_effect("slow_full_stop") and CardManager.has_effect("slow_aura"):
		var eid: int = body.get_instance_id()
		if body.has_method("take_damage") and not _full_stopped.has(eid):
			_full_stopped[eid] = true
			if body.has_method("freeze"):
				body.freeze(0.3)
			print("[slow_full_stop] froze %s" % body.name)


func _on_body_exited(body: Node2D) -> void:
	super._on_body_exited(body)
	_full_stopped.erase(body.get_instance_id())


func _attack_target(target: Node2D) -> void:
	if debug_attacks:
		print("[%s] Slowed %s for %.0fs" % [name, target.name, SLOW_DURATION])
	_spawn_projectile(target)


func _collect_enemies_near_pos(node: Node, pos: Vector2, radius: float, result: Array) -> void:
	for child in node.get_children():
		if child.has_method("take_damage") and pos.distance_to(child.global_position) <= radius:
			result.append(child)
		if child.get_child_count() > 0:
			_collect_enemies_near_pos(child, pos, radius, result)
