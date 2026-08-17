class_name StarterDeck
extends RefCounted

## Builds combat decks from data/cards/*.tres (GDD: 20–50 cards).

const SLASH := preload("res://data/cards/slash.tres")
const GUARD := preload("res://data/cards/guard.tres")
const EMBER := preload("res://data/cards/ember.tres")
const MEND := preload("res://data/cards/mend.tres")
const STAB := preload("res://data/cards/stab.tres")


static func create_orphan_deck() -> Array[CardData]:
	var cards: Array[CardData] = []
	_add_copies(cards, SLASH, 10)
	_add_copies(cards, GUARD, 4)
	_add_copies(cards, EMBER, 4)
	_add_copies(cards, MEND, 2)
	return cards


static func create_party_deck(member_ids: Array[String]) -> Array[CardData]:
	var cards: Array[CardData] = create_orphan_deck()
	if member_ids.has(PartyManager.BRYNNAEL):
		_add_copies(cards, MEND, 4)
	if member_ids.has(PartyManager.EDWARD):
		_add_copies(cards, STAB, 4)
	if member_ids.has(PartyManager.SELUC):
		_add_copies(cards, SLASH, 2)
		_add_copies(cards, EMBER, 2)
	while cards.size() > GameConstants.DECK_MAX_SIZE:
		cards.pop_back()
	while cards.size() < GameConstants.DECK_MIN_SIZE:
		_add_copies(cards, SLASH, 1)
	return cards


static func _add_copies(target: Array[CardData], template: Resource, count: int) -> void:
	if count <= 0 or template == null:
		return
	var base_card: CardData = template as CardData
	if base_card == null:
		return
	for i in count:
		var card: CardData = base_card.duplicate() as CardData
		card.id = "%s_%d" % [base_card.id, target.size()]
		target.append(card)
