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
	EventBus.card_played.connect(_on_event_bus_card_played)
	EventBus.card_play_cancelled.connect(_on_card_play_cancelled)


func start_combat(deck_cards: Array[CardData]) -> void:
	player.reset_for_combat(deck_cards)
	var resources: Array[Resource] = []
	for card: CardData in deck_cards:
		resources.append(card)
	DeckManager.initialize_combat_deck(resources)
	EventBus.combat_started.emit()
	CombatStateMachine.start_combat()


func try_play_card(card: CardData) -> bool:
	if CombatStateMachine.is_combat_over():
		return false
	# Switching cards mid-target cancels the pending play and restores it.
	if CombatStateMachine.current_phase == CombatStateMachine.Phase.WAITING_FOR_TARGET:
		CombatStateMachine.cancel_pending_play()
	if not _input_enabled:
		return false
	if CombatStateMachine.current_phase != CombatStateMachine.Phase.PLAYER_MAIN:
		EventBus.combat_log.emit("Cannot play cards right now.")
		return false
	if card.is_dormant:
		EventBus.combat_log.emit("Cannot play %s." % card.display_name)
		return false
	if not _can_afford_via_entity(card):
		EventBus.combat_log.emit("Not enough mana for %s." % card.display_name)
		return false
	if DeckManager.hand.find(card) < 0:
		return false
	EventBus.card_played.emit(card, null)
	return true


func _on_event_bus_card_played(card: Resource, _target: Node) -> void:
	if not DeckManager.consume_card(card):
		return
	player.cards_played_this_turn += 1


func _on_card_play_cancelled(card: Resource) -> void:
	if not DeckManager.return_card_to_hand(card):
		return
	player.cards_played_this_turn = maxi(0, player.cards_played_this_turn - 1)
	_sync_mana_pool_from_player_entity()
	EventBus.card_drawn.emit(card, player.display_name)


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
		CombatStateMachine.Phase.VICTORY, CombatStateMachine.Phase.DEFEAT:
			_handle_combat_over()


func _handle_setup() -> void:
	EventBus.combat_log.emit("Combat started.")
	CombatStateMachine.begin_player_turn()


func _handle_turn_start() -> void:
	if CombatStateMachine.is_combat_over():
		return
	player.cards_played_this_turn = 0
	_sync_mana_pool_from_player_entity()
	EventBus.turn_started.emit(CombatStateMachine.turn_number, player.display_name)
	EventBus.combat_log.emit("Turn %d — mana regenerated, hand drawn." % CombatStateMachine.turn_number)
	CombatStateMachine.enter_player_main()


func _sync_player_entity_mana_from_pool() -> void:
	# Mana regen is owned by CombatStateMachine → CombatEntity.regenerate_mana().
	_sync_mana_pool_from_player_entity()


func _handle_player_main() -> void:
	if CombatStateMachine.is_combat_over():
		_input_enabled = false
		return
	_input_enabled = true
	_sync_mana_pool_from_player_entity()
	EventBus.combat_log.emit("Select a card or end your turn.")


func _handle_turn_end() -> void:
	if CombatStateMachine.is_combat_over():
		return
	EventBus.turn_ended.emit(CombatStateMachine.turn_number)
	CombatStateMachine.begin_enemy_turn()


func _handle_enemy_turn() -> void:
	if CombatStateMachine.is_combat_over():
		return
	var enemy: Node = get_parent().get_node_or_null("Enemy")
	if (
		enemy != null
		and enemy.has_method("take_turn")
		and enemy.has_method("is_alive")
		and enemy.call("is_alive")
	):
		# EnemyAI.take_turn awaits think/lunge and calls end_enemy_turn itself.
		await enemy.take_turn()
	else:
		EventBus.combat_log.emit("Enemy turn (stub).")
		await get_tree().create_timer(0.6).timeout
		if not CombatStateMachine.is_combat_over():
			CombatStateMachine.end_enemy_turn()


func _handle_combat_over() -> void:
	_input_enabled = false


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
