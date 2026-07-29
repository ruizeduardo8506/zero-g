class_name DeckManager
extends RefCounted

signal hand_changed(hand: Array[CardData])
signal piles_changed(draw_count: int, burn_count: int)
signal card_drawn(card: CardData)
signal card_played(card: CardData)
signal reshuffle_required
signal fatigue_applied

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var burn_pile: Array[CardData] = []

var hand_limit: int = GameConstants.HAND_START_SIZE
var fatigue_stacks: int = 0


func load_deck(cards: Array[CardData]) -> void:
	draw_pile = cards.duplicate()
	hand.clear()
	burn_pile.clear()
	fatigue_stacks = 0
	_shuffle_draw_pile()
	_emit_pile_state()


func draw_cards(count: int) -> int:
	var drawn: int = 0
	while drawn < count and hand.size() < hand_limit:
		if draw_pile.is_empty():
			if burn_pile.is_empty():
				break
			reshuffle_required.emit()
			reshuffle_from_burn()
		if draw_pile.is_empty():
			break
		var card: CardData = draw_pile.pop_back()
		hand.append(card)
		card_drawn.emit(card)
		drawn += 1
	hand_changed.emit(hand)
	_emit_pile_state()
	return drawn


func play_card(card: CardData) -> bool:
	var index: int = hand.find(card)
	if index < 0:
		return false
	hand.remove_at(index)
	burn_pile.append(card)
	card_played.emit(card)
	hand_changed.emit(hand)
	_emit_pile_state()
	return true


func reshuffle_from_burn(apply_fatigue: bool = true) -> void:
	if burn_pile.is_empty():
		return
	draw_pile = burn_pile.duplicate()
	burn_pile.clear()
	_shuffle_draw_pile()
	if apply_fatigue:
		fatigue_stacks += 1
		fatigue_applied.emit()
	_emit_pile_state()


func _shuffle_draw_pile() -> void:
	draw_pile.shuffle()


func _emit_pile_state() -> void:
	piles_changed.emit(draw_pile.size(), burn_pile.size())
