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

const SELECTED_MODULATE: Color = Color(1.5, 1.5, 0.6, 1.0)
const NORMAL_MODULATE: Color = Color(1.0, 1.0, 1.0, 1.0)

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


func set_selected_tower_button(tower_type: String) -> void:
	_selected_type = tower_type
	_basic_btn.modulate = SELECTED_MODULATE if tower_type == "basic" else NORMAL_MODULATE
	_sniper_btn.modulate = SELECTED_MODULATE if tower_type == "sniper" else NORMAL_MODULATE
	_splash_btn.modulate = SELECTED_MODULATE if tower_type == "splash" else NORMAL_MODULATE
	_slow_btn.modulate = SELECTED_MODULATE if tower_type == "slow" else NORMAL_MODULATE
	_wall_btn.modulate = SELECTED_MODULATE if tower_type == "wall" else NORMAL_MODULATE


func _on_gold_changed(new_amount: int) -> void:
	_gold_label.text = "Gold: %d" % new_amount


func _on_base_hp_changed(new_hp: int) -> void:
	_hp_label.text = "HP: %d / 50" % new_hp


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
	_wall_btn.text = "Wall (25g)\n%d/20" % count


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
