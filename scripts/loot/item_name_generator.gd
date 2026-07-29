class_name ItemNameGenerator
extends RefCounted

## Procedural equipment display names (GDD loot naming).
## Static helper — call ItemNameGenerator.generate_equipment_name(...).
## Uses GearData (WeaponData / ShieldData).

const FACTION_OLD_GODS: String = "old_gods"
const FACTION_NEW_GODS: String = "new_gods"

# --- Trash / Common: [Condition] + [Material] + [Base Noun] ---
const CONDITIONS: Array[String] = [
	"Chipped",
	"Rusted",
	"Worn",
	"Cracked",
	"Bent",
	"Scuffed",
	"Frayed",
	"Patched",
	"Notched",
	"Tarnished",
]

# --- Magic / Rare: [Elemental/Crafting Prefix] + [Material] + [Base Noun] ---
const CRAFTING_PREFIXES: Array[String] = [
	"Sparking",
	"Ember",
	"Frosted",
	"Tempered",
	"Honed",
	"Runed",
	"Keen",
	"Hardened",
	"Resonant",
	"Quicksilver",
]

# --- Epic / Legendary: [Base Noun] + "of the" + [Lore Title] ---
const LORE_TITLES: Array[String] = [
	"Vanguard",
	"Heretic",
	"Scavenger",
	"Oathbound",
	"Riftwalker",
	"Ashen Choir",
	"Silent Decree",
	"Broken Seal",
	"Last Watch",
	"Wild Court",
]

# Shield epic/legendary replaces the base noun with a protective title.
const PROTECTIVE_NOUNS: Array[String] = [
	"Aegis",
	"Bulwark",
	"Ward",
	"Defender",
	"Rampart",
	"Bastion",
]

# --- Mythic / Unique: Lore-adapted legends, keyed by equipment class ---
const LEGENDS_SWORD: Array[String] = [
	"Excalibur, The First Forge",
	"Masamune, The Edge of Rebellion",
	"Durandal, The Last Decree",
	"Gram, The Oathbreaker",
	"Kusanagi, The Storm Seeker",
	"Joyeuse, The Sun-Forged Blade",
	"Dainsleif, The Blood Legacy"
]

const LEGENDS_GREAT_SWORD: Array[String] = [
	"Caladbolg, The Rift Cleaver",
	"Zulfiqar, The Split-Horizon",
	"Claymore, The Titan's Reach",
	"Balmung, The Dragon's Bane",
	"Tyrfing, The Inevitable Edge"
]

const LEGENDS_AXE: Array[String] = [
	"Parashu, The World Cleaver",
	"Labrys, The Twin Judgment",
	"Forseti, The Law Breaker",
	"Ukko, The Thunder Cleaver"
]

const LEGENDS_GREAT_AXE: Array[String] = [
	"Labrys, The Twin Judgment",
	"Storm Breaker, The hand of Thor",
	"Minotaur, The Labyrinth Fall",
	"Executioner, The Final Decree",
	"Perun, The Storm Feller"
]

const LEGENDS_MACE: Array[String] = [
	"Mjolnir, The Primal Storm",
	"Sharur, The Speaking Smash",
	"Yagrush, The Chaser",
	"Morgenstern, The Dawn Crusher"
]

const LEGENDS_GREAT_MACE: Array[String] = [
	"Giant Thumb, The Opposed Finger",
	"Ayamur, The Driver",
	"Tarkus, The Earthshaker",
	"Gada, The Immovable Force"
]

const LEGENDS_DAGGER: Array[String] = [
	"Carnwennan, The Shadow Seal",
	"Kris, The Serpent Tongue",
	"Parazonium, The Hidden Oath",
	"Pugio, The Silent Decree",
	"Rondel, The Armor Piercer"
]

const LEGENDS_SPEAR: Array[String] = [
	"Gae Bolg, The Bloodroot Spear",
	"Rhongomyniad, The Sovereign Reach",
	"Gungnir, The True Strike",
	"Trishula, The Threefold Storm",
	"Amentum, The Wind Chaser"
]

const LEGENDS_WAND: Array[String] = [
	"Caduceus Shard, The Dual Pistol",
	"Gambanteinn, The Wild Measure",
	"Thyrsus, The Wild Vine",
	"Ruyi Shard, The Changing Measure",
	"Almandal, The Crystal Focus"
]

