class_name EntityUI
extends Control

## Compact floating HP/MP bars bound to a single CombatEntity.
## Also acts as a drag-and-drop target for CardVisual plays.

const HEALTH_FILL := Color(0.2, 0.8, 0.2, 1.0)
const MANA_FILL := Color(0.2, 0.4, 0.9, 1.0)
const ENEMY_HEALTH_FILL := Color(0.8, 0.2, 0.2, 1.0)

@export var health_bar: ProgressBar
@export var mana_bar: ProgressBar

## Set in setup() — the CombatEntity this widget represents.
var parent_entity: CombatEntity
var _entity: CombatEntity


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	_apply_bar_colors()


func setup(entity: CombatEntity) -> void:
	_disconnect_entity()
	parent_entity = entity
	_entity = entity
	if _entity == null:
		return
	if not _entity.local_health_changed.is_connected(_on_local_health_changed):
		_entity.local_health_changed.connect(_on_local_health_changed)
	if not _entity.local_mana_changed.is_connected(_on_local_mana_changed):
		_entity.local_mana_changed.connect(_on_local_mana_changed)
	_on_local_health_changed(_entity.current_hp, _entity.max_hp)
	_on_local_mana_changed(_entity.current_mana, _entity.max_mana)
	_apply_bar_colors()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if parent_entity == null or not is_instance_valid(parent_entity):
		return false
	if CombatStateMachine.current_phase != CombatStateMachine.Phase.PLAYER_MAIN:
		return false
	return data is Resource


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if parent_entity == null or not (data is Resource):
		return
	EventBus.card_played.emit(data as Resource, parent_entity)


func _disconnect_entity() -> void:
	if _entity == null:
		return
	if _entity.local_health_changed.is_connected(_on_local_health_changed):
		_entity.local_health_changed.disconnect(_on_local_health_changed)
	if _entity.local_mana_changed.is_connected(_on_local_mana_changed):
		_entity.local_mana_changed.disconnect(_on_local_mana_changed)
	_entity = null
	parent_entity = null


func _on_local_health_changed(new_hp: int, max_hp: int) -> void:
	if health_bar == null:
		return
	health_bar.max_value = float(max_hp)
	health_bar.value = float(new_hp)


func _on_local_mana_changed(new_mana: int, max_mana: int) -> void:
	if mana_bar == null:
		return
	mana_bar.max_value = float(max_mana)
	mana_bar.value = float(new_mana)
	mana_bar.visible = max_mana > 0


func _gui_input(event: InputEvent) -> void:
	if _entity == null:
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			EventBus.entity_clicked.emit(_entity)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			EventBus.entity_clicked.emit(_entity)
			accept_event()


func _on_mouse_entered() -> void:
	if _entity != null:
		EventBus.target_hovered.emit(_entity)


func _apply_bar_colors() -> void:
	var hp_color: Color = HEALTH_FILL
	if _entity != null and _entity.entity_id != "player" and not _entity.is_in_group("player"):
		hp_color = ENEMY_HEALTH_FILL
	_set_bar_fill(health_bar, hp_color)
	_set_bar_fill(mana_bar, MANA_FILL)


func _set_bar_fill(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", style)
	bar.show_percentage = false


func _exit_tree() -> void:
	_disconnect_entity()
