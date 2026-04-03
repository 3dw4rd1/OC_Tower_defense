extends CanvasLayer

const ENEMY_DISPLAY_NAMES: Dictionary = {
	"basic": "Shambler",
	"scout": "Scout",
	"fast":  "Runner",
	"tank":  "Brute",
	"boss":  "BOSS",
	"elite": "Elite",
}

# Base enemy HP and speed (from scene defaults, used for legacy wave scaling)
const BASE_HP: Dictionary    = {"basic": 30,   "fast": 15,    "tank": 120, "elite": 80}
const BASE_SPEED: Dictionary = {"basic": 80.0, "fast": 144.0, "tank": 40.0, "elite": 96.0}

var _panel: Panel
var _rows_container: VBoxContainer
var _toggle_btn: Button
var _is_open: bool = false


func _ready() -> void:
	layer = 2
	_build_ui()
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)


func _build_ui() -> void:
	# ── Toggle button (always visible, top-left) ─────────────────────────────
	_toggle_btn = Button.new()
	_toggle_btn.text = "Wave Info"
	_toggle_btn.position = Vector2(8, 8)
	_toggle_btn.custom_minimum_size = Vector2(80, 24)
	_toggle_btn.add_theme_font_size_override("font_size", 11)
	_toggle_btn.add_theme_color_override("font_color", Color(0.90, 0.88, 0.82))

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.10, 0.10, 0.10, 0.75)
	btn_style.border_color = Color(0.55, 0.72, 0.40)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(2)
	btn_style.set_content_margin_all(4)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.20, 0.20, 0.20, 0.85)
	btn_hover.border_color = Color(0.75, 0.90, 0.55)
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(2)
	btn_hover.set_content_margin_all(4)

	_toggle_btn.add_theme_stylebox_override("normal", btn_style)
	_toggle_btn.add_theme_stylebox_override("hover", btn_hover)
	_toggle_btn.add_theme_stylebox_override("pressed", btn_hover)
	_toggle_btn.pressed.connect(toggle)
	add_child(_toggle_btn)

	# ── Info panel (left side, hidden by default) ─────────────────────────────
	_panel = Panel.new()
	_panel.position = Vector2(8, 40)
	_panel.size = Vector2(280, 420)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.6)
	panel_style.border_color = Color(0.45, 0.45, 0.45, 0.8)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(3)
	panel_style.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", panel_style)
	_panel.visible = false
	add_child(_panel)

	# ScrollContainer fills the panel (with 6px margin from panel style)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(6, 6)
	scroll.size = Vector2(268, 408)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_FILL
	_rows_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_rows_container)


func toggle() -> void:
	_is_open = !_is_open
	_panel.visible = _is_open
	if _is_open:
		refresh_wave_data(GameManager.current_wave)


func _on_wave_started(wave_num: int) -> void:
	if _is_open:
		refresh_wave_data(wave_num)


func _on_wave_completed(_wave_num: int) -> void:
	if _is_open:
		refresh_wave_data(GameManager.current_wave)


func refresh_wave_data(wave_num: int) -> void:
	for child in _rows_container.get_children():
		child.queue_free()

	if wave_num == 0:
		_add_label("No wave in progress", Color(0.75, 0.75, 0.75, 1.0))
		return

	var is_endless := wave_num > GameManager.TOTAL_WAVES
	var wave_text: String
	if is_endless:
		wave_text = "Wave %d  [ENDLESS +%d]" % [wave_num, wave_num - GameManager.TOTAL_WAVES]
	else:
		wave_text = "Wave %d / %d" % [wave_num, GameManager.TOTAL_WAVES]
	_add_label(wave_text, Color(1.0, 0.85, 0.30, 1.0))

	var alive := WaveManager.get_alive_count()
	if alive > 0:
		_add_label("Alive: %d" % alive, Color(1.0, 0.50, 0.50, 1.0))

	_add_separator()
	_add_row("Type", "Count", "HP", "Speed", true)
	_add_separator()

	var groups := _compute_wave_groups(wave_num)
	for g: Dictionary in groups:
		_add_row(
			ENEMY_DISPLAY_NAMES.get(g["type"], g["type"]),
			str(g["count"]),
			str(g["hp"]),
			"%.0f" % g["speed"]
		)