const LEGENDS_BOW: Array[String] = [
	"Failnaught, The Lawstring",
	"Ichaival, The Storm Quiver",
	"Gandiva, The Moonstring",
	"Artemis, The Huntress Vow",
	"Pinaka, The Storm Bow",
	"Houyi, The Sun Piercer"
]

const LEGENDS_FIST: Array[String] = [
	"Caestus, The Bare Covenant",
	"Vajra Grip, The Thunder Oath",
	"Megingjord, The Titan Grip",
	"Nemean, The Beast Claws",
	"Katar, The Iron Fang"
]

const LEGENDS_STAFF: Array[String] = [
	"Gambanteinn, The Wild Measure",
	"Caduceus, The Dual Canon",
	"Ruyi Jingu, The Ocean Measure",
	"Kerykeion, The Herald's Will",
	"Khatvanga, The Skull Scepter"
]

const LEGENDS_SHIELD: Array[String] = [
	"Aegision, The Civic Bastion",
	"Svalinn, The Cool Ward",
	"Prydwen, The Hull of Law",
	"Ancile, The Falling Star",
	"Yata, The Truth Mirror",
	"Scutum, The Legion's Wall"
]

const LEGENDS_ARMOR: Array[String] = [
	"Aegis of the Fallen King",
	"Mantle of the Old Gods",
	"Plate of the Silent Decree",
	"Hide of the Rift Beast",
	"Vestments of the Silver Choir",
	"Greaves of the Last Watch",
]

const LEGENDS_ACCESSORY: Array[String] = [
	"The Eye of the Storm",
	"Heart of the Forge",
	"Signet of the Broken Seal",
	"Amulet of the Wild Pantheon",
	"Ring of the Civic Guard",
	"Necklace of the Ashen Grove",
]

# Flat fallback catalog of legends
const LORE_ADAPTED_LEGENDS: Array[String] = [
	"Excalibur, The First Forge",
	"Mjolnir, The Primal Storm",
	"Masamune, The Edge of Rebellion",
	"Gae Bolg, The Bloodroot Spear",
	"Durandal, The Last Decree",
	"Caladbolg, The Rift Cleaver",
	"Gram, The Oathbreaker",
	"Aegision, The Civic Bastion",
	"Parashu, The World Cleaver",
	"Labrys, The Twin Judgment",
	"Carnwennan, The Shadow Seal",
	"Kris, The Serpent Tongue",
	"Rhongomyniad, The Sovereign Reach",
	"Caduceus Shard, The Dual Pistol",
	"Gambanteinn, The Wild Measure",
	"Failnaught, The Lawstring",
	"Ichaival, The Storm Quiver",
	"Caestus, The Bare Covenant",
	"Vajra Grip, The Thunder Oath",
	"Caduceus, The Dual Canon",
	"Svalinn, The Cool Ward",
	"Prydwen, The Hull of Law",
	"Gungnir, The True Strike",
	"Gandiva, The Moonstring",
	"Artemis, The Huntress Vow",
	"Kusanagi, The Storm Seeker",
	"Storm Breaker, The hand of Thor",
	"Giant Thumb, The Opposed Finger",
	"Aegis of the Fallen King",
	"Mantle of the Old Gods",
	"The Eye of the Storm",
	"Heart of the Forge",
]

# --- Materials: Old Gods (Primal / Nature / Brutal) ---
const OLD_GODS_MATERIALS: Array[String] = [
	"Bone",
	"Obsidian",
	"Flint",
	"Ironwood",
	"Jagged Tooth",
	"Cinder",
	"Bloodstone",
	"Primal Bark",
	"Basalt",
	"Petrified Ash"
]

const OLD_GODS_PREFIXES: Array[String] = [
	"Primal",
	"Feral",
	"Bloodied",
	"Stormborn",
	"Wild",
	"Rending",
	"Untamed",
	"Savage",
]

const OLD_GODS_LORE_TITLES: Array[String] = [
	"Beast Court",
	"Root Tyrant",
	"Storm Herd",
	"Blood Moon",
	"Wild Pantheon",
	"Ashen Grove",
]

