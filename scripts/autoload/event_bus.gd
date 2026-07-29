extends Node

# Decoupled combat signals. Systems emit here; UI and audio subscribe.

signal combat_started
signal combat_ended(victory: bool)

signal turn_started(turn_number: int, active_combatant_name: String)
signal turn_ended(turn_number: int)

signal card_drawn(card: CardData, combatant_name: String)
signal card_played(card: CardData, combatant_name: String)
signal hand_updated(hand: Array[CardData])

signal mana_updated(current: int, cap: int)
signal piles_updated(draw_count: int, burn_count: int)

signal phase_changed(previous: int, current: int)
signal combat_log(message: String)
