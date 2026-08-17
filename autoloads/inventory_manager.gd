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

var dispatch_active: bool = false
var dispatch_complete_at_msec: int = 0


func reset() -> void:
	gold = 0
	primal_essence = 0
	materials = {"wood": 0, "ore": 0, "rock": 0}
	master_card_collection.clear()
	equipment_inventory.clear()
	dispatch_active = false
	dispatch_complete_at_msec = 0
	EventBus.inventory_changed.emit()


func add_material(type: String, amount: int) -> void:
	if amount == 0:
		return
	if not materials.has(type):
		push_warning("InventoryManager.add_material: unknown type '%s'" % type)
		return
	var next: int = int(materials[type]) + amount
	materials[type] = maxi(0, next)
	EventBus.inventory_changed.emit()


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	EventBus.inventory_changed.emit()


## Spend gold (default) or primal_essence when is_essence is true.
## Returns false if the balance is insufficient.
func spend_currency(amount: int, is_essence: bool = false) -> bool:
	if amount < 0:
		return false
	if is_essence:
		if primal_essence < amount:
			return false
		primal_essence -= amount
		EventBus.inventory_changed.emit()
		return true
	if gold < amount:
		return false
	gold -= amount
	EventBus.inventory_changed.emit()
	return true


func start_dispatch() -> bool:
	if dispatch_active:
		return false
	dispatch_active = true
	dispatch_complete_at_msec = Time.get_ticks_msec() + int(GameConstants.DISPATCH_DURATION_SEC * 1000.0)
	EventBus.inventory_changed.emit()
	return true


func poll_dispatch() -> bool:
	if not dispatch_active:
		return false
	if Time.get_ticks_msec() < dispatch_complete_at_msec:
		return false
	dispatch_active = false
	dispatch_complete_at_msec = 0
	add_material("wood", GameConstants.DISPATCH_WOOD_REWARD)
	return true


func dispatch_remaining_sec() -> float:
	if not dispatch_active:
		return 0.0
	return maxf(0.0, float(dispatch_complete_at_msec - Time.get_ticks_msec()) / 1000.0)


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"primal_essence": primal_essence,
		"wood": int(materials.get("wood", 0)),
		"ore": int(materials.get("ore", 0)),
		"rock": int(materials.get("rock", 0)),
		"dispatch_active": dispatch_active,
		"dispatch_complete_at_msec": dispatch_complete_at_msec,
	}


func from_dict(data: Dictionary) -> void:
	gold = int(data.get("gold", 0))
	primal_essence = int(data.get("primal_essence", 0))
	materials["wood"] = int(data.get("wood", 0))
	materials["ore"] = int(data.get("ore", 0))
	materials["rock"] = int(data.get("rock", 0))
	dispatch_active = bool(data.get("dispatch_active", false))
	dispatch_complete_at_msec = int(data.get("dispatch_complete_at_msec", 0))
	EventBus.inventory_changed.emit()
