extends CanvasLayer

@onready var _gold_label: Label = $GoldLabel
@onready var _hp_label: Label = $HPLabel
@onready var _wave_label: Label = $WaveLabel
@onready var _enemy_count_label: Label = $EnemyCountLabel
@onready var _game_over_overlay: Control = $GameOverOverlay
@onready var _victory_overlay: Control = $VictoryOverlay


func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)
	WaveManager.enemy_count_changed.connect(_on_enemy_count_changed)

	_gold_label.text = "Gold: %d" % GameManager.gold
	_hp_label.text = "HP: %d / 20" % GameManager.base_hp
	_wave_label.text = "Wave %d / 10" % GameManager.current_wave
	_enemy_count_label.text = "Enemies: 0"
	_game_over_overlay.visible = false
	_victory_overlay.visible = false


func _on_gold_changed(new_amount: int) -> void:
	_gold_label.text = "Gold: %d" % new_amount


func _on_base_hp_changed(new_hp: int) -> void:
	_hp_label.text = "HP: %d / 20" % new_hp


func _on_wave_started(wave_num: int) -> void:
	_wave_label.text = "Wave %d / 10" % wave_num


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


func _select_tower(tower_type: String) -> void:
	var game_map: Node = get_parent().get_node_or_null("GameMap")
	if game_map:
		game_map.selected_tower_type = tower_type


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
