extends Node

## Global combat phase controller (autoload).
## Owns turn/phase flow and bridges DeckManager Fatigue → active player CombatEntity.

const CombatEntityScript = preload("res://scripts/combat/combat_entity.gd")

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

const PLAYER_ENTITY_GROUP: String = "player_combat_entity"

signal phase_changed(previous: Phase, current: Phase)

var current_phase: Phase = Phase.INACTIVE
var turn_number: int = 0
var is_player_turn: bool = true

## Phase-2 player CombatEntity registered by the combat scene / controller.
var active_player_entity: Node2D = null

var _applying_fatigue: bool = false


func _ready() -> void:
	EventBus.fatigue_triggered.connect(_on_fatigue_triggered)


## Call when a party CombatEntity enters combat (or leaves — pass null).
func set_active_player_entity(entity: Node2D) -> void:
	active_player_entity = entity


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
	active_player_entity = null
	_transition_to(Phase.INACTIVE)


func _on_fatigue_triggered() -> void:
	if _applying_fatigue:
		return
	_applying_fatigue = true
	var player: Node2D = _resolve_active_player()
	if player != null and player.has_method("trigger_fatigue_penalty"):
		player.call("trigger_fatigue_penalty")
		EventBus.combat_log.emit("Fatigue! Mana burned to 0 — rely on physical procs.")
	else:
		push_warning("CombatStateMachine: fatigue_triggered but no active player CombatEntity")
	_applying_fatigue = false


func _resolve_active_player() -> Node2D:
	if active_player_entity != null and is_instance_valid(active_player_entity):
		return active_player_entity
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var nodes: Array[Node] = tree.get_nodes_in_group(PLAYER_ENTITY_GROUP)
	for node: Node in nodes:
		if is_instance_valid(node) and node is Node2D and node.has_method("trigger_fatigue_penalty"):
			return node as Node2D
	return null


func _transition_to(next: Phase) -> void:
	var previous: Phase = current_phase
	current_phase = next
	phase_changed.emit(previous, next)
	EventBus.phase_changed.emit(previous, next)
