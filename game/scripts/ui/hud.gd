extends CanvasLayer

@onready var _gold_label: Label = $BottomBar/StatsBar/GoldLabel
@onready var _hp_label: Label = $BottomBar/StatsBar/HPLabel
@onready var _wave_label: Label = $BottomBar/StatsBar/WaveLabel
@onready var _enemy_count_label: Label = $BottomBar/StatsBar/EnemyCountLabel
@onready var _game_over_overlay: Control = $GameOverOverlay
@onready var _victory_overlay: Control = $VictoryOverlay
@onready var _basic_btn: Button = $BottomBar/TowerPanel/BasicBtn
@onready var _sniper_btn: Button = $BottomBar/TowerPanel/SniperBtn
@onready var _splash_btn: Button = $BottomBar/TowerPanel/SplashBtn
@onready var _slow_btn: Button = $BottomBar/TowerPanel/SlowBtn
@onready var _wall_btn: Button = $BottomBar/TowerPanel/WallBtn

# StyleBoxFlat styles for tower buttons
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_selected: StyleBoxFlat

var _selected_type: String = ""
var _wall_count: int = 0


func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)
	WaveManager.enemy_count_changed.connect(_on_enemy_count_changed)

	_gold_label.text = "Gold: %d" % GameManager.gold
	_hp_label.text = "HP: %d / 50" % GameManager.base_hp
	_wave_label.text = "Wave %d / %d" % [GameManager.current_wave, GameManager.TOTAL_WAVES]
	_enemy_count_label.text = "Enemies: 0"
	_game_over_overlay.visible = false
	_victory_overlay.visible = false

	_gold_label.add_theme_color_override("font_color", Color(0.85, 0.70, 0.15))   # Survivor Gold
	_hp_label.add_theme_color_override("font_color", Color(0.72, 0.12, 0.10))     # Zombie Red
	_wave_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))   # Dirty White
	_enemy_count_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))  # Dirty White

	# Build button styles
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.15, 0.20, 0.13)
	_style_normal.border_color = Color(0.35, 0.45, 0.28)
	_style_normal.set_border_width_all(1)
	_style_normal.set_corner_radius_all(2)
	_style_normal.set_content_margin_all(8)

	_style_hover = StyleBoxFlat.new()
	_style_hover.bg_color = Color(0.22, 0.30, 0.18)
	_style_hover.border_color = Color(0.55, 0.72, 0.40)
	_style_hover.set_border_width_all(1)
	_style_hover.set_corner_radius_all(2)
	_style_hover.set_content_margin_all(8)

	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.28, 0.38, 0.22)
	_style_selected.border_color = Color(0.85, 0.70, 0.15)   # gold border = selected
	_style_selected.set_border_width_all(2)
	_style_selected.set_corner_radius_all(2)
	_style_selected.set_content_margin_all(8)

	# Apply styles to all tower buttons
	for btn in [_basic_btn, _sniper_btn, _splash_btn, _slow_btn, _wall_btn]:
		btn.add_theme_stylebox_override("normal", _style_normal)
		btn.add_theme_stylebox_override("hover", _style_hover)
		btn.add_theme_stylebox_override("pressed", _style_selected)
		btn.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))
		btn.add_theme_font_size_override("font_size", 12)


func set_selected_tower_button(tower_type: String) -> void:
	_selected_type = tower_type
	for btn in [_basic_btn, _sniper_btn, _splash_btn, _slow_btn, _wall_btn]:
		btn.add_theme_stylebox_override("normal", _style_normal)
		btn.modulate = Color(1, 1, 1, 1)

	var selected_btn: Button = null
	match tower_type:
		"basic":   selected_btn = _basic_btn
		"sniper":  selected_btn = _sniper_btn
		"splash":  selected_btn = _splash_btn
		"slow":    selected_btn = _slow_btn
		"wall":    selected_btn = _wall_btn

	if selected_btn:
		selected_btn.add_theme_stylebox_override("normal", _style_selected)


func _on_gold_changed(new_amount: int) -> void:
	_gold_label.text = "Gold: %d" % new_amount


func _on_base_hp_changed(new_hp: int) -> void:
	_hp_label.text = "HP: %d / 50" % new_hp
	if new_hp <= 10:
		_hp_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.10))
	else:
		_hp_label.add_theme_color_override("font_color", Color(0.72, 0.12, 0.10))


func _on_wave_started(wave_num: int) -> void:
	_wave_label.text = "Wave %d / %d" % [wave_num, GameManager.TOTAL_WAVES]


func _on_wave_completed(_wave_num: int) -> void:
	_enemy_count_label.text = "Enemies: 0"


func _on_enemy_count_changed(count: int) -> void:
	_enemy_count_label.text = "Enemies: %d" % count


func _on_game_over() -> void:
	_game_over_overlay.visible = true


func _on_victory() -> void:
	_victory_overlay.visible = true


func _on_basic_button_pressed() -> void:
	_select_tower("basic")


func _on_sniper_button_pressed() -> void:
	_select_tower("sniper")


func _on_splash_button_pressed() -> void:
	_select_tower("splash")


func _on_slow_button_pressed() -> void:
	_select_tower("slow")


func _on_wall_button_pressed() -> void:
	_select_tower("wall")


func update_wall_button(count: int) -> void:
	_wall_count = count
	_wall_btn.text = "Barbed Wire\n25g  %d/20" % count


func _select_tower(tower_type: String) -> void:
	var game_map: Node = get_parent().get_node_or_null("GameMap")
	if not game_map:
		return
	# Toggle: clicking the already-selected type cancels placement
	if _selected_type == tower_type:
		game_map.cancel_placement()
		set_selected_tower_button("")
	else:
		set_selected_tower_button(tower_type)
		game_map.select_tower_type(tower_type)


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
