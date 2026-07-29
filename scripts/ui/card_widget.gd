class_name CardWidget
extends PanelContainer

signal card_pressed(card: CardData)

@export var max_width: float = 120.0
@export var aspect_ratio: float = 1.4

var card_data: CardData
var _current_mana: int = 0
var _is_playable: bool = false

@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel
@onready var _class_label: Label = %ClassLabel
@onready var _glow: ColorRect = %Glow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	resized.connect(_on_resized)
	_apply_size()


func setup(card: CardData, current_mana: int) -> void:
	card_data = card
	_current_mana = current_mana
	_is_playable = card.is_playable(current_mana)
	_name_label.text = card.display_name
	_cost_label.text = "◆ %d" % card.mana_cost if not card.drains_full_mana else "◆ ALL"
	_class_label.text = CardData.BaseClass.keys()[card.base_class]
	modulate = Color(1, 1, 1, 1) if _is_playable else Color(0.55, 0.55, 0.6, 0.85)
	_glow.visible = _is_playable
	_apply_size()


func _apply_size() -> void:
	var width: float = mini(size.x, max_width) if size.x > 0 else max_width
	custom_minimum_size = Vector2(width, width * aspect_ratio)


func _on_resized() -> void:
	_apply_size()


func _on_gui_input(event: InputEvent) -> void:
	if not _is_playable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(card_data)
	elif event is InputEventScreenTouch and event.pressed:
		card_pressed.emit(card_data)
