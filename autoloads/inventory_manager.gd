extends Node

## Persistent player economy and inventory (autoload).
## Gold / Primal Essence / gathering materials + card & gear collections.

var gold: int = 0
var primal_essence: int = 0

var materials: Dictionary = {
	"wood": 0,
	"ore": 0,
	"rock": 0,
}

## Persistent AbilityCard / CardData definitions owned by the player.
var master_card_collection: Array[Resource] = []
## Persistent GearData (weapons, armor, shields, accessories).
var equipment_inventory: Array[Resource] = []


func add_material(type: String, amount: int) -> void:
	if amount == 0:
		return
	if not materials.has(type):
		push_warning("InventoryManager.add_material: unknown type '%s'" % type)
		return
	var next: int = int(materials[type]) + amount
	materials[type] = maxi(0, next)


## Spend gold (default) or primal_essence when is_essence is true.
## Returns false if the balance is insufficient.
func spend_currency(amount: int, is_essence: bool = false) -> bool:
	if amount < 0:
		return false
	if is_essence:
		if primal_essence < amount:
			return false
		primal_essence -= amount
		return true
	if gold < amount:
		return false
	gold -= amount
	return true
