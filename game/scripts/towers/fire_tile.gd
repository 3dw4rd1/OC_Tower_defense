extends Node2D

var radius: float = 48.0
var tick_damage: int = 1

const DURATION: float = 2.0
const TICK_INTERVAL: float = 0.5

var _elapsed: float = 0.0
var _tick_elapsed: float = 0.0
var _ever_hit: Dictionary = {}
var _prev_in_radius: Dictionary = {}


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	_tick_elapsed += delta
	if _tick_elapsed >= TICK_INTERVAL:
		_tick_elapsed -= TICK_INTERVAL
		_do_tick()


func _do_tick() -> void:
	var cur_in_radius: Dictionary = {}
	var enemies: Array = []
	if get_tree() and get_tree().current_scene:
		_collect_enemies(get_tree().current_scene, enemies)
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var eid: int = e.get_instance_id()
		cur_in_radius[eid] = e
		var dmg: int = tick_damage
		if CardManager.has_effect("splash_napalm"):
			if _ever_hit.has(eid) and not _prev_in_radius.has(eid):
				# Re-entry: enemy left and came back — double damage
				dmg = tick_damage * 2
		_ever_hit[eid] = true
		if e.has_method("take_damage"):
			e.take_damage(dmg)
	_prev_in_radius = cur_in_radius


func _collect_enemies(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child.has_method("take_damage"):
			if global_position.distance_to(child.global_position) <= radius:
				result.append(child)
		if child.get_child_count() > 0:
			_collect_enemies(child, result)
