extends Control

signal card_clicked(card_id: String)

const RARITY_COLORS: Dictionary = {
	"common":    Color(0.16, 0.17, 0.16),
	"uncommon":  Color(0.09, 0.18, 0.09),
	"rare":      Color(0.07, 0.12, 0.28),
	"legendary": Color(0.24, 0.14, 0.04),
}

const RARITY_ACCENT_COLORS: Dictionary = {
	"common":    Color(0.50, 0.50, 0.52),
	"uncommon":  Color(0.30, 0.65, 0.25),
	"rare":      Color(0.20, 0.45, 0.90),
	"legendary": Color(0.90, 0.65, 0.10),
}

var _card_id: String = ""

@onready var _background: ColorRect = $Background
@onready var _accent_strip: ColorRect = $MarginContainer/VBox/AccentStrip
@onready var _hover_highlight: ColorRect = $HoverHighlight
@onready var _name_label: Label = $MarginContainer/VBox/NameLabel
@onready var _rarity_label: Label = $MarginContainer/VBox/RarityLabel
@onready var _desc_label: Label = $MarginContainer/VBox/DescriptionLabel
@onready var _flavor_label: Label = $MarginContainer/VBox/FlavorLabel


func setup(card_data: Dictionary) -> void:
	_card_id = card_data.get("id", "")
	var rarity: String = card_data.get("rarity", "common")
	_background.color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	_accent_strip.color = RARITY_ACCENT_COLORS.get(rarity, RARITY_ACCENT_COLORS["common"])
	_name_label.text = card_data.get("name", "")
	_rarity_label.text = rarity.capitalize()
	_rarity_label.add_theme_color_override("font_color", RARITY_ACCENT_COLORS.get(rarity, RARITY_ACCENT_COLORS["common"]))
	_desc_label.text = card_data.get("description", "")
	_flavor_label.text = card_data.get("flavor_text", "")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(_card_id)


func _on_mouse_entered() -> void:
	_hover_highlight.visible = true


func _on_mouse_exited() -> void:
	_hover_highlight.visible = false
