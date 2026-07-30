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


func draw_cards(amount: int) -> void:
	if amount <= 0:
		return
	for _i: int in amount:
		if hand.size() >= MAX_HAND_SIZE:
			return
		if draw_pile.is_empty():
			_reshuffle_burn_pile()
			if draw_pile.is_empty():
				return
		var card: Resource = draw_pile.pop_back()
		hand.append(card)


func play_card(card: Resource, target: Node) -> void:
	if card == null:
		push_warning("DeckManager.play_card: card is null")
		return
	var index: int = hand.find(card)
	if index < 0:
		push_warning("DeckManager.play_card: card not in hand")
		return
	hand.remove_at(index)
	burn_pile.append(card)
	var target_name: String = target.name if is_instance_valid(target) else ""
	EventBus.card_played.emit(card, target_name)


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
