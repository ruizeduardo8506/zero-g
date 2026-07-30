extends Node

# Decoupled combat signals. Systems emit here; UI and audio subscribe.

# COMBAT LIFECYCLE
signal combat_started
signal combat_ended(victory: bool)
signal combat_log(message: String)

# COMBAT & DECK SIGNALS
signal card_drawn(card: CardData, combatant_name: String)
## `target` is the combat Node chosen for the card; null when untargeted / pending.
signal card_played(card: Resource, target: Node)
signal targeting_started(card_data: Resource)
signal deck_shuffled()
signal hand_discarded()
signal hand_updated(hand: Array[CardData])
signal fatigue_triggered()
signal piles_updated(draw_count: int, burn_count: int)

# ENTITY & STAT SIGNALS
signal health_changed(entity_id: String, new_hp: int, max_hp: int)
signal mana_changed(entity_id: String, new_mana: int, max_mana: int)
signal mana_updated(current: int, cap: int)
signal entity_died(entity_id: String)
## Focused combatant for the Dynamic Target Frame (party / multi-enemy UI).
signal target_hovered(entity: CombatEntity)
## Player selected a combatant while targeting a card.
signal entity_clicked(entity: CombatEntity)

# GAME STATE SIGNALS
signal turn_started(turn_number: int, active_combatant_name: String)
signal turn_ended(turn_number: int)
signal phase_changed(previous: int, current: int)
