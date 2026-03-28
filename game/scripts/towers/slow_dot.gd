extends Node2D

const TICK_DAMAGE: int = 2
const DURATION: float = 2.0
const TICK_INTERVAL: float = 0.5

var _elapsed: float = 0.0
var _tick_elapsed: float = 0.0


func _ready() -> void:
	name = "SlowDoT"


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	_tick_elapsed += delta
	if _tick_elapsed >= TICK_INTERVAL:
		_tick_elapsed -= TICK_INTERVAL
		var parent: Node = get_parent()
		if is_instance_valid(parent) and parent.has_method("take_damage"):
			parent.take_damage(TICK_DAMAGE)