# --- Materials: New Gods (Forged / Civilized / Holy) ---
const NEW_GODS_MATERIALS: Array[String] = [
	"Iron",
	"Steel",
	"Silver",
	"Sanctified Brass",
	"Polished Bronze",
	"Gilded",
	"Marble",
	"Sun-Forged Alloy",
	"Inquisitor's Steel",
	"Templar Iron"
]

const NEW_GODS_PREFIXES: Array[String] = [
	"Sanctified",
	"Polished",
	"Inquisitor's",
	"Forged",
	"Ordained",
	"Measured",
	"Lawbound",
	"Anvil",
]

const NEW_GODS_LORE_TITLES: Array[String] = [
	"Inquisitor",
	"First Forge",
	"Civic Guard",
	"High Ordinance",
	"Silver Choir",
	"Iron Canon",
]


## Build a display name for WeaponData, ShieldData, ArmorData, or AccessoryData.
static func generate_equipment_name(
	equipment: GearData,
	rarity: RarityTier,
	faction: String = ""
) -> String:
	assert(equipment != null, "ItemNameGenerator: equipment is required")
	assert(rarity != null, "ItemNameGenerator: rarity is required")

	match rarity.id:
		RarityTier.Id.TRASH, RarityTier.Id.COMMON:
			return _name_low_tier(equipment, faction)
		RarityTier.Id.MAGIC, RarityTier.Id.RARE:
			return _name_mid_tier(equipment, faction)
		RarityTier.Id.EPIC, RarityTier.Id.LEGENDARY:
			return _name_high_tier(equipment, faction)
		RarityTier.Id.MYTHIC, RarityTier.Id.UNIQUE:
			return _name_legend_tier(equipment)
		_:
			return equipment.display_name if not equipment.display_name.is_empty() else "Unknown Relic"


static func _name_legend_tier(equipment: GearData) -> String:
	return _pick(_legends_for(equipment))


static func _legends_for(equipment: GearData) -> Array[String]:
	if equipment is ShieldData:
		return LEGENDS_SHIELD
	if equipment is WeaponData:
		return _weapon_legends((equipment as WeaponData).weapon_type)
	if equipment is ArmorData:
		return LEGENDS_ARMOR
	if equipment is AccessoryData:
		return LEGENDS_ACCESSORY
	return LORE_ADAPTED_LEGENDS


static func _weapon_legends(type: WeaponData.WeaponType) -> Array[String]:
	match type:
		WeaponData.WeaponType.SWORD:
			return LEGENDS_SWORD
		WeaponData.WeaponType.GREAT_SWORD:
			return LEGENDS_GREAT_SWORD
		WeaponData.WeaponType.AXE:
			return LEGENDS_AXE
		WeaponData.WeaponType.GREAT_AXE:
			return LEGENDS_GREAT_AXE
		WeaponData.WeaponType.MACE:
			return LEGENDS_MACE
		WeaponData.WeaponType.GREAT_MACE:
			return LEGENDS_GREAT_MACE
		WeaponData.WeaponType.DAGGER:
			return LEGENDS_DAGGER
		WeaponData.WeaponType.SPEAR:
			return LEGENDS_SPEAR
		WeaponData.WeaponType.WAND:
			return LEGENDS_WAND
		WeaponData.WeaponType.BOW:
			return LEGENDS_BOW
		WeaponData.WeaponType.FIST:
			return LEGENDS_FIST
		WeaponData.WeaponType.STAFF:
			return LEGENDS_STAFF
		_:
			return LORE_ADAPTED_LEGENDS


static func _name_low_tier(equipment: GearData, faction: String) -> String:
	return "%s %s %s" % [
		_pick(CONDITIONS),
		_pick(_materials_for(faction)),
		_base_noun(equipment),
	]


static func _name_mid_tier(equipment: GearData, faction: String) -> String:
	return "%s %s %s" % [
		_pick(_prefixes_for(faction, equipment)),
		_pick(_materials_for(faction)),
		_base_noun(equipment),
	]


static func _name_high_tier(equipment: GearData, faction: String) -> String:
	var noun: String = _base_noun(equipment)
	if equipment is ShieldData:
		noun = _pick(PROTECTIVE_NOUNS)
	return "%s of the %s" % [noun, _pick(_lore_titles_for(faction))]


