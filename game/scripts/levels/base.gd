extends Node2D

@onready var _hp_label: Label = $HPLabel


func _ready() -> void:
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	_hp_label.text = "HP: %d" % GameManager.base_hp


func _on_base_hp_changed(new_hp: int) -> void:
	_hp_label.text = "HP: %d" % new_hp


func _on_detection_area_body_entered(body: Node2D) -> void:
	GameManager.damage_base(1)
	if body.has_method("reach_base"):
		body.reach_base()
	else:
		body.queue_free()
