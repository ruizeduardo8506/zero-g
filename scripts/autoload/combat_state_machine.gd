extends Node

## Global combat phase controller (autoload).
## Owns turn/phase flow, Fatigue → player entity, and card Action Resolution / targeting.
## Mouse/touch: drag-drop resolves with a concrete target. Controller: cycle targets then confirm.

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

## Card awaiting a target during WAITING_FOR_TARGET.
var pending_card: Resource = null
## Controller targeting cycle.
var valid_targets: Array[Node] = []
var current_target_index: int = 0

var _applying_fatigue: bool = false
var _resolving_card: bool = false


func _ready() -> void:
	EventBus.fatigue_triggered.connect(_on_fatigue_triggered)
	EventBus.card_played.connect(_on_card_played)
	EventBus.entity_clicked.connect(_on_entity_clicked)
	EventBus.entity_died.connect(_on_entity_died)


## Call when a party CombatEntity enters combat (or leaves — pass null).
func set_active_player_entity(entity: Node2D) -> void:
	active_player_entity = entity


func is_combat_over() -> bool:
	return current_phase == Phase.VICTORY or current_phase == Phase.DEFEAT


func start_combat() -> void:
	turn_number = 0
	is_player_turn = true
	_clear_targeting_state()
	_transition_to(Phase.SETUP)
	# Opening hand + mana for the first player turn (GDD: draw 5).
	_prepare_player_turn_resources()


func end_combat(victory: bool) -> void:
	_finish_combat(victory)


func begin_player_turn() -> void:
	if is_combat_over():
		return
	is_player_turn = true
	turn_number += 1
	_clear_targeting_state()
	_transition_to(Phase.TURN_START)


## After the enemy phase — regen mana, draw 5, then start the player turn.
func end_enemy_turn() -> void:
	if is_combat_over():
		return
	_prepare_player_turn_resources()
	begin_player_turn()


func enter_player_main() -> void:
	if is_combat_over():
		return
	_transition_to(Phase.PLAYER_MAIN)


func enter_targeting() -> void:
	if is_combat_over():
		return
	_transition_to(Phase.WAITING_FOR_TARGET)


func end_player_turn() -> void:
	if is_combat_over():
		return
	DeckManager.discard_hand()
	_clear_targeting_state()
	_transition_to(Phase.TURN_END)


func begin_enemy_turn() -> void:
	if is_combat_over():
		return
	is_player_turn = false
	_clear_targeting_state()
	_transition_to(Phase.ENEMY_TURN)


## Regen mana on all party CombatEntities, then draw the standard hand size.
func _prepare_player_turn_resources() -> void:
	_regenerate_player_mana()
	DeckManager.draw_cards(GameConstants.HAND_START_SIZE)


func _regenerate_player_mana() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var players: Array[Node] = tree.get_nodes_in_group(PLAYER_GROUP)
	for node: Node in players:
		if is_instance_valid(node) and node.has_method("regenerate_mana"):
			node.call("regenerate_mana")
			if "current_mana" in node and "max_mana" in node:
				EventBus.mana_updated.emit(
					int(node.get("current_mana")),
					int(node.get("max_mana")),
				)


## Abort an in-progress target selection and return to PLAYER_MAIN.
func cancel_pending_play() -> void:
	if current_phase != Phase.WAITING_FOR_TARGET:
		return
	_cancel_pending_card()


func reset() -> void:
	turn_number = 0
	is_player_turn = true
	active_player_entity = null
	_clear_targeting_state()
	_transition_to(Phase.INACTIVE)


