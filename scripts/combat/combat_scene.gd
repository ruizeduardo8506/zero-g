extends Control

@onready var _controller: CombatController = %CombatController
@onready var _hud: CombatHud = %CombatHud
@onready var _hand_ui: HandUI = %HandManager
@onready var _player_entity: Node2D = %Player
@onready var _enemy_entity: Node2D = %Enemy


func _ready() -> void:
	_wire_signals()
	if _player_entity != null:
		CombatStateMachine.set_active_player_entity(_player_entity)
	_controller.start_combat(StarterDeck.create_orphan_deck())
	# Focus target frame on the player once EntityUI / HUD have finished _ready.
	call_deferred("_focus_default_target")


func _focus_default_target() -> void:
	if _player_entity != null:
		EventBus.target_hovered.emit(_player_entity)


func _wire_signals() -> void:
	CombatStateMachine.phase_changed.connect(_on_phase_changed)
	EventBus.hand_updated.connect(_on_hand_updated)
	EventBus.mana_updated.connect(_on_mana_updated)
	EventBus.piles_updated.connect(_on_piles_updated)
	_hud.end_turn_pressed.connect(_controller.end_player_turn)
	if _hand_ui != null:
		_hand_ui.card_play_requested.connect(_on_card_play_requested)
	var hand: HandContainer = _hud.get_hand_container()
	if hand != null:
		hand.card_selected.connect(_on_card_selected)


func _on_phase_changed(_previous: int, _current: int) -> void:
	# Nested transitions (SETUP → TURN_START → PLAYER_MAIN) emit intermediate
	# phase_changed callbacks after the final phase is already set. Always sync
	# UI from the live phase so End Turn is not left disabled.
	var live_phase: int = CombatStateMachine.current_phase
	var phase_name: String = CombatStateMachine.Phase.keys()[live_phase]
	_hud.update_turn(CombatStateMachine.turn_number, phase_name)
	var is_player_main: bool = live_phase == CombatStateMachine.Phase.PLAYER_MAIN
	_hud.set_interaction_enabled(is_player_main)


func _on_hand_updated(hand: Array[CardData]) -> void:
	var hand_container: HandContainer = _hud.get_hand_container()
	if hand_container == null:
		return
	hand_container.display_hand(hand, _controller.player.mana.current)


func _on_mana_updated(current: int, cap: int) -> void:
	_hud.update_mana(current, cap)
	_on_hand_updated(_controller.player.deck.hand)


func _on_piles_updated(draw_count: int, burn_count: int) -> void:
	_hud.update_piles(draw_count, burn_count)


func _on_card_play_requested(card: Resource) -> void:
	if card is CardData:
		_controller.try_play_card(card as CardData)
	else:
		EventBus.combat_log.emit("Cannot play card — unsupported card type.")


func _on_card_selected(card: CardData) -> void:
	_controller.try_play_card(card)
