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
	if not player.can_play_card(card):
		EventBus.combat_log.emit("Cannot play %s." % card.display_name)
		return false
	if not player.play_card(card):
		return false
	EventBus.card_played.emit(card, null)
	EventBus.combat_log.emit("Played %s (-%d mana)." % [card.display_name, card.mana_cost])
	return true


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
	EventBus.turn_started.emit(CombatStateMachine.turn_number, player.display_name)
	EventBus.combat_log.emit("Turn %d — mana regenerated." % CombatStateMachine.turn_number)
	CombatStateMachine.enter_player_main()


func _handle_player_main() -> void:
	_input_enabled = true
	EventBus.combat_log.emit("Select a card or end your turn.")


func _handle_turn_end() -> void:
	EventBus.turn_ended.emit(CombatStateMachine.turn_number)
	CombatStateMachine.begin_enemy_turn()


func _handle_enemy_turn() -> void:
	# Placeholder: enemy AI will run here.
	EventBus.combat_log.emit("Enemy turn (stub).")
	await get_tree().create_timer(0.6).timeout
	CombatStateMachine.begin_player_turn()


func _on_hand_changed(hand: Array[CardData]) -> void:
	EventBus.hand_updated.emit(hand)


func _on_piles_changed(draw_count: int, burn_count: int) -> void:
	EventBus.piles_updated.emit(draw_count, burn_count)


func _on_mana_changed(current: int, cap: int) -> void:
	EventBus.mana_updated.emit(current, cap)


func _on_card_drawn(card: CardData) -> void:
	EventBus.card_drawn.emit(card, player.display_name)


func _on_card_played(card: CardData) -> void:
	pass
