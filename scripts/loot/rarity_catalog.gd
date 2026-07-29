class_name RarityCatalog
extends RefCounted

## Loads gear RarityTier definitions from data/rarities/.
## Card rarity stays on CardData — do not use this for cards.

const RARITY_DIR: String = "res://data/rarities/"

const PATHS: Dictionary = {
	RarityTier.Id.TRASH: RARITY_DIR + "01_trash.tres",
	RarityTier.Id.COMMON: RARITY_DIR + "02_common.tres",
	RarityTier.Id.MAGIC: RARITY_DIR + "03_magic.tres",
	RarityTier.Id.RARE: RARITY_DIR + "04_rare.tres",
	RarityTier.Id.EPIC: RARITY_DIR + "05_epic.tres",
	RarityTier.Id.LEGENDARY: RARITY_DIR + "06_legendary.tres",
	RarityTier.Id.MYTHIC: RARITY_DIR + "07_mythic.tres",
	RarityTier.Id.UNIQUE: RARITY_DIR + "08_unique.tres",
}

static var _cache: Dictionary = {}


static func get_tier(id: RarityTier.Id) -> RarityTier:
	if _cache.has(id):
		return _cache[id] as RarityTier
	var path: String = PATHS[id]
	var tier: RarityTier = load(path) as RarityTier
	assert(tier != null, "Missing RarityTier at %s" % path)
	_cache[id] = tier
	return tier


static func all_tiers() -> Array[RarityTier]:
	var result: Array[RarityTier] = []
	for id: RarityTier.Id in PATHS.keys():
		result.append(get_tier(id))
	return result


static func standard_drop_tiers() -> Array[RarityTier]:
	var result: Array[RarityTier] = []
	for tier: RarityTier in all_tiers():
		if tier.is_standard_drop:
			result.append(tier)
	return result
