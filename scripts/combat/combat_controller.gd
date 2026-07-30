class_name CombatController
extends Node

## Per-combat orchestrator. Owns combatants and reacts to CombatStateMachine phases.

var player: Combatant = Combatant.new()

var _input_enabled: bool = false


func _ready() -> void:
	player.display_name = "The Orphan"
	CombatStateMachine.phase_changed.connect(_on_phase_changed)
	player.deck.hand_changed.connect(_on_hand_changed)
	player.deck.piles_changed.connect(_on_piles_changed)
	player.mana.mana_changed.connect(_on_mana_changed)
	player.deck.card_drawn.connect(_on_card_drawn)
	player.deck.card_played.connect(_on_card_played)


func start_combat(deck_cards: Array[CardData]) -> void:
	player.reset_for_combat(deck_cards)
	EventBus.combat_started.emit()
	CombatStateMachine.start_combat()


func try_play_card(card: CardData) -> bool:
	if not _input_enabled:
		return false
	if CombatStateMachine.current_phase != CombatStateMachine.Phase.PLAYER_MAIN:
		return false
	if card.is_dormant:
		EventBus.combat_log.emit("Cannot play %s." % card.display_name)
		return false
	# Mana spend is owned by CombatStateMachine Action Resolver on the Player entity.
	# Pre-check entity mana (or ManaPool fallback) before emitting card_played.
	if not _can_afford_via_entity(card):
		EventBus.combat_log.emit("Cannot play %s." % card.display_name)
		return false
	if player.deck.hand.find(card) < 0:
		return false
	EventBus.card_played.emit(card, null)
	if not player.deck.play_card(card):
		return false
	_sync_mana_pool_from_player_entity()
	player.cards_played_this_turn += 1
	EventBus.combat_log.emit("Played %s (-%d mana)." % [card.display_name, card.mana_cost])
	return true


func _can_afford_via_entity(card: CardData) -> bool:
	var entity: Node = _get_player_entity()
	if entity != null and "current_mana" in entity:
		var current: int = int(entity.get("current_mana"))
		if card.drains_full_mana:
			return current > 0
		return card.mana_cost <= current
	return player.can_play_card(card)


func _get_player_entity() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if not players.is_empty():
		return players[0]
	return get_parent().get_node_or_null("Player")


func _sync_mana_pool_from_player_entity() -> void:
	var entity: Node = _get_player_entity()
	if entity == null or not ("current_mana" in entity):
		return
	player.mana.current = int(entity.get("current_mana"))
	if "max_mana" in entity:
		player.mana.cap = int(entity.get("max_mana"))
	player.mana.mana_changed.emit(player.mana.current, player.mana.cap)


func end_player_turn() -> void:
	if not _input_enabled:
		return
	_input_enabled = false
	CombatStateMachine.end_player_turn()


func _on_phase_changed(previous: int, current: int) -> void:
	match current:
		CombatStateMachine.Phase.SETUP:
			_handle_setup()
		CombatStateMachine.Phase.TURN_START:
			_handle_turn_start()
		CombatStateMachine.Phase.PLAYER_MAIN:
			_handle_player_main()
		CombatStateMachine.Phase.TURN_END:
			_handle_turn_end()
		CombatStateMachine.Phase.ENEMY_TURN:
			_handle_enemy_turn()


func _handle_setup() -> void:
	player.deck.draw_cards(GameConstants.HAND_START_SIZE)
	EventBus.combat_log.emit("Combat started. Drew %d cards." % GameConstants.HAND_START_SIZE)
	CombatStateMachine.begin_player_turn()


func _handle_turn_start() -> void:
	player.begin_turn()
	_sync_player_entity_mana_from_pool()
	EventBus.turn_started.emit(CombatStateMachine.turn_number, player.display_name)
	EventBus.combat_log.emit("Turn %d — mana regenerated." % CombatStateMachine.turn_number)
	CombatStateMachine.enter_player_main()


func _sync_player_entity_mana_from_pool() -> void:
	var entity: Node = _get_player_entity()
	if entity == null:
		return
	if "current_mana" in entity:
		entity.set("current_mana", player.mana.current)
	if "max_mana" in entity:
		entity.set("max_mana", player.mana.cap)
	if entity.has_method("_broadcast_stats"):
		entity.call("_broadcast_stats")
	elif entity.has_method("regenerate_mana"):
		# Fallback: at least push EventBus mana if broadcast helper missing.
		EventBus.mana_changed.emit("player", player.mana.current, player.mana.cap)


func _handle_player_main() -> void:
	_input_enabled = true
	EventBus.combat_log.emit("Select a card or end your turn.")


func _handle_turn_end() -> void:
	EventBus.turn_ended.emit(CombatStateMachine.turn_number)
	CombatStateMachine.begin_enemy_turn()


func _handle_enemy_turn() -> void:
	var enemy: Node = get_parent().get_node_or_null("Enemy")
	var player_entity: Node = get_parent().get_node_or_null("Player")
	if enemy != null and enemy.has_method("take_turn") and enemy.has_method("is_alive") and enemy.call("is_alive"):
		enemy.call("take_turn", player_entity)
	else:
		EventBus.combat_log.emit("Enemy turn (stub).")
	await get_tree().create_timer(0.6).timeout
	CombatStateMachine.begin_player_turn()


func _on_hand_changed(hand: Array[CardData]) -> void:
	EventBus.hand_updated.emit(hand)


func _on_piles_changed(draw_count: int, burn_count: int) -> void:
	EventBus.piles_updated.emit(draw_count, burn_count)


func _on_mana_changed(current: int, cap: int) -> void:
	EventBus.mana_updated.emit(current, cap)
	EventBus.mana_changed.emit("player", current, cap)


func _on_card_drawn(card: CardData) -> void:
	EventBus.card_drawn.emit(card, player.display_name)


func _on_card_played(card: CardData) -> void:
	pass
