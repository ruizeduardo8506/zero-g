class_name ArmorData
extends GearData

## Armor specialization of GearData.
##
## Rarity interaction:
## - Author base_defense as the pre-rarity value.
## - Call scaled_defense() at runtime: base_defense * RarityTier.stat_multiplier
##   (skipped when uses_fixed_stats — Unique).

enum ArmorSlot {
	HELMET,
	CHEST,
	GLOVES,
	BOOTS,
}

@export_group("Armor")
@export var armor_slot: ArmorSlot = ArmorSlot.CHEST
## Pre-rarity defense. Combat reads scaled_defense().
@export var base_defense: int = 0


func _init() -> void:
	equip_slot = EquipSlot.ARMOR


func scaled_defense() -> int:
	return apply_rarity_to_stat(base_defense)
