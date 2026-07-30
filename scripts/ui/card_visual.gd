class_name CardVisual
extends PanelContainer

## Single-card UI widget. Bind labels/background in the editor, then call setup().
## Supports click-to-target and mouse/touch drag-and-drop onto EntityUI.

const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_TWEEN_SEC: float = 0.12
const DRAG_PREVIEW_SCALE := Vector2(0.85, 0.85)

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


func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_data == null:
		return null
	var preview: Control = duplicate() as Control
	if preview != null:
		preview.scale = DRAG_PREVIEW_SCALE
		preview.modulate = Color(1, 1, 1, 0.92)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_drag_preview(preview)
	return card_data


func _gui_input(event: InputEvent) -> void:
	if card_data == null:
		return
	# Click / tap selects card for targeting (drag uses _get_drag_data instead).
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			if get_viewport().gui_is_dragging():
				return
			card_clicked.emit(card_data)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if not touch.pressed and not get_viewport().gui_is_dragging():
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
