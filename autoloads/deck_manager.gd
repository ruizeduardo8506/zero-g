extends Node

## Global in-combat deck lifecycle (autoload).
## Draw → hand → burn; empty draw reshuffles burn and triggers Fatigue via EventBus.
## Per-combatant pile helper remains scripts/deck/deck_manager.gd (CombatantDeck).

const MIN_DECK_SIZE: int = 20
const MAX_DECK_SIZE: int = 50
const MAX_HAND_SIZE: int = 10

var draw_pile: Array[Resource] = []
var hand: Array[Resource] = []
var burn_pile: Array[Resource] = []


func initialize_combat_deck(active_deck: Array[Resource]) -> void:
	var size: int = active_deck.size()
	if size < MIN_DECK_SIZE or size > MAX_DECK_SIZE:
		push_warning(
			"DeckManager: active_deck size %d outside GDD range %d–%d"
			% [size, MIN_DECK_SIZE, MAX_DECK_SIZE]
		)
	draw_pile = active_deck.duplicate()
	hand.clear()
	burn_pile.clear()
	draw_pile.shuffle()
	_emit_piles()


func draw_cards(amount: int) -> void:
	if amount <= 0:
		return
	for _i: int in amount:
		if hand.size() >= MAX_HAND_SIZE:
			break
		if draw_pile.is_empty():
			_reshuffle_burn_pile()
			if draw_pile.is_empty():
				break
		var card: Resource = draw_pile.pop_back()
		hand.append(card)
		EventBus.card_drawn.emit(card, "player")
	_emit_piles()
	EventBus.hand_updated.emit(_hand_as_card_data())


## End-of-turn: all remaining hand cards go to the burn pile.
func discard_hand() -> void:
	if hand.is_empty():
		EventBus.hand_discarded.emit()
		_emit_piles()
		return
	for card: Resource in hand:
		burn_pile.append(card)
	hand.clear()
	EventBus.hand_discarded.emit()
	_emit_piles()
	var empty_hand: Array[CardData] = []
	EventBus.hand_updated.emit(empty_hand)


## Move a played card hand → burn without re-emitting card_played (avoids recursion).
func consume_card(card: Resource) -> bool:
	if card == null:
		return false
	var index: int = hand.find(card)
	if index < 0:
		return false
	hand.remove_at(index)
	burn_pile.append(card)
	_emit_piles()
	return true


## Undo a cancelled play — burn → hand.
func return_card_to_hand(card: Resource) -> bool:
	if card == null:
		return false
	var index: int = burn_pile.find(card)
	if index < 0:
		return false
	burn_pile.remove_at(index)
	hand.append(card)
	_emit_piles()
	return true


func play_card(card: Resource, target: Node) -> void:
	if card == null:
		push_warning("DeckManager.play_card: card is null")
		return
	if not consume_card(card):
		push_warning("DeckManager.play_card: card not in hand")
		return
	EventBus.card_played.emit(card, target)


func _reshuffle_burn_pile() -> void:
	if burn_pile.is_empty():
		return
	for card: Resource in burn_pile:
		draw_pile.append(card)
	burn_pile.clear()
	draw_pile.shuffle()
	EventBus.deck_shuffled.emit()
	# GDD Fatigue: empty-draw reshuffle — combat applies mana burn / debuffs on this signal.
	EventBus.fatigue_triggered.emit()


func _emit_piles() -> void:
	EventBus.piles_updated.emit(draw_pile.size(), burn_pile.size())


func _hand_as_card_data() -> Array[CardData]:
	var typed: Array[CardData] = []
	for card: Resource in hand:
		if card is CardData:
			typed.append(card as CardData)
	return typed
