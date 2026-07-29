class_name RarityTier
extends Resource

## Gear-only rarity definition (loot / equipment).
## Card rarity is separate — see CardData.Rarity in the deck module.
##
## How multipliers interact with WeaponData / ShieldData:
## - WeaponData.base_damage and ShieldData.base_hp_boost are AUTHORING values
##   (pre-rarity). Combat / inventory should read scaled helpers on those classes,
##   which multiply by stat_multiplier unless uses_fixed_stats is true (Unique).
## - Example: Common sword base_damage 10 → scaled 10 * 1.05 = 11.
## - Unique gear sets uses_fixed_stats = true so the authored numbers are final.

enum Id {
	TRASH,
	COMMON,
	MAGIC,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
	UNIQUE,
}

@export var id: Id = Id.COMMON
@export var tier_name: String = ""
@export var color: Color = Color.WHITE
## Multiplier applied to Weapon/Shield base stats when the tier scales normally.
@export var stat_multiplier: float = 1.0
## When true, ignore stat_multiplier and use the item's authored stats as-is (Unique).
@export var uses_fixed_stats: bool = false
@export_multiline var deck_impact: String = ""
## False for Legendary / Mythic / Unique — excluded from the standard drop table.
@export var is_standard_drop: bool = true


func scales_with_multiplier() -> bool:
	return not uses_fixed_stats


## Shared helper for WeaponData / ShieldData scaled getters.
func scale_stat(base_value: int) -> int:
	if uses_fixed_stats:
		return base_value
	return int(round(float(base_value) * stat_multiplier))


func scale_stat_f(base_value: float) -> float:
	if uses_fixed_stats:
		return base_value
	return base_value * stat_multiplier
