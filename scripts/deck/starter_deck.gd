class_name StarterDeck
extends RefCounted

## Builds a minimal 20-card starter deck for the combat prototype.


static func create_orphan_deck() -> Array[CardData]:
	var cards: Array[CardData] = []
	_add_copies(cards, _make_card("slash", "Slash", 1, CardData.BaseClass.WARRIOR), 10)
	_add_copies(cards, _make_card("guard", "Guard", 1, CardData.BaseClass.WARRIOR), 4)
	_add_copies(cards, _make_card("ember", "Ember", 2, CardData.BaseClass.MAGE), 4)
	_add_copies(cards, _make_card("mend", "Mend", 2, CardData.BaseClass.PRIEST), 4)
	_add_copies(cards, _make_card("stab", "Stab", 1, CardData.BaseClass.ROGUE), 2)
	return cards


static func _add_copies(target: Array[CardData], template: CardData, count: int) -> void:
	for i in count:
		var card: CardData = template.duplicate()
		card.id = "%s_%d" % [template.id, i]
		target.append(card)


static func _make_card(
	id: String,
	display_name: String,
	mana_cost: int,
	base_class: CardData.BaseClass,
) -> CardData:
	var card := CardData.new()
	card.id = id
	card.display_name = display_name
	card.mana_cost = mana_cost
	card.base_class = base_class
	card.description = "%s — %d mana" % [display_name, mana_cost]
	return card
