class_name Combatant
extends RefCounted

signal stats_changed

@export var display_name: String = "Combatant"
@export var max_hp: int = 100

var current_hp: int = 100
var deck: CombatantDeck = CombatantDeck.new()
var mana: ManaPool = ManaPool.new()
var cards_played_this_turn: int = 0


func reset_for_combat(deck_cards: Array[CardData], starting_mana: int = 0) -> void:
	current_hp = max_hp
	cards_played_this_turn = 0
	deck.load_deck(deck_cards)
	mana.reset_for_combat(starting_mana)
	stats_changed.emit()


func begin_turn() -> void:
	cards_played_this_turn = 0
	mana.on_turn_start()
	var cards_to_draw: int = deck.hand_limit - deck.hand.size()
	if cards_to_draw > 0:
		deck.draw_cards(cards_to_draw)


func can_play_card(card: CardData, overdrive: bool = false) -> bool:
	var play_limit: int = GameConstants.OVERDRIVE_MAX_PLAYS if overdrive else hand_limit_for_turn()
	if cards_played_this_turn >= play_limit:
		return false
	return mana.can_afford(card) and not card.is_dormant


func play_card(card: CardData) -> bool:
	if not mana.spend_for_card(card):
		return false
	if not deck.play_card(card):
		return false
	cards_played_this_turn += 1
	stats_changed.emit()
	return true


func hand_limit_for_turn() -> int:
	return deck.hand_limit
