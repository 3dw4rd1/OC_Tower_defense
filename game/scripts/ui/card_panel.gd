extends Control

signal card_clicked(card_id: String)

const RARITY_COLORS: Dictionary = {
	"common":    Color(0.533, 0.533, 0.533),
	"uncommon":  Color(0.290, 0.486, 0.247),
	"rare":      Color(0.165, 0.373, 0.627),
	"legendary": Color(0.722, 0.525, 0.043),
}

var _card_id: String = ""

@onready var _background: ColorRect = $Background
@onready var _hover_highlight: ColorRect = $HoverHighlight
@onready var _name_label: Label = $MarginContainer/VBox/NameLabel
@onready var _rarity_label: Label = $MarginContainer/VBox/RarityLabel
@onready var _desc_label: Label = $MarginContainer/VBox/DescriptionLabel
@onready var _flavor_label: Label = $MarginContainer/VBox/FlavorLabel


func setup(card_data: Dictionary) -> void:
	_card_id = card_data.get("id", "")
	var rarity: String = card_data.get("rarity", "common")
	_background.color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	_name_label.text = card_data.get("name", "")
	_rarity_label.text = rarity.capitalize()
	_desc_label.text = card_data.get("description", "")
	_flavor_label.text = card_data.get("flavor_text", "")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(_card_id)


func _on_mouse_entered() -> void:
	_hover_highlight.visible = true


func _on_mouse_exited() -> void:
	_hover_highlight.visible = false
