class_name CardVisual
extends PanelContainer

## Single-card UI widget. Bind labels/background in the editor, then call setup().

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_SEC: float = 0.12

signal card_clicked(card_data: Resource)

@export var name_label: Label
@export var cost_label: Label
@export var description_label: Label
@export var card_background: TextureRect

var card_data: Resource

var _hover_tween: Tween
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_base_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(data: Resource) -> void:
	card_data = data
	if data == null:
		_clear_labels()
		return

	if name_label != null:
		name_label.text = _resolve_card_name(data)
	if cost_label != null:
		cost_label.text = str(_resolve_mana_cost(data))
	if description_label != null:
		description_label.text = _resolve_description(data)


func _gui_input(event: InputEvent) -> void:
	if card_data == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(card_data)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			card_clicked.emit(card_data)
			accept_event()


func _on_mouse_entered() -> void:
	_tween_scale(HOVER_SCALE)


func _on_mouse_exited() -> void:
	_tween_scale(_base_scale)


func _tween_scale(target: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target, HOVER_TWEEN_SEC)


func _clear_labels() -> void:
	if name_label != null:
		name_label.text = ""
	if cost_label != null:
		cost_label.text = ""
	if description_label != null:
		description_label.text = ""


func _resolve_card_name(data: Resource) -> String:
	if "card_name" in data:
		return str(data.get("card_name"))
	if "display_name" in data:
		return str(data.get("display_name"))
	return data.resource_name


func _resolve_mana_cost(data: Resource) -> int:
	if "mana_cost" in data:
		return int(data.get("mana_cost"))
	return 0


func _resolve_description(data: Resource) -> String:
	if "description" in data:
		return str(data.get("description"))
	return ""
