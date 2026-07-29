class_name AbilityCard
extends Resource

## Phase 1 ability-card definition for the combat deck engine (GDD).
## Stored as .tres under data/cards/; logic lives in scripts/deck/.
##
## DORMANT cards: unplayable from hand until a WeaponData physical hit procs them
## (GDD — physical attacks can awaken dormant abilities at zero mana cost), or until
## a required weapon/combo condition is met. Combat should skip DORMANT in normal
## playability checks and route them through the weapon-proc / unlock pipeline instead.

enum DamageType {
	NONE,
	SLASHING,
	BLUNT,
	ELEMENTAL,
}

enum CardType {
	ATTACK,
	SKILL,
	DORMANT,
}

@export var id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var damage_type: DamageType = DamageType.NONE
## Raw value for damage, healing, or shielding before combat modifiers.
@export var base_power: int = 0
## True for full-party / all-enemy AoE sweeps.
@export var target_all: bool = false


## Normal hand play — DORMANT cards are never playable this way.
func is_playable_from_hand(current_mana: int) -> bool:
	if card_type == CardType.DORMANT:
		return false
	return mana_cost <= current_mana


## Weapon-proc path: DORMANT (and optionally other) cards may fire at zero mana.
func can_proc_from_weapon() -> bool:
	return card_type == CardType.DORMANT
