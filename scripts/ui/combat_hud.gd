class_name CombatHud
extends Control

## Main combat canvas UI. Subscribes to EventBus for player HP / mana bars
## and keeps the Phase-1 scaffold (hand, turn, piles) for CombatScene.

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

@onready var _turn_label: Label = %TurnLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _mana_status_label: Label = %ManaLabel
@onready var _pile_label: Label = %PileLabel
@onready var _log_label: Label = %LogLabel
@onready var _hand_container: HandContainer = %HandContainer
@onready var _end_turn_button: Button = %EndTurnButton

var _mana_burn_tween: Tween


func _ready() -> void:
	_end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	EventBus.combat_log.connect(_on_combat_log)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.mana_changed.connect(_on_mana_changed)


func get_hand_container() -> HandContainer:
	return _hand_container


func set_interaction_enabled(enabled: bool) -> void:
	_end_turn_button.disabled = not enabled
	_hand_container.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func update_turn(turn_number: int, phase_name: String) -> void:
	_turn_label.text = "TURN %02d" % turn_number
	_phase_label.text = phase_name


## Legacy path from CombatScene / ManaPool via EventBus.mana_updated.
func update_mana(current: int, cap: int) -> void:
	_mana_status_label.text = "MANA %d / %d" % [current, cap]


func update_piles(draw_count: int, burn_count: int) -> void:
	_pile_label.text = "DRAW %d  |  BURN %d" % [draw_count, burn_count]


func _on_combat_log(message: String) -> void:
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
	# Keep top-bar status in sync when EventBus path is used (CombatEntity).
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
