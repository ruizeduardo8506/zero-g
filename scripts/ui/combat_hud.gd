class_name CombatHud
extends Control

signal end_turn_pressed

@onready var _turn_label: Label = %TurnLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _mana_label: Label = %ManaLabel
@onready var _pile_label: Label = %PileLabel
@onready var _log_label: Label = %LogLabel
@onready var _hand_container: HandContainer = %HandContainer
@onready var _end_turn_button: Button = %EndTurnButton


func _ready() -> void:
	_end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	EventBus.combat_log.connect(_on_combat_log)


func get_hand_container() -> HandContainer:
	return _hand_container


func set_interaction_enabled(enabled: bool) -> void:
	_end_turn_button.disabled = not enabled
	_hand_container.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func update_turn(turn_number: int, phase_name: String) -> void:
	_turn_label.text = "TURN %02d" % turn_number
	_phase_label.text = phase_name


func update_mana(current: int, cap: int) -> void:
	_mana_label.text = "MANA %d / %d" % [current, cap]


func update_piles(draw_count: int, burn_count: int) -> void:
	_pile_label.text = "DRAW %d  |  BURN %d" % [draw_count, burn_count]


func _on_combat_log(message: String) -> void:
	_log_label.text = message
