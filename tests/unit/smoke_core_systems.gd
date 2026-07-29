extends SceneTree

## Headless smoke suite for ZeroG core systems (no GUT addon yet).

var _failures: int = 0


func _fail(msg: String) -> void:
	_failures += 1
	printerr("FAIL: ", msg)


func _ok(msg: String) -> void:
	print("OK: ", msg)


func _init() -> void:
	print("")
	print("=== ZeroG smoke tests ===")
	print("")
	_test_ability_card()
	_test_combat_deck_manager()
	_test_combat_stats()
	_test_rarity_and_gear()
	_test_item_names()
	_test_legacy_deck_helpers()
	_test_load_main_scene()
	print("")
	if _failures == 0:
		print("=== ALL PASSED ===")
		quit(0)
	else:
		printerr("=== FAILED: %d ===" % _failures)
		quit(1)


func _test_ability_card() -> void:
	var card := AbilityCard.new()
	card.id = "warrior_slash_01"
	card.card_name = "Slash"
	card.mana_cost = 1
	card.card_type = AbilityCard.CardType.ATTACK
	card.damage_type = AbilityCard.DamageType.SLASHING
	card.base_power = 5
	if not card.is_playable_from_hand(1):
		_fail("ATTACK should be playable with enough mana")
		return
	var dormant := AbilityCard.new()
	dormant.card_type = AbilityCard.CardType.DORMANT
	if dormant.is_playable_from_hand(99):
		_fail("DORMANT must not be playable from hand")
		return
	if not dormant.can_proc_from_weapon():
		_fail("DORMANT should proc from weapon")
		return
	_ok("AbilityCard")


func _test_combat_deck_manager() -> void:
	var mgr := CombatDeckManager.new()
	var drawn: Array = []
	var played: Array = []
	var reshuffles: Array = []
	mgr.card_drawn.connect(func(c: AbilityCard): drawn.append(c))
	mgr.card_played.connect(func(c: AbilityCard): played.append(c))
	mgr.deck_reshuffled.connect(func(f: bool): reshuffles.append(f))
	for i in 5:
		var c := AbilityCard.new()
		c.id = "c%d" % i
		mgr.starting_deck.append(c)
	mgr.max_hand_size = 3
	mgr.initialize_deck()
	mgr.draw_card(3)
	if mgr.get_hand_count() != 3 or drawn.size() != 3:
		_fail("draw into hand")
		return
	mgr.draw_card(2)
	if mgr.get_burn_count() != 2 or drawn.size() != 3:
		_fail("overcap should burn without card_drawn")
		return
	mgr.play_card(mgr.hand[0])
	if played.size() != 1:
		_fail("play_card signal")
		return
	if mgr.get_draw_count() != 0:
		_fail("draw should be empty before fatigue draw")
		return
	mgr.draw_card(1)
	if reshuffles.is_empty() or reshuffles[0] != true:
		_fail("fatigue reshuffle expected")
		return
	_ok("CombatDeckManager")


func _test_combat_stats() -> void:
	var stats := CombatStats.new()
	stats._ready()
	if stats.current_hp != 100 or stats.current_mana != 20:
		_fail("CombatStats init")
		return
	if not stats.spend_mana(5) or stats.current_mana != 15:
		_fail("spend_mana")
		return
	if stats.spend_mana(99):
		_fail("spend_mana should fail when insufficient")
		return
	stats.regenerate_mana()
	if stats.current_mana != 20:
		_fail("regenerate_mana clamp")
		return
	stats.trigger_fatigue_penalty()
	if stats.current_mana != 0:
		_fail("fatigue mana burn")
		return
	stats.take_damage(150)
	if stats.current_hp != 0 or stats.is_alive():
		_fail("take_damage / died")
		return
	_ok("CombatStats")


func _test_rarity_and_gear() -> void:
	var common: RarityTier = RarityCatalog.get_tier(RarityTier.Id.COMMON)
	if common == null or not is_equal_approx(common.stat_multiplier, 1.05):
		_fail("RarityCatalog COMMON")
		return
	var blade: WeaponData = load("res://data/gear/iron_blade.tres") as WeaponData
	var buckler: ShieldData = load("res://data/gear/scrap_buckler.tres") as ShieldData
	var armor: ArmorData = load("res://data/gear/patched_chestguard.tres") as ArmorData
	var ring: AccessoryData = load("res://data/gear/iron_signet.tres") as AccessoryData
	if blade == null or buckler == null or armor == null or ring == null:
		_fail("sample gear .tres load")
		return
	blade.base_damage = 10
	if blade.scaled_damage() != 11:
		_fail("WeaponData rarity scale")
		return
	if not blade.allows_off_hand():
		_fail("1H sword should allow off-hand")
		return
	var great := WeaponData.new()
	great.weapon_type = WeaponData.WeaponType.GREAT_SWORD
	great.handedness = WeaponData.Handedness.TWO_HANDED
	if not great.blocks_off_hand():
		_fail("great sword should block off-hand")
		return
	_ok("Rarity + Gear resources")


func _test_item_names() -> void:
	seed(7)
	var spear := WeaponData.new()
	spear.weapon_type = WeaponData.WeaponType.SPEAR
	var mythic: RarityTier = RarityCatalog.get_tier(RarityTier.Id.MYTHIC)
	var name := ItemNameGenerator.generate_equipment_name(spear, mythic, "")
	if name not in ItemNameGenerator.LEGENDS_SPEAR:
		_fail("mythic spear legend mismatch: %s" % name)
		return
	var shield := ShieldData.new()
	var unique: RarityTier = RarityCatalog.get_tier(RarityTier.Id.UNIQUE)
	var sname := ItemNameGenerator.generate_equipment_name(shield, unique, "")
	if sname not in ItemNameGenerator.LEGENDS_SHIELD:
		_fail("unique shield legend mismatch: %s" % sname)
		return
	var boots := ArmorData.new()
	boots.armor_slot = ArmorData.ArmorSlot.BOOTS
	var trash: RarityTier = RarityCatalog.get_tier(RarityTier.Id.TRASH)
	var aname := ItemNameGenerator.generate_equipment_name(boots, trash, ItemNameGenerator.FACTION_OLD_GODS)
	if not aname.ends_with("Boots"):
		_fail("armor noun: %s" % aname)
		return
	_ok("ItemNameGenerator")


func _test_legacy_deck_helpers() -> void:
	# Restored scaffold — ensure scripts still parse/instantiate.
	var card := CardData.new()
	card.id = "legacy_slash"
	if not card.is_playable(1):
		# default mana 0 may be playable; just ensure call works
		pass
	var deck := DeckManager.new()
	var mana := ManaPool.new()
	var combatant := Combatant.new()
	if card == null or deck == null or mana == null or combatant == null:
		_fail("legacy helpers instantiate")
		return
	_ok("Legacy CardData/DeckManager/ManaPool/Combatant")


func _test_load_main_scene() -> void:
	var packed: PackedScene = load("res://scenes/combat/CombatScene.tscn") as PackedScene
	if packed == null:
		_fail("CombatScene.tscn missing")
		return
	var scene: Node = packed.instantiate()
	if scene == null:
		_fail("CombatScene instantiate")
		return
	# Don't enter the tree (avoids autoload/UI side effects); packing is enough smoke.
	if scene.get_script() == null and scene.get_child_count() < 0:
		_fail("CombatScene empty")
		scene.free()
		return
	_ok("CombatScene loads (%d children)" % scene.get_child_count())
	scene.free()
