class_name CombatDeckManager
extends Node

## In-battle card lifecycle: draw pile → hand → burn pile (GDD § Combat & Deck Engine).
## Attach as a child of a character / combatant scene. Does not spend mana or resolve
## effects — only moves AbilityCard resources and notifies listeners via signals.

# GDD: deck 20–50 cards; hand expands to 10 (12 in overdrive — handled by callers).
const DECK_MIN_SIZE: int = 20
const DECK_MAX_SIZE: int = 50
const DEFAULT_MAX_HAND_SIZE: int = 10

signal card_drawn(card: AbilityCard)
signal card_played(card: AbilityCard)
## Emitted when burn is reshuffled into the draw pile. fatigue_penalty_triggered is
## true for empty-draw reshuffles (GDD Fatigue: mana burn / stat debuffs).
signal deck_reshuffled(fatigue_penalty_triggered: bool)

## Full list brought into the fight (designer-authored or built before combat).
@export var starting_deck: Array[AbilityCard] = []
## Soft cap for hand; callers may raise for overdrive (up to 12 per GDD).
@export var max_hand_size: int = DEFAULT_MAX_HAND_SIZE

var draw_pile: Array[AbilityCard] = []
var hand: Array[AbilityCard] = []
var burn_pile: Array[AbilityCard] = []


## Copies starting_deck into draw_pile, clears hand/burn, then shuffles.
func initialize_deck() -> void:
	var size: int = starting_deck.size()
	if size < DECK_MIN_SIZE or size > DECK_MAX_SIZE:
		push_warning(
			"CombatDeckManager: starting_deck size %d outside GDD range %d–%d"
			% [size, DECK_MIN_SIZE, DECK_MAX_SIZE]
		)

	draw_pile = starting_deck.duplicate()
	hand.clear()
	burn_pile.clear()
	_shuffle(draw_pile)


## Draws up to `amount` cards. Overflow past max_hand_size goes straight to burn.
## Empty draw pile triggers a fatigue reshuffle from burn when possible.
func draw_card(amount: int) -> void:
	if amount <= 0:
		return

	for _i: int in amount:
		if draw_pile.is_empty():
			if burn_pile.is_empty():
				return
			reshuffle_burn_pile()
			if draw_pile.is_empty():
				return

		var card: AbilityCard = draw_pile.pop_back()
		if hand.size() >= max_hand_size:
			# Overcap: never enters hand — burn immediately (no card_drawn).
			burn_pile.append(card)
			continue

		hand.append(card)
		card_drawn.emit(card)


## Removes `card` from hand and sends it to the burn pile.
func play_card(card: AbilityCard) -> void:
	if card == null:
		push_warning("CombatDeckManager.play_card: card is null")
		return

	var index: int = hand.find(card)
	if index < 0:
		push_warning("CombatDeckManager.play_card: card not in hand (%s)" % card.id)
		return

	hand.remove_at(index)
	burn_pile.append(card)
	card_played.emit(card)


## Moves burn → draw and shuffles. Always counts as a Fatigue event per GDD
## (manual / forced reshuffle when the draw pile is exhausted).
func reshuffle_burn_pile() -> void:
	if burn_pile.is_empty():
		deck_reshuffled.emit(false)
		return

	for card: AbilityCard in burn_pile:
		draw_pile.append(card)
	burn_pile.clear()
	_shuffle(draw_pile)
	deck_reshuffled.emit(true)


func get_draw_count() -> int:
	return draw_pile.size()


func get_hand_count() -> int:
	return hand.size()


func get_burn_count() -> int:
	return burn_pile.size()


func _shuffle(pile: Array[AbilityCard]) -> void:
	pile.shuffle()
