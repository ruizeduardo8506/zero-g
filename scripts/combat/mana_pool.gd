class_name ManaPool
extends RefCounted

signal mana_changed(current: int, cap: int)

var current: int = 0
var cap: int = GameConstants.MANA_DEFAULT_CAP
var regen_per_turn: int = GameConstants.MANA_REGEN_PER_TURN


func reset_for_combat(starting_mana: int = 0) -> void:
	current = clampi(starting_mana, 0, cap)
	mana_changed.emit(current, cap)


func on_turn_start() -> void:
	current = mini(current + regen_per_turn, cap)
	mana_changed.emit(current, cap)


func can_afford(card: CardData) -> bool:
	if card.drains_full_mana:
		return current > 0
	return card.mana_cost <= current


func spend_for_card(card: CardData) -> bool:
	if not can_afford(card):
		return false
	if card.drains_full_mana:
		current = 0
	else:
		current -= card.mana_cost
	mana_changed.emit(current, cap)
	return true
