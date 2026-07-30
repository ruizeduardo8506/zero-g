extends Node

## Global combat phase controller (autoload).
## Owns turn/phase flow, Fatigue → player entity, and card Action Resolution / targeting.

const CombatEntityScript = preload("res://scripts/combat/combat_entity.gd")

enum Phase {
	INACTIVE,
	SETUP,
	TURN_START,
	PLAYER_MAIN,
	PLAYER_TARGETING,
	WAITING_FOR_TARGET,
	ENEMY_TURN,
	TURN_END,
	RESOLUTION,
	VICTORY,
	DEFEAT,
}

## Director alias: PLAYER_MAIN is the actionable player turn.
const PLAYER_GROUP: String = "player"
const ENEMIES_GROUP: String = "enemies"
const PLAYER_ENTITY_GROUP: String = "player_combat_entity"

signal phase_changed(previous: Phase, current: Phase)

var current_phase: Phase = Phase.INACTIVE
var turn_number: int = 0
var is_player_turn: bool = true

## Phase-2 player CombatEntity registered by the combat scene / controller.
var active_player_entity: Node2D = null

## Card awaiting a clicked target during WAITING_FOR_TARGET.
var pending_card: Resource = null

var _applying_fatigue: bool = false
var _resolving_card: bool = false


func _ready() -> void:
	EventBus.fatigue_triggered.connect(_on_fatigue_triggered)
	EventBus.card_played.connect(_on_card_played)
	EventBus.entity_clicked.connect(_on_entity_clicked)


## Call when a party CombatEntity enters combat (or leaves — pass null).
func set_active_player_entity(entity: Node2D) -> void:
	active_player_entity = entity


func start_combat() -> void:
	turn_number = 0
	is_player_turn = true
	pending_card = null
	_transition_to(Phase.SETUP)


func end_combat(victory: bool) -> void:
	pending_card = null
	_transition_to(Phase.VICTORY if victory else Phase.DEFEAT)


func begin_player_turn() -> void:
	is_player_turn = true
	turn_number += 1
	pending_card = null
	_transition_to(Phase.TURN_START)


func enter_player_main() -> void:
	_transition_to(Phase.PLAYER_MAIN)


func enter_targeting() -> void:
	_transition_to(Phase.WAITING_FOR_TARGET)


func end_player_turn() -> void:
	pending_card = null
	_transition_to(Phase.TURN_END)


func begin_enemy_turn() -> void:
	is_player_turn = false
	pending_card = null
	_transition_to(Phase.ENEMY_TURN)


func reset() -> void:
	turn_number = 0
	is_player_turn = true
	active_player_entity = null
	pending_card = null
	_transition_to(Phase.INACTIVE)


## Card committed from hand — enter targeting instead of auto-resolving.
func _on_card_played(card_data: Resource, _target: Node) -> void:
	if _resolving_card:
		return
	if current_phase != Phase.PLAYER_MAIN:
		return
	if card_data == null:
		return

	pending_card = card_data
	_transition_to(Phase.WAITING_FOR_TARGET)
	EventBus.targeting_started.emit(card_data)
	var card_name: String = _resolve_card_name(card_data)
	EventBus.combat_log.emit("Select a target for %s." % card_name)


## Manual targeting — resolve pending card against the clicked combatant.
func _on_entity_clicked(target: CombatEntity) -> void:
	if current_phase != Phase.WAITING_FOR_TARGET:
		return
	if pending_card == null or target == null:
		return
	if _resolving_card:
		return

	_resolving_card = true
	var card: Resource = pending_card
	var player: Node = _find_player_entity()
	if player == null or not player.has_method("spend_mana"):
		push_warning("CombatStateMachine: no player entity in group '%s'" % PLAYER_GROUP)
		_resolving_card = false
		return

	var mana_cost: int = _resolve_mana_cost(card, player)
	if not player.call("spend_mana", mana_cost):
		print("Not enough mana!")
		EventBus.combat_log.emit("Not enough mana!")
		_resolving_card = false
		pending_card = null
		_transition_to(Phase.PLAYER_MAIN)
		return

	# Keep ManaPool / HUD in sync with entity mana after spend.
	if "current_mana" in player and "max_mana" in player:
		EventBus.mana_updated.emit(int(player.get("current_mana")), int(player.get("max_mana")))

	var heal: int = _resolve_card_heal(card)
	if heal > 0 and target.has_method("heal"):
		target.heal(heal)
		EventBus.combat_log.emit("Healed %s for %d HP." % [target.entity_id, heal])

	var damage: int = _resolve_card_damage(card)
	if damage > 0 and target.has_method("take_damage"):
		target.take_damage(damage)
		EventBus.combat_log.emit("Dealt %d damage to %s." % [damage, target.entity_id])

	pending_card = null
	_resolving_card = false
	# Return to player turn (PLAYER_MAIN).
	_transition_to(Phase.PLAYER_MAIN)


func _resolve_mana_cost(card_data: Resource, player: Node) -> int:
	if "drains_full_mana" in card_data and bool(card_data.get("drains_full_mana")):
		return int(player.get("current_mana"))
	if "mana_cost" in card_data:
		return int(card_data.get("mana_cost"))
	return 0


func _resolve_card_damage(card_data: Resource) -> int:
	if "base_damage" in card_data:
		return int(card_data.get("base_damage"))
	if "base_power" in card_data and _resolve_card_heal(card_data) <= 0:
		return int(card_data.get("base_power"))
	return 0


func _resolve_card_heal(card_data: Resource) -> int:
	if "base_heal" in card_data:
		return int(card_data.get("base_heal"))
	return 0


func _resolve_card_name(card_data: Resource) -> String:
	if "display_name" in card_data:
		return str(card_data.get("display_name"))
	if "card_name" in card_data:
		return str(card_data.get("card_name"))
	return "card"


func _find_player_entity() -> Node:
	if active_player_entity != null and is_instance_valid(active_player_entity):
		return active_player_entity
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var players: Array[Node] = tree.get_nodes_in_group(PLAYER_GROUP)
	if not players.is_empty():
		return players[0]
	var legacy: Array[Node] = tree.get_nodes_in_group(PLAYER_ENTITY_GROUP)
	if not legacy.is_empty():
		return legacy[0]
	return null


func _on_fatigue_triggered() -> void:
	if _applying_fatigue:
		return
	_applying_fatigue = true
	var player: Node = _resolve_active_player()
	if player != null and player.has_method("trigger_fatigue_penalty"):
		player.call("trigger_fatigue_penalty")
		EventBus.combat_log.emit("Fatigue! Mana burned to 0 — rely on physical procs.")
	else:
		push_warning("CombatStateMachine: fatigue_triggered but no active player CombatEntity")
	_applying_fatigue = false


func _resolve_active_player() -> Node2D:
	var found: Node = _find_player_entity()
	if found is Node2D:
		return found as Node2D
	return null


func _transition_to(next: Phase) -> void:
	var previous: Phase = current_phase
	current_phase = next
	phase_changed.emit(previous, next)
	EventBus.phase_changed.emit(previous, next)
