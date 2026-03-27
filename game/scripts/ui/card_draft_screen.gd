extends CanvasLayer

signal draft_complete

const _CARD_PANEL_SCENE := preload("res://scenes/ui/card_panel.tscn")

@onready var _card_row: HBoxContainer = $Center/VBox/CardRow


func _ready() -> void:
	visible = false
	CardManager.card_draft_started.connect(_on_card_draft_started)


func _on_card_draft_started(cards: Array) -> void:
	for child in _card_row.get_children():
		child.queue_free()
	for card_data: Dictionary in cards:
		var panel: Control = _CARD_PANEL_SCENE.instantiate()
		_card_row.add_child(panel)
		panel.setup(card_data)
		panel.card_clicked.connect(func(cid: String) -> void: _on_card_clicked(cid, panel))
	visible = true


func _on_card_clicked(card_id: String, clicked_panel: Control) -> void:
	# Disable further input during animation
	for panel: Control in _card_row.get_children():
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardManager.pick_card(card_id)
	var tween := create_tween()
	tween.tween_property(clicked_panel, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(clicked_panel, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	visible = false
	draft_complete.emit()
