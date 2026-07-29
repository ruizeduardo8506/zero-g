class_name RarityTier
extends Resource

## Gear-only rarity definition (loot / equipment).
## Card rarity is separate — see CardData.Rarity.

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
## Multiplier applied to base gear stats when rolling / scaling this tier.
@export var stat_multiplier: float = 1.0
## When true, generators ignore stat_multiplier and use the item's fixed stats (Unique).
@export var uses_fixed_stats: bool = false
@export_multiline var deck_impact: String = ""
## False for Legendary / Mythic / Unique — not in the standard drop table.
@export var is_standard_drop: bool = true


func scales_with_multiplier() -> bool:
	return not uses_fixed_stats
