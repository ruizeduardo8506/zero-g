class_name CombatHud
extends Control

## Main combat canvas UI. Subscribes to EventBus for player HP / mana bars.
## Phase-1 scaffold nodes (turn/hand/end-turn) are optional — resolve with
## get_node_or_null so bar-only HUD layouts do not crash on _ready.

const PLAYER_ENTITY_ID: String = "player"

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

var _turn_label: Label
var _phase_label: Label
var _mana_status_label: Label
var _pile_label: Label
var _log_label: Label
var _hand_container: HandContainer
var _end_turn_button: Button

var _mana_burn_tween: Tween


func _ready() -> void:
	_turn_label = get_node_or_null("%TurnLabel") as Label
	_phase_label = get_node_or_null("%PhaseLabel") as Label
	_mana_status_label = get_node_or_null("%ManaLabel") as Label
	_pile_label = get_node_or_null("%PileLabel") as Label
	_log_label = get_node_or_null("%LogLabel") as Label
	_hand_container = get_node_or_null("%HandContainer") as HandContainer
	_end_turn_button = get_node_or_null("%EndTurnButton") as Button

	if _end_turn_button != null:
		_end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	EventBus.combat_log.connect(_on_combat_log)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.mana_changed.connect(_on_mana_changed)


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


## Legacy path from CombatScene / ManaPool via EventBus.mana_updated.
func update_mana(current: int, cap: int) -> void:
	if _mana_status_label != null:
		_mana_status_label.text = "MANA %d / %d" % [current, cap]
	if mana_bar != null:
		mana_bar.max_value = float(cap)
		mana_bar.value = float(current)
	if mana_label != null:
		mana_label.text = "MP: %d/%d" % [current, cap]
	if current == 0:
		_play_mana_burn_feedback()


func update_piles(draw_count: int, burn_count: int) -> void:
	if _pile_label != null:
		_pile_label.text = "DRAW %d  |  BURN %d" % [draw_count, burn_count]


func _on_combat_log(message: String) -> void:
	if _log_label != null:
		_log_label.text = message


func _on_health_changed(entity_id: String, new_hp: int, max_hp: int) -> void:
	if entity_id != PLAYER_ENTITY_ID:
		return
	if health_bar != null:
		health_bar.max_value = float(max_hp)
		health_bar.value = float(new_hp)
	if health_label != null:
		health_label.text = "HP: %d/%d" % [new_hp, max_hp]


func _on_mana_changed(entity_id: String, new_mana: int, max_mana: int) -> void:
	if entity_id != PLAYER_ENTITY_ID:
		return
	if mana_bar != null:
		mana_bar.max_value = float(max_mana)
		mana_bar.value = float(new_mana)
	if mana_label != null:
		mana_label.text = "MP: %d/%d" % [new_mana, max_mana]
	if _mana_status_label != null:
		_mana_status_label.text = "MANA %d / %d" % [new_mana, max_mana]
	if new_mana == 0:
		_play_mana_burn_feedback()


func _play_mana_burn_feedback() -> void:
	if mana_bar == null:
		return
	if _mana_burn_tween != null and _mana_burn_tween.is_valid():
		_mana_burn_tween.kill()
	mana_bar.modulate = MANA_BURN_RED
	_mana_burn_tween = create_tween()
	_mana_burn_tween.tween_property(mana_bar, "modulate", MANA_BURN_GRAY, MANA_BURN_FLASH_SEC)
	_mana_burn_tween.tween_property(mana_bar, "modulate", Color.WHITE, MANA_BURN_RESTORE_SEC)