func _compute_wave_groups(wave_num: int) -> Array:
	var groups: Array = []

	if wave_num <= 10:
		# ── Plan A (waves 1–10) ──────────────────────────────────────────────
		var idx := wave_num - 1
		var total_count: int = WaveManager.PLAN_A_COUNTS[idx]
		var hp: int          = WaveManager.PLAN_A_HP[idx]
		var spd_mult: float  = WaveManager.PLAN_A_SPEED_MULT[idx]
		var speed: float     = WaveManager.PLAN_A_BASE_SPEED * spd_mult

		var scout_count: int   = 0
		var regular_count: int = total_count
		if wave_num >= 5:
			scout_count   = int(round(total_count * 0.225))
			regular_count = total_count - scout_count

		var elite_count: int = 0
		if wave_num == 10:
			elite_count   = int(round(total_count * 0.10))
			regular_count -= elite_count

		if wave_num % 5 == 0:
			groups.append({"type": "boss", "count": 1,
				"hp": hp * 8, "speed": WaveManager.PLAN_A_BASE_SPEED * spd_mult * 0.7})
		if regular_count > 0:
			groups.append({"type": "basic", "count": regular_count, "hp": hp, "speed": speed})
		if scout_count > 0:
			groups.append({"type": "scout", "count": scout_count,
				"hp": int(hp * 0.4), "speed": speed * 2.0})
		if elite_count > 0:
			groups.append({"type": "elite", "count": elite_count, "hp": hp, "speed": speed})

	elif wave_num <= 25:
		# ── Legacy (waves 11–25) ─────────────────────────────────────────────
		var legacy_idx := wave_num - 11
		var data: Dictionary     = WaveManager.LEGACY_WAVE_DATA[legacy_idx]
		var steps: int           = wave_num - 10
		var count_mult: float    = pow(1.08, steps)
		var hp_mult: float       = pow(1.10, steps)
		var spd_mult: float      = pow(1.05, steps)

		if wave_num % 5 == 0:
			groups.append({"type": "boss", "count": 1,
				"hp": int(120 * pow(1.10, steps) * 8),
				"speed": 40.0 * pow(1.05, steps) * 0.7})

		var total_legacy: int = 0
		var temp: Array = []
		for enemy_type: String in data:
			var count: int  = int(ceil(data[enemy_type] * count_mult))
			var s_hp: int   = int(BASE_HP.get(enemy_type, 30) * hp_mult)
			var s_spd: float = BASE_SPEED.get(enemy_type, 80.0) * spd_mult
			total_legacy += count
			temp.append({"type": enemy_type, "count": count, "hp": s_hp, "speed": s_spd})

		var elite_ratio: float = lerpf(0.10, 0.25, float(clamp(wave_num - 10, 0, 10)) / 10.0)
		var elite_count: int   = int(round(total_legacy * elite_ratio))
		if elite_count > 0:
			groups.append({"type": "elite", "count": elite_count,
				"hp": int(BASE_HP["elite"] * hp_mult),
				"speed": BASE_SPEED["elite"] * spd_mult})

		groups.append_array(temp)

	else:
		# ── Endless (wave 26+) ───────────────────────────────────────────────
		var step: int        = wave_num - 25
		var ehp: float       = pow(1.18, step)
		var espd: float      = pow(1.07, step)
		var ecnt: float      = pow(1.12, step)
		var total: int       = int(ceil(75 * ecnt))
		var e_ratio: float   = min(0.35, 0.25 + step * 0.01)
		var t_ratio: float   = 0.20
		var f_ratio: float   = 0.25

		if wave_num % 5 == 0:
			var ms: int = wave_num - 10
			groups.append({"type": "boss", "count": 1,
				"hp": int(120 * pow(1.10, ms) * 8 * ehp),
				"speed": 40.0 * pow(1.05, ms) * 0.7 * espd})

		var elite_n: int = int(round(total * e_ratio))
		var tank_n: int  = int(round(total * t_ratio))
		var fast_n: int  = int(round(total * f_ratio))
		var basic_n: int = total - elite_n - tank_n - fast_n

		if elite_n > 0:
			groups.append({"type": "elite", "count": elite_n,
				"hp": int(400 * ehp), "speed": 96.0  * 2.1 * espd})
		if tank_n > 0:
			groups.append({"type": "tank",  "count": tank_n,
				"hp": int(600 * ehp), "speed": 40.0  * 2.1 * espd})
		if fast_n > 0:
			groups.append({"type": "fast",  "count": fast_n,
				"hp": int(150 * ehp), "speed": 144.0 * 2.1 * espd})
		if basic_n > 0:
			groups.append({"type": "basic", "count": basic_n,
				"hp": int(300 * ehp), "speed": 80.0  * 2.1 * espd})

	return groups


func _add_label(text_str: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	_rows_container.add_child(lbl)


func _add_separator() -> void:
	_rows_container.add_child(HSeparator.new())


func _add_row(col_type: String, col_count: String, col_hp: String, col_speed: String, is_header: bool = false) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_FILL

	var cols   := [col_type, col_count, col_hp, col_speed]
	var widths := [95,       45,        65,      60]
	var color  := Color(1.0, 0.85, 0.30, 1.0) if is_header else Color(1, 1, 1, 1)

	for i: int in range(cols.size()):
		var lbl := Label.new()
		lbl.text = cols[i]
		lbl.custom_minimum_size.x = float(widths[i])
		lbl.add_theme_color_override("font_color", color)
		lbl.add_theme_font_size_override("font_size", 11)
		hbox.add_child(lbl)

	_rows_container.add_child(hbox)
