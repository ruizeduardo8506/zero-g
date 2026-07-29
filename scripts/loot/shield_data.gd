class_name ShieldData
extends GearData

## Shield specialization of GearData — Miracle Guard system.
##
## Rarity interaction:
## - Author base_hp_boost as the pre-rarity value.
## - Call scaled_hp_boost() at runtime: base_hp_boost * RarityTier.stat_multiplier
##   (skipped when uses_fixed_stats — Unique).
## - deflect_chance is a probability (0.0–1.0). Scale it with apply_rarity_to_stat_f
##   only if design wants rarer shields to deflect more; for now scaled_deflect_chance()
##   applies the same rarity multiplier, clamped to 1.0.
## - has_defiance is a boolean perk and is NOT multiplied by rarity.

enum ShieldType {
	BUCKLER,
	ROUND,
	KITE,
	TOWER,
}

@export_group("Shield")
@export var shield_type: ShieldType = ShieldType.BUCKLER
## Flat max-HP granted while this shield is equipped (pre-rarity).
@export var base_hp_boost: int = 0
## Chance (0.0–1.0) to completely nullify one incoming standard attack.
@export_range(0.0, 1.0, 0.01) var deflect_chance: float = 0.0
## If true, survive a lethal hit at exactly 1 HP once per battle (Defiance).
@export var has_defiance: bool = false


func _init() -> void:
	equip_slot = EquipSlot.OFF_HAND


## Combat-facing HP boost after rarity scaling.
func scaled_hp_boost() -> int:
	return apply_rarity_to_stat(base_hp_boost)


## Deflect chance after rarity scaling, capped at 100%.
func scaled_deflect_chance() -> float:
	return clampf(apply_rarity_to_stat_f(deflect_chance), 0.0, 1.0)


## Whether this shield may pair with the given main-hand weapon.
func is_valid_with_main_hand(main_hand: WeaponData) -> bool:
	if main_hand == null:
		return false
	return main_hand.allows_off_hand()
