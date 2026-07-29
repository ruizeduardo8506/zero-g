extends Control

@onready var _controller: CombatController = %CombatController
@onready var _hud: CombatHud = %CombatHud


func _ready() -> void:
	_wire_signals()
	_controller.start_combat(StarterDeck.create_orphan_deck())


func _wire_signals() -> void:
	CombatStateMachine.phase_changed.connect(_on_phase_changed)
	EventBus.hand_updated.connect(_on_hand_updated)
	EventBus.mana_updated.connect(_on_mana_updated)
	EventBus.piles_updated.connect(_on_piles_updated)
	_hud.get_hand_container().card_selected.connect(_on_card_selected)
	_hud.end_turn_pressed.connect(_controller.end_player_turn)


func _on_phase_changed(_previous: int, current: int) -> void:
	var phase_name: String = CombatStateMachine.Phase.keys()[current]
	_hud.update_turn(CombatStateMachine.turn_number, phase_name)
	var is_player_main: bool = current == CombatStateMachine.Phase.PLAYER_MAIN
	_hud.set_interaction_enabled(is_player_main)


func _on_hand_updated(hand: Array[CardData]) -> void:
	_hud.get_hand_container().display_hand(hand, _controller.player.mana.current)


func _on_mana_updated(current: int, cap: int) -> void:
	_hud.update_mana(current, cap)
	_on_hand_updated(_controller.player.deck.hand)


func _on_piles_updated(draw_count: int, burn_count: int) -> void:
	_hud.update_piles(draw_count, burn_count)


func _on_card_selected(card: CardData) -> void:
	_controller.try_play_card(card)
