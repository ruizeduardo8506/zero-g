class_name CombatEntity
extends Node2D

## Base class for all combat participants (party members and enemies).
## Routes HP / mana updates through EventBus so UI stays decoupled (GDD Phase 2).
## Party members should be in group "player_combat_entity" (or registered via
## CombatStateMachine.set_active_player_entity) so Fatigue mana-burn can find them.

# GDD defaults: mana regen 5 / turn, mana cap 20.
@export var entity_id: String = ""
@export var max_hp: int = 100
@export var max_mana: int = 20
@export var base_mana_regen: int = 5

var current_hp: int = 0
var current_mana: int = 0


func _ready() -> void:
	if entity_id.is_empty():
		entity_id = name
	current_hp = max_hp
	current_mana = max_mana
	# Defer so CombatHud / other subscribers finish connecting in _ready first.
	call_deferred("_broadcast_stats")


## Push current HP / mana to EventBus (spawn init and external resync).
func _broadcast_stats() -> void:
	EventBus.health_changed.emit(entity_id, current_hp, max_hp)
	EventBus.mana_changed.emit(entity_id, current_mana, max_mana)


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	var was_alive: bool = current_hp > 0
	current_hp = clampi(current_hp - amount, 0, max_hp)
	EventBus.health_changed.emit(entity_id, current_hp, max_hp)
	if was_alive and current_hp == 0:
		EventBus.entity_died.emit(entity_id)


func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = clampi(current_hp + amount, 0, max_hp)
	EventBus.health_changed.emit(entity_id, current_hp, max_hp)


## Returns true and spends mana when the pool can cover `amount`.
func spend_mana(amount: int) -> bool:
	if amount < 0:
		return false
	if current_mana < amount:
		return false
	current_mana = clampi(current_mana - amount, 0, max_mana)
	EventBus.mana_changed.emit(entity_id, current_mana, max_mana)
	return true


## Start-of-turn mana refill (GDD: +base_mana_regen, capped at max_mana).
func regenerate_mana() -> void:
	current_mana = clampi(current_mana + base_mana_regen, 0, max_mana)
	EventBus.mana_changed.emit(entity_id, current_mana, max_mana)


## GDD Fatigue — empty draw-pile reshuffle burns mana to 0.
## Called by CombatStateMachine after EventBus.fatigue_triggered (from DeckManager).
## Does not re-emit fatigue_triggered — that would recurse.
func trigger_fatigue_penalty() -> void:
	current_mana = 0
	EventBus.mana_changed.emit(entity_id, current_mana, max_mana)


func is_alive() -> bool:
	return current_hp > 0
