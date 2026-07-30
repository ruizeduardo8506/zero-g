class_name CombatEntity
extends Node2D

## Base class for all combat participants (party members and enemies).
## Routes HP / mana updates through EventBus so UI stays decoupled (GDD Phase 2).
## Spawns a floating EntityUI above itself for party-scale combat readability.

const ENTITY_UI_SCENE: PackedScene = preload("res://scenes/ui/combat/entity_ui.tscn")
const ENTITY_UI_OFFSET := Vector2(-48, -56)
const CLICK_AREA_SIZE := Vector2(112, 112)

# GDD defaults: mana regen 5 / turn, mana cap 20.
@export var entity_id: String = ""
@export var max_hp: int = 100
@export var max_mana: int = 20
@export var base_mana_regen: int = 5

## Local UI signals — EntityUI / Target Frame subscribe per-entity.
signal local_health_changed(new_hp: int, max_hp: int)
signal local_mana_changed(new_mana: int, max_mana: int)

var current_hp: int = 0
var current_mana: int = 0

var _entity_ui: Control
var _click_area: Area2D


func _ready() -> void:
	if entity_id.is_empty():
		entity_id = name
	current_hp = max_hp
	current_mana = max_mana
	_setup_click_area()
	_spawn_entity_ui()
	# Defer so CombatHud / other subscribers finish connecting in _ready first.
	call_deferred("_broadcast_stats")


func _setup_click_area() -> void:
	_click_area = Area2D.new()
	_click_area.name = "ClickArea"
	_click_area.input_pickable = true
	_click_area.monitorable = true
	_click_area.monitoring = true
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = CLICK_AREA_SIZE
	shape_node.shape = rect
	_click_area.add_child(shape_node)
	_click_area.input_event.connect(_on_click_area_input_event)
	_click_area.mouse_entered.connect(_on_click_area_mouse_entered)
	add_child(_click_area)


func _spawn_entity_ui() -> void:
	if ENTITY_UI_SCENE == null:
		push_error("CombatEntity: entity_ui.tscn failed to preload.")
		return
	_entity_ui = ENTITY_UI_SCENE.instantiate() as Control
	if _entity_ui == null:
		return
	add_child(_entity_ui)
	_entity_ui.position = ENTITY_UI_OFFSET
	if _entity_ui.has_method("setup"):
		_entity_ui.call("setup", self)


func _on_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int,
) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			EventBus.entity_clicked.emit(self)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			EventBus.entity_clicked.emit(self)
			get_viewport().set_input_as_handled()


func _on_click_area_mouse_entered() -> void:
	EventBus.target_hovered.emit(self)


## Push current HP / mana to EventBus and local listeners (spawn init / resync).
func _broadcast_stats() -> void:
	_emit_health()
	_emit_mana()


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	var was_alive: bool = current_hp > 0
	current_hp = clampi(current_hp - amount, 0, max_hp)
	_emit_health()
	if was_alive and current_hp == 0:
		EventBus.entity_died.emit(entity_id)


func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = clampi(current_hp + amount, 0, max_hp)
	_emit_health()


## Returns true and spends mana when the pool can cover `amount`.
func spend_mana(amount: int) -> bool:
	if amount < 0:
		return false
	if current_mana < amount:
		return false
	current_mana = clampi(current_mana - amount, 0, max_mana)
	_emit_mana()
	return true


## Start-of-turn mana refill (GDD: +base_mana_regen, capped at max_mana).
func regenerate_mana() -> void:
	current_mana = clampi(current_mana + base_mana_regen, 0, max_mana)
	_emit_mana()


## GDD Fatigue — empty draw-pile reshuffle burns mana to 0.
func trigger_fatigue_penalty() -> void:
	current_mana = 0
	_emit_mana()


func is_alive() -> bool:
	return current_hp > 0


func _emit_health() -> void:
	local_health_changed.emit(current_hp, max_hp)
	EventBus.health_changed.emit(entity_id, current_hp, max_hp)


func _emit_mana() -> void:
	local_mana_changed.emit(current_mana, max_mana)
	EventBus.mana_changed.emit(entity_id, current_mana, max_mana)
