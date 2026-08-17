class_name AbilityCard
extends CardData

## Compatibility wrapper around CardData for older tests / CombatDeckManager.

var card_name: String:
	get:
		return display_name
	set(value):
		display_name = value

var base_power: int:
	get:
		return base_damage
	set(value):
		base_damage = value


func is_playable_from_hand(current_mana: int) -> bool:
	return is_playable(current_mana)
