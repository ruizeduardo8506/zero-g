class_name WeaponData
extends GearData

## Weapon specialization of GearData.
##
## Rarity interaction:
## - Author base_damage as the pre-rarity value (generators may boost 2H rolls first).
## - Call scaled_damage() at runtime: base_damage * RarityTier.stat_multiplier
##   (skipped when the tier has uses_fixed_stats — Unique).
## - TWO_HANDED_BASE_ATTACK_MULT is for loot generation only; it is NOT re-applied
##   inside scaled_damage() so Unique authored numbers stay exact.

enum WeaponType {
	SWORD,
	AXE,
	MACE,
	DAGGER,
	SPEAR,
	WAND,
	GREAT_SWORD,
	GREAT_AXE,
	GREAT_MACE,
	BOW,
	FIST,
	STAFF,
}

enum Handedness {
	ONE_HANDED,
	TWO_HANDED,
}

enum DamageType {
	SLASHING,
	BLUNT,
	ELEMENTAL,
}

## Generators multiply a one-hand base roll by this when creating two-handed weapons.
const TWO_HANDED_BASE_ATTACK_MULT: float = 1.35

@export_group("Weapon")
@export var weapon_type: WeaponType = WeaponType.SWORD
@export var handedness: Handedness = Handedness.ONE_HANDED
## True for daggers — may occupy EquipSlot.OFF_HAND as well as MAIN_HAND.
@export var can_be_offhand: bool = false
@export var base_damage: int = 0
@export var damage_type: DamageType = DamageType.SLASHING


func _init() -> void:
	equip_slot = EquipSlot.MAIN_HAND


## Combat-facing damage after rarity scaling.
func scaled_damage() -> int:
	return apply_rarity_to_stat(base_damage)


func is_two_handed() -> bool:
	return handedness == Handedness.TWO_HANDED


## Main-hand weapon leaves OFF_HAND free for a shield or off-hand dagger.
## Staff is TWO_HANDED but still allows a shield (elemental ranged exception).
## Fist and other two-handers block the off-hand.
func allows_off_hand() -> bool:
	if equip_slot != EquipSlot.MAIN_HAND:
		return false
	if handedness == Handedness.ONE_HANDED:
		return true
	return weapon_type == WeaponType.STAFF


func blocks_off_hand() -> bool:
	return equip_slot == EquipSlot.MAIN_HAND and not allows_off_hand()


func is_valid_off_hand_dagger() -> bool:
	return can_be_offhand and equip_slot == EquipSlot.OFF_HAND and weapon_type == WeaponType.DAGGER


## Default handedness / off-hand flag / damage kind for a weapon family.
static func default_handedness(type: WeaponType) -> Handedness:
	match type:
		WeaponType.GREAT_SWORD, WeaponType.GREAT_AXE, WeaponType.GREAT_MACE, \
		WeaponType.BOW, WeaponType.FIST, WeaponType.STAFF:
			return Handedness.TWO_HANDED
		_:
			return Handedness.ONE_HANDED


static func default_can_be_offhand(type: WeaponType) -> bool:
	return type == WeaponType.DAGGER


static func default_damage_type(type: WeaponType) -> DamageType:
	match type:
		WeaponType.MACE, WeaponType.FIST, WeaponType.GREAT_MACE:
			return DamageType.BLUNT
		WeaponType.WAND, WeaponType.STAFF:
			return DamageType.ELEMENTAL
		_:
			return DamageType.SLASHING


## Apply two-hand attack bias when rolling base_damage for a new weapon.
static func apply_handedness_to_base_damage(one_hand_base: int, type: WeaponType) -> int:
	if default_handedness(type) != Handedness.TWO_HANDED:
		return one_hand_base
	return int(round(float(one_hand_base) * TWO_HANDED_BASE_ATTACK_MULT))
