class_name AccessoryData
extends GearData

## Accessory specialization of GearData (rings / necklaces).
##
## Class anchors (GDD): when is_class_anchor is true, GearData.class_anchor
## forces the wearer's advanced class override. Rarity does not scale the flag.

enum AccessoryType {
	RING,
	NECKLACE,
}

@export_group("Accessory")
@export var accessory_type: AccessoryType = AccessoryType.RING
## If true, this piece forces a class change via class_anchor (Legendary+ anchors).
@export var is_class_anchor: bool = false


func _init() -> void:
	equip_slot = EquipSlot.ACCESSORY


func forces_class_change() -> bool:
	return is_class_anchor and class_anchor != ClassAnchor.NONE
