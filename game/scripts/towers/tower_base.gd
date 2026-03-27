extends Node2D

const PROJECTILE_SCENE = preload("res://scenes/towers/Projectile.tscn")

@export var debug_attacks: bool = false

var damage: int = 10
var range_px: float = 96.0
var attack_speed: float = 1.0  # attacks per second
var projectile_color: Color = Color(0.86, 0.63, 0.24)
var projectile_aoe_radius: float = 0.0
var projectile_slow_duration: float = 0.0
var range_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# Tower type string set by each subclass before calling super._ready()
var _tower_type: String = ""

# Base stats captured at _ready() time; _apply_card_modifiers() always multiplies from these
var _base_damage: int = 0
var _base_range_px: float = 0.0
var _base_attack_speed: float = 0.0

var _attack_timer: float = 0.0
var _enemies_in_range: Array[Node2D] = []
var _range_indicator: Node2D = null

@onready var _range_area: Area2D = $RangeArea


func _ready() -> void:
	_range_area.body_entered.connect(_on_body_entered)
	_range_area.body_exited.connect(_on_body_exited)
	# Capture base stats (subclass has already set them before calling super._ready())
	_base_damage = damage
	_base_range_px = range_px
	_base_attack_speed = attack_speed
	# Apply any cards picked so far
	_apply_card_modifiers()
	var shape: CircleShape2D = _range_area.get_node("CollisionShape2D").shape as CircleShape2D
	if shape:
		shape.radius = range_px
	_add_range_indicator()
	# Update when future cards are picked
	CardManager.card_picked.connect(_on_card_picked)


func _apply_card_modifiers() -> void:
	if _tower_type == "":
		return
	var mods: Dictionary = CardManager.get_tower_multipliers(_tower_type)
	damage = int(_base_damage * mods.get("damage", 1.0))
	range_px = _base_range_px * mods.get("range", 1.0)
	attack_speed = _base_attack_speed * mods.get("attack_speed", 1.0)
	# Apply curse damage penalty on top of normal multipliers (Step 8)
	if CardManager.curse_damage_penalty > 0.0:
		damage = int(damage * (1.0 - CardManager.curse_damage_penalty))


func _on_card_picked(_card: Dictionary) -> void:
	_apply_card_modifiers()
	# Update collision shape radius to match new range_px
	if _range_area:
		var shape: CircleShape2D = _range_area.get_node("CollisionShape2D").shape as CircleShape2D
		if shape:
			shape.radius = range_px
	if _range_indicator:
		_range_indicator.set_meta("radius", range_px)
		_range_indicator.queue_redraw()


func _add_range_indicator() -> void:
	_range_indicator = Node2D.new()
	_range_indicator.name = "RangeIndicator"
	# Store range_px in metadata so the draw callback can read it
	_range_indicator.set_meta("radius", range_px)
	var indicator_ref := _range_indicator
	_range_indicator.draw.connect(func(): _draw_range_indicator(indicator_ref))
	add_child(_range_indicator)
	_range_indicator.visible = false  # Hidden by default; show on hover or during placement


func _draw_range_indicator(indicator: Node2D) -> void:
	var r: float = indicator.get_meta("radius")
	# Filled translucent circle using range_color at low alpha
	var fill_color := Color(range_color.r, range_color.g, range_color.b, 0.08)
	indicator.draw_circle(Vector2.ZERO, r, fill_color)
	# Dashed outline — draw as a series of short arcs approximated by line segments
	var steps: int = 64
	var outline_color := Color(range_color.r, range_color.g, range_color.b, 0.55)
	for i: int in range(steps):
		if i % 4 == 3:
			continue  # gap
		var a0: float = (float(i) / steps) * TAU
		var a1: float = (float(i + 1) / steps) * TAU
		var p0: Vector2 = Vector2(cos(a0), sin(a0)) * r
		var p1: Vector2 = Vector2(cos(a1), sin(a1)) * r
		indicator.draw_line(p0, p1, outline_color, 1.0)


func show_range_indicator() -> void:
	if _range_indicator:
		_range_indicator.visible = true
		_range_indicator.queue_redraw()


func hide_range_indicator() -> void:
	if _range_indicator:
		_range_indicator.visible = false


func _process(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 1.0 / attack_speed
		_do_attack()
	# Hover to show/hide range ring on placed towers
	var dist: float = get_global_mouse_position().distance_to(global_position)
	if dist < 24.0:
		show_range_indicator()
	else:
		hide_range_indicator()


func _do_attack() -> void:
	var target: Node2D = _get_nearest_enemy()
	if target == null:
		return
	_attack_target(target)


func _attack_target(target: Node2D) -> void:
	_spawn_projectile(target)
	if debug_attacks:
		print("[%s] Fired at %s (hp: %s) — damage: %d" % [name, target.name, target.get("_hp"), damage])


func _spawn_projectile(target: Node2D) -> void:
	var proj: Node2D = PROJECTILE_SCENE.instantiate()
	proj.target = target
	proj.damage = damage
	proj.color = projectile_color
	proj.aoe_radius = projectile_aoe_radius
	proj.slow_duration = projectile_slow_duration
	proj.global_position = global_position
	get_parent().add_child(proj)


func _get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy: Node2D in _enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		_enemies_in_range.append(body)


func _on_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)