static func _base_noun(equipment: GearData) -> String:
	if equipment is WeaponData:
		return _weapon_noun((equipment as WeaponData).weapon_type)
	if equipment is ShieldData:
		return "Shield"
	if equipment is ArmorData:
		return _armor_noun((equipment as ArmorData).armor_slot)
	if equipment is AccessoryData:
		return _accessory_noun((equipment as AccessoryData).accessory_type)
	return "Gear"


static func _armor_noun(slot: ArmorData.ArmorSlot) -> String:
	match slot:
		ArmorData.ArmorSlot.HELMET:
			return "Helmet"
		ArmorData.ArmorSlot.CHEST:
			return "Chestguard"
		ArmorData.ArmorSlot.GLOVES:
			return "Gauntlets"
		ArmorData.ArmorSlot.BOOTS:
			return "Boots"
		_:
			return "Armor"


static func _accessory_noun(type: AccessoryData.AccessoryType) -> String:
	match type:
		AccessoryData.AccessoryType.RING:
			return _pick(["Ring", "Signet"])
		AccessoryData.AccessoryType.NECKLACE:
			return _pick(["Necklace", "Amulet"])
		_:
			return "Accessory"


static func _weapon_noun(type: WeaponData.WeaponType) -> String:
	match type:
		WeaponData.WeaponType.SWORD: return "Sword"
		WeaponData.WeaponType.GREAT_SWORD: return "Great Sword"
		WeaponData.WeaponType.AXE: return "Axe"
		WeaponData.WeaponType.GREAT_AXE: return "Great Axe"
		WeaponData.WeaponType.MACE: return "Mace"
		WeaponData.WeaponType.GREAT_MACE: return "Great Mace"
		WeaponData.WeaponType.DAGGER: return "Dagger"
		WeaponData.WeaponType.SPEAR: return "Spear"
		WeaponData.WeaponType.WAND: return "Wand"
		WeaponData.WeaponType.BOW: return "Bow"
		WeaponData.WeaponType.FIST: return "Fist"
		WeaponData.WeaponType.STAFF: return "Staff"
		_: return "Weapon"


static func _materials_for(faction: String) -> Array[String]:
	match faction:
		FACTION_OLD_GODS:
			return OLD_GODS_MATERIALS
		FACTION_NEW_GODS:
			return NEW_GODS_MATERIALS
		_:
			return _merged(OLD_GODS_MATERIALS, NEW_GODS_MATERIALS)


static func _prefixes_for(faction: String, equipment: GearData) -> Array[String]:
	var pool: Array[String] = CRAFTING_PREFIXES.duplicate()
	match faction:
		FACTION_OLD_GODS:
			pool.append_array(OLD_GODS_PREFIXES)
		FACTION_NEW_GODS:
			pool.append_array(NEW_GODS_PREFIXES)
		_:
			pool.append_array(OLD_GODS_PREFIXES)
			pool.append_array(NEW_GODS_PREFIXES)

	if equipment is WeaponData:
		var weapon: WeaponData = equipment as WeaponData
		if weapon.damage_type == WeaponData.DamageType.ELEMENTAL:
			pool.append_array(["Sparking", "Ember", "Frosted", "Stormlit", "Arcane"])
		elif weapon.damage_type == WeaponData.DamageType.BLUNT:
			pool.append_array(["Crushing", "Weighted", "Sundering"])

	return pool


static func _lore_titles_for(faction: String) -> Array[String]:
	match faction:
		FACTION_OLD_GODS:
			return _merged(LORE_TITLES, OLD_GODS_LORE_TITLES)
		FACTION_NEW_GODS:
			return _merged(LORE_TITLES, NEW_GODS_LORE_TITLES)
		_:
			return _merged(LORE_TITLES, _merged(OLD_GODS_LORE_TITLES, NEW_GODS_LORE_TITLES))


static func _pick(array: Array[String]) -> String:
	if array.is_empty():
		return "Unknown"
	return array[randi() % array.size()]


static func _merged(arr1: Array[String], arr2: Array[String]) -> Array[String]:
	var res: Array[String] = arr1.duplicate()
	res.append_array(arr2)
	return res