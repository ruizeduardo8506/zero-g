class_name CombatStats
extends Node

## Per-combatant HP / mana component (GDD § Combat & Deck Engine).
## Attach as a child of a character or enemy scene. UI should listen to the
## signals below; wire `trigger_fatigue_penalty` from CombatDeckManager's
## `deck_reshuffled(true)` (or the combat controller that owns both).

# GDD defaults: mana regen 5 / turn, mana cap 20 (expandable via items later).
const DEFAULT_MAX_HP: int = 100
const DEFAULT_MAX_MANA: int = 20
const DEFAULT_MANA_REGEN: int = 5

signal health_changed(new_health: int, max_health: int)
signal mana_changed(new_mana: int, max_mana: int)
signal died()
signal fatigue_triggered()

@export var max_hp: int = DEFAULT_MAX_HP
@export var max_mana: int = DEFAULT_MAX_MANA
## Mana restored at the start of this combatant's turn.
@export var base_mana_regen: int = DEFAULT_MANA_REGEN

var current_hp: int = 0
var current_mana: int = 0


func _ready() -> void:
	current_hp = maxi(0, max_hp)
	current_mana = maxi(0, max_mana)
	health_changed.emit(current_hp, max_hp)
	mana_changed.emit(current_mana, max_mana)


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	var was_alive: bool = current_hp > 0
	current_hp = clampi(current_hp - amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)
	if was_alive and current_hp == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = clampi(current_hp + amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)


## Returns true and spends mana when the pool can cover `amount`.
func spend_mana(amount: int) -> bool:
	if amount < 0:
		return false
	if current_mana < amount:
		return false
	current_mana = clampi(current_mana - amount, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)
	return true


## Start-of-turn mana refill (GDD: +base_mana_regen, capped at max_mana).
func regenerate_mana() -> void:
	current_mana = clampi(current_mana + base_mana_regen, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)


## GDD Fatigue — empty draw pile reshuffle burns the mana pool to 0.
## Forces reliance on zero-mana physical weapon procs (and DORMANT card awakens)
## until the next regenerate_mana / other mana gain.
func trigger_fatigue_penalty() -> void:
	current_mana = 0
	mana_changed.emit(current_mana, max_mana)
	fatigue_triggered.emit()


func is_alive() -> bool:
	return current_hp > 0
