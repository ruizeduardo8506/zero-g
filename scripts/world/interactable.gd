class_name Interactable
extends Area2D

## Top-down talk/door/save hotspot. Keyboard: E or ui_accept. Touch: tap the area.

signal interacted

@export var prompt_text: String = "Interact"
@export var interact_id: String = ""
@export var marker_color: Color = Color(0.9, 0.75, 0.25, 1.0)

var _player_inside: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	if _get_shape() == null:
		_add_default_shape()
	_add_marker()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("ui_accept"):
		_emit_interact()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_emit_interact()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("overworld_player"):
		return
	_player_inside = true
	EventBus.interact_prompt_changed.emit(prompt_text)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("overworld_player"):
		return
	_player_inside = false
	EventBus.interact_prompt_changed.emit("")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_emit_interact()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_emit_interact()


func _emit_interact() -> void:
	interacted.emit()


func _get_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _add_default_shape() -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GameConstants.TILE_SIZE * 2, GameConstants.TILE_SIZE * 2)
	shape_node.shape = rect
	add_child(shape_node)


func _add_marker() -> void:
	if get_node_or_null("Marker") != null:
		return
	var marker := ColorRect.new()
	marker.name = "Marker"
	marker.size = Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	marker.position = Vector2(-GameConstants.TILE_SIZE * 0.5, -GameConstants.TILE_SIZE * 0.5)
	marker.color = marker_color
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)
