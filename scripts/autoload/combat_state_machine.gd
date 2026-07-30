extends Node

## Global combat phase controller (autoload).
## Owns turn/phase flow, Fatigue → player entity, and card Action Resolution.

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

## Director alias: player may act during PLAYER_MAIN (player turn).
const PLAYER_GROUP: String = "player"
const ENEMIES_GROUP: String = "enemies"
const PLAYER_ENTITY_GROUP: String = "player_combat_entity"

signal phase_changed(previous: Phase, current: Phase)

var current_phase: Phase = Phase.INACTIVE
var turn_number: int = 0
var is_player_turn: bool = true

## Phase-2 player CombatEntity registered by the combat scene / controller.
var active_player_entity: Node2D = null

var _applying_fatigue: bool = false
var _resolving_card: bool = false


func _ready() -> void:
	EventBus.fatigue_triggered.connect(_on_fatigue_triggered)
	EventBus.card_played.connect(_on_card_played)


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


## Action Resolver — spend player mana and apply card damage / healing.
func _on_card_played(card_data: Resource, target: Node) -> void:
	if _resolving_card:
		return
	# PLAYER_MAIN is the actionable player-turn phase (Director: PLAYER_TURN).
	if current_phase != Phase.PLAYER_MAIN:
		return
	if card_data == null:
		return

	_resolving_card = true
	var player: Node = _find_player_entity()
	if player == null or not player.has_method("spend_mana"):
		push_warning("CombatStateMachine: no player entity in group '%s'" % PLAYER_GROUP)
		_resolving_card = false
		return

	var mana_cost: int = _resolve_mana_cost(card_data, player)
	if not player.call("spend_mana", mana_cost):
		print("Not enough mana!")
		EventBus.combat_log.emit("Not enough mana!")
		_resolving_card = false
		return

	var heal: int = _resolve_card_heal(card_data)
	if heal > 0 and player.has_method("heal"):
		player.call("heal", heal)
		EventBus.combat_log.emit("Healed %d HP." % heal)

	var damage: int = _resolve_card_damage(card_data)
	if damage > 0:
		var resolved_target: Node = target
		if resolved_target == null or not is_instance_valid(resolved_target):
			resolved_target = _find_default_enemy()
		if resolved_target == null or not resolved_target.has_method("take_damage"):
			push_warning("CombatStateMachine: no valid enemy target for card")
			_resolving_card = false
			return
		resolved_target.call("take_damage", damage)
		var target_id: String = (
			str(resolved_target.get("entity_id"))
			if "entity_id" in resolved_target
			else resolved_target.name
		)
		EventBus.combat_log.emit("Dealt %d damage to %s." % [damage, target_id])

	_resolving_card = false


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


func _find_player_entity() -> Node:
	if active_player_entity != null and is_instance_valid(active_player_entity):
		return active_player_entity
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var players: Array[Node] = tree.get_nodes_in_group(PLAYER_GROUP)
	if not players.is_empty():
		return players[0]
	# Legacy fatigue group fallback.
	var legacy: Array[Node] = tree.get_nodes_in_group(PLAYER_ENTITY_GROUP)
	if not legacy.is_empty():
		return legacy[0]
	return null


func _find_default_enemy() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var enemies: Array[Node] = tree.get_nodes_in_group(ENEMIES_GROUP)
	for enemy: Node in enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_alive") and enemy.call("is_alive"):
			return enemy
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			return enemy
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