func _input(event: InputEvent) -> void:
	if is_combat_over():
		return
	if current_phase != Phase.WAITING_FOR_TARGET:
		return
	if pending_card == null:
		return

	if event.is_action_pressed("ui_left"):
		_cycle_target(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_cycle_target(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if valid_targets.is_empty():
			return
		var chosen: Node = valid_targets[current_target_index]
		_resolve_card_on_target(chosen)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_pending_card()
		get_viewport().set_input_as_handled()


## Card committed from hand.
func _on_card_played(card_data: Resource, target: Node) -> void:
	if is_combat_over() or _resolving_card:
		return
	if current_phase != Phase.PLAYER_MAIN:
		return
	if card_data == null:
		return

	# Controller: always enter explicit target cycling (ignore drag target).
	if InputManager.is_using_controller:
		_begin_controller_targeting(card_data)
		return

	# Mouse / touch: drag-drop provides the target and resolves immediately.
	pending_card = card_data
	if (
		target != null
		and is_instance_valid(target)
		and target.has_method("take_damage")
		and target.has_method("heal")
	):
		_transition_to(Phase.WAITING_FOR_TARGET)
		_resolve_card_on_target(target)
		return

	# Click-to-play with no drag target: auto-cast when only one valid target
	# (prototype often has a single enemy), otherwise wait for a click.
	_populate_valid_targets(card_data)
	_transition_to(Phase.WAITING_FOR_TARGET)
	if valid_targets.size() == 1:
		_resolve_card_on_target(valid_targets[0])
		return

	EventBus.targeting_started.emit(card_data)
	if valid_targets.is_empty():
		EventBus.combat_log.emit("No valid targets for %s." % _resolve_card_name(card_data))
		# Defer restore until card_played listeners finish consuming.
		var cancelled: Resource = pending_card
		_clear_targeting_state()
		_transition_to(Phase.PLAYER_MAIN)
		call_deferred("_emit_play_cancelled", cancelled)
		return
	EventBus.combat_log.emit("Select a target for %s." % _resolve_card_name(card_data))


func _begin_controller_targeting(card_data: Resource) -> void:
	pending_card = card_data
	_populate_valid_targets(card_data)
	current_target_index = 0
	_transition_to(Phase.WAITING_FOR_TARGET)
	EventBus.targeting_started.emit(card_data)
	if valid_targets.is_empty():
		EventBus.combat_log.emit("No valid targets for %s." % _resolve_card_name(card_data))
		_cancel_pending_card()
		return
	_emit_current_target_hovered()
	EventBus.combat_log.emit(
		"Targeting %s — D-pad to cycle, A/Confirm to cast, B/Cancel to abort."
		% _resolve_card_name(card_data)
	)


func _populate_valid_targets(card_data: Resource) -> void:
	valid_targets.clear()
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var group_name: String = ENEMIES_GROUP
	if _is_healing_or_defensive_card(card_data):
		group_name = PLAYER_GROUP
	var nodes: Array[Node] = tree.get_nodes_in_group(group_name)
	for node: Node in nodes:
		if not is_instance_valid(node):
			continue
		if node.has_method("is_alive") and not bool(node.call("is_alive")):
			continue
		valid_targets.append(node)


func _is_healing_or_defensive_card(card_data: Resource) -> bool:
	return _resolve_card_heal(card_data) > 0


func _cycle_target(direction: int) -> void:
	if valid_targets.is_empty():
		return
	var size: int = valid_targets.size()
	current_target_index = (current_target_index + direction) % size
	if current_target_index < 0:
		current_target_index += size
	_emit_current_target_hovered()


func _emit_current_target_hovered() -> void:
	if valid_targets.is_empty():
		return
	if current_target_index < 0 or current_target_index >= valid_targets.size():
		current_target_index = 0
	var target: Node = valid_targets[current_target_index]
	if is_instance_valid(target):
		EventBus.target_hovered.emit(target)


func _cancel_pending_card() -> void:
	var cancelled: Resource = pending_card
	_clear_targeting_state()
	_transition_to(Phase.PLAYER_MAIN)
	if cancelled != null:
		EventBus.card_play_cancelled.emit(cancelled)
		EventBus.combat_log.emit("Cancelled %s." % _resolve_card_name(cancelled))


func _emit_play_cancelled(card: Resource) -> void:
	if card == null:
		return
	EventBus.card_play_cancelled.emit(card)


## Manual mouse/touch click targeting while WAITING_FOR_TARGET.
func _on_entity_clicked(target: CombatEntity) -> void:
	if is_combat_over():
		return
	if current_phase != Phase.WAITING_FOR_TARGET:
		return
	if pending_card == null or target == null:
		return
	# Controller mode uses D-pad + ui_accept instead of free clicks.
	if InputManager.is_using_controller:
		return
	_resolve_card_on_target(target)


func _on_entity_died(entity_id: String) -> void:
	if is_combat_over():
		return
	if entity_id == "player":
		print("Game Over!")
		_finish_combat(false)
	elif entity_id == "enemy":
		print("You Win!")
		_finish_combat(true)


func _finish_combat(victory: bool) -> void:
	_clear_targeting_state()
	_resolving_card = false
	_transition_to(Phase.VICTORY if victory else Phase.DEFEAT)
	EventBus.combat_log.emit("You Win!" if victory else "Game Over!")
	EventBus.combat_ended.emit(victory)


func _resolve_card_on_target(target: Node) -> void:
	if _resolving_card:
		return
	if pending_card == null or target == null:
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
		_clear_targeting_state()
		_transition_to(Phase.PLAYER_MAIN)
		# Defer so card_played listeners finish consuming the card first.
		call_deferred("_emit_play_cancelled", card)
		return

	if "current_mana" in player and "max_mana" in player:
		EventBus.mana_updated.emit(int(player.get("current_mana")), int(player.get("max_mana")))

	var target_id: String = str(target.get("entity_id")) if "entity_id" in target else target.name
	var heal: int = _resolve_card_heal(card)
	if heal > 0 and target.has_method("heal"):
		target.call("heal", heal)
		EventBus.combat_log.emit("Healed %s for %d HP." % [target_id, heal])

	var damage: int = _resolve_card_damage(card)
	if damage > 0 and target.has_method("take_damage"):
		target.call("take_damage", damage)
		EventBus.combat_log.emit("Dealt %d damage to %s." % [damage, target_id])

	_clear_targeting_state()
	_resolving_card = false
	if not is_combat_over():
		_transition_to(Phase.PLAYER_MAIN)


func _clear_targeting_state() -> void:
	pending_card = null
	valid_targets.clear()
	current_target_index = 0


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
