class_name GearData
extends Resource

## Base custom resource for all equipment.
## Specialize via WeaponData, ShieldData, ArmorData, and AccessoryData.
##
## Rarity: every piece stores rarity_id. Concrete subclasses scale their own
## base stats through get_rarity().scale_stat(...) — see RarityTier comments.

enum EquipSlot {
	MAIN_HAND,
	OFF_HAND,
	ARMOR,
	ACCESSORY,
}

## Legendary class-anchor override (GDD). NONE means no force.
enum ClassAnchor {
	NONE,
	WARRIOR,
	MAGE,
	PRIEST,
	ROGUE,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var equip_slot: EquipSlot = EquipSlot.MAIN_HAND
@export var rarity_id: RarityTier.Id = RarityTier.Id.COMMON

@export_group("Special")
@export var is_cursed: bool = false
@export var class_anchor: ClassAnchor = ClassAnchor.NONE
## Card id permanently burned onto gear via Imbue (GDD). Empty if none.
@export var imbued_card_id: String = ""


func get_rarity() -> RarityTier:
	return RarityCatalog.get_tier(rarity_id)


## Apply this piece's rarity multiplier to an authored integer base.
## Unique tiers (uses_fixed_stats) return the base unchanged.
func apply_rarity_to_stat(base_value: int) -> int:
	return get_rarity().scale_stat(base_value)


func apply_rarity_to_stat_f(base_value: float) -> float:
	return get_rarity().scale_stat_f(base_value)
