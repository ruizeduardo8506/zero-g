class_name CombatHud
extends Control

## Dynamic Target Frame — shows HP/MP for the combatant the player is inspecting.
## Per-entity floating bars live on EntityUI (spawned by CombatEntity).

const HEALTH_FILL := Color(0.2, 0.8, 0.2, 1.0)
const MANA_FILL := Color(0.2, 0.4, 0.9, 1.0)
const ENEMY_HEALTH_FILL := Color(0.8, 0.2, 0.2, 1.0)

## Mana Burn flash (Fatigue) — brief red → gray → restore.
const MANA_BURN_RED := Color(0.9, 0.2, 0.25, 1.0)
const MANA_BURN_GRAY := Color(0.45, 0.48, 0.52, 1.0)
const MANA_BURN_FLASH_SEC: float = 0.18
const MANA_BURN_RESTORE_SEC: float = 0.35

signal end_turn_pressed

@export var health_bar: ProgressBar
@export var mana_bar: ProgressBar
@export var health_label: Label
@export var mana_label: Label
@export var target_name_label: Label

var _turn_label: Label
var _phase_label: Label
var _mana_status_label: Label
var _pile_label: Label
var _log_label: Label
var _hand_container: HandContainer
var _end_turn_button: Button

var _mana_burn_tween: Tween
var _focused_entity: CombatEntity


func _ready() -> void:
	_turn_label = get_node_or_null("%TurnLabel") as Label
	_phase_label = get_node_or_null("%PhaseLabel") as Label
	_mana_status_label = get_node_or_null("%ManaLabel") as Label
	_pile_label = get_node_or_null("%PileLabel") as Label
	_log_label = get_node_or_null("%LogLabel") as Label
	_hand_container = get_node_or_null("%HandContainer") as HandContainer
	_end_turn_button = get_node_or_null("%EndTurnButton") as Button

	_apply_bar_colors()

	if _end_turn_button != null:
		_end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	EventBus.combat_log.connect(_on_combat_log)
	EventBus.target_hovered.connect(_on_target_hovered)


func get_hand_container() -> HandContainer:
	return _hand_container


func set_interaction_enabled(enabled: bool) -> void:
	if _end_turn_button != null:
		_end_turn_button.disabled = not enabled
	if _hand_container != null:
		_hand_container.mouse_filter = (
			Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		)


func update_turn(turn_number: int, phase_name: String) -> void:
	if _turn_label != null:
		_turn_label.text = "TURN %02d" % turn_number
	if _phase_label != null:
		_phase_label.text = phase_name


## Legacy path from CombatScene / ManaPool — refresh frame if focused on player.
func update_mana(current: int, cap: int) -> void:
	if _mana_status_label != null:
		_mana_status_label.text = "MANA %d / %d" % [current, cap]
	if _focused_entity == null or _focused_entity.entity_id != "player":
		return
	_apply_mana_to_frame(current, cap)
	if current == 0:
		_play_mana_burn_feedback()


func update_piles(draw_count: int, burn_count: int) -> void:
	if _pile_label != null:
		_pile_label.text = "DRAW %d  |  BURN %d" % [draw_count, burn_count]


func _on_combat_log(message: String) -> void:
	if _log_label != null:
		_log_label.text = message


func _on_target_hovered(entity: CombatEntity) -> void:
	if entity == null:
		return
	_unbind_focused_entity()
	_focused_entity = entity
	if target_name_label != null:
		target_name_label.text = entity.entity_id.capitalize()
	_apply_bar_colors_for_entity(entity)
	entity.local_health_changed.connect(_on_focused_health_changed)
	entity.local_mana_changed.connect(_on_focused_mana_changed)
	_on_focused_health_changed(entity.current_hp, entity.max_hp)
	_on_focused_mana_changed(entity.current_mana, entity.max_mana)


func _unbind_focused_entity() -> void:
	if _focused_entity == null:
		return
	if _focused_entity.local_health_changed.is_connected(_on_focused_health_changed):
		_focused_entity.local_health_changed.disconnect(_on_focused_health_changed)
	if _focused_entity.local_mana_changed.is_connected(_on_focused_mana_changed):
		_focused_entity.local_mana_changed.disconnect(_on_focused_mana_changed)
	_focused_entity = null


func _on_focused_health_changed(new_hp: int, max_hp: int) -> void:
	if health_bar != null:
		health_bar.max_value = float(max_hp)
		health_bar.value = float(new_hp)
	if health_label != null:
		health_label.text = "HP: %d/%d" % [new_hp, max_hp]


func _on_focused_mana_changed(new_mana: int, max_mana: int) -> void:
	_apply_mana_to_frame(new_mana, max_mana)
	if new_mana == 0:
		_play_mana_burn_feedback()


func _apply_mana_to_frame(new_mana: int, max_mana: int) -> void:
	if mana_bar != null:
		mana_bar.max_value = float(max_mana)
		mana_bar.value = float(new_mana)
		mana_bar.visible = max_mana > 0
	if mana_label != null:
		mana_label.text = "MP: %d/%d" % [new_mana, max_mana]
		mana_label.visible = max_mana > 0


func _apply_bar_colors() -> void:
	_set_bar_fill(health_bar, HEALTH_FILL)
	_set_bar_fill(mana_bar, MANA_FILL)


func _apply_bar_colors_for_entity(entity: CombatEntity) -> void:
	var hp_color: Color = HEALTH_FILL
	if entity != null and not entity.is_in_group("player") and entity.entity_id != "player":
		hp_color = ENEMY_HEALTH_FILL
	_set_bar_fill(health_bar, hp_color)
	_set_bar_fill(mana_bar, MANA_FILL)


func _set_bar_fill(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(3)
	style.content_margin_left = 1.0
	style.content_margin_top = 1.0
	style.content_margin_right = 1.0
	style.content_margin_bottom = 1.0
	bar.add_theme_stylebox_override("fill", style)
	bar.show_percentage = false


func _play_mana_burn_feedback() -> void:
	if mana_bar == null or not mana_bar.visible:
		return
	if _mana_burn_tween != null and _mana_burn_tween.is_valid():
		_mana_burn_tween.kill()
	mana_bar.modulate = MANA_BURN_RED
	_mana_burn_tween = create_tween()
	_mana_burn_tween.tween_property(mana_bar, "modulate", MANA_BURN_GRAY, MANA_BURN_FLASH_SEC)
	_mana_burn_tween.tween_property(mana_bar, "modulate", Color.WHITE, MANA_BURN_RESTORE_SEC)


func _exit_tree() -> void:
	_unbind_focused_entity()
