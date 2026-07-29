extends Node

enum Phase {
	INACTIVE,
	SETUP,
	TURN_START,
	PLAYER_MAIN,
	PLAYER_TARGETING,
	ENEMY_TURN,
	TURN_END,
	RESOLUTION,
	VICTORY,
	DEFEAT,
}

signal phase_changed(previous: Phase, current: Phase)

var current_phase: Phase = Phase.INACTIVE
var turn_number: int = 0
var is_player_turn: bool = true


func start_combat() -> void:
	turn_number = 0
	is_player_turn = true
	_transition_to(Phase.SETUP)


func end_combat(victory: bool) -> void:
	_transition_to(Phase.VICTORY if victory else Phase.DEFEAT)


func begin_player_turn() -> void:
	is_player_turn = true
	turn_number += 1
	_transition_to(Phase.TURN_START)


func enter_player_main() -> void:
	_transition_to(Phase.PLAYER_MAIN)


func enter_targeting() -> void:
	_transition_to(Phase.PLAYER_TARGETING)


func end_player_turn() -> void:
	_transition_to(Phase.TURN_END)


func begin_enemy_turn() -> void:
	is_player_turn = false
	_transition_to(Phase.ENEMY_TURN)


func reset() -> void:
	turn_number = 0
	is_player_turn = true
	_transition_to(Phase.INACTIVE)


func _transition_to(next: Phase) -> void:
	var previous: Phase = current_phase
	current_phase = next
	phase_changed.emit(previous, next)
	EventBus.phase_changed.emit(previous, next)
