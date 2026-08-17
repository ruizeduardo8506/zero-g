class_name CardData
extends Resource

enum BaseClass { WARRIOR, MAGE, PRIEST, ROGUE }
## Card rarity only — gear uses RarityTier / RarityCatalog under scripts/loot/.
enum Rarity { TRASH, COMMON, MAGIC, RARE, EPIC, LEGENDARY, MYTHIC, UNIQUE }
enum DamageType { NONE, SLASHING, BLUNT, ELEMENTAL }
enum CardType { ATTACK, SKILL, DORMANT }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var mana_cost: int = 0
## Raw damage dealt when the Action Resolver resolves this card (0 = non-damaging).
@export var base_damage: int = 0
## Healing applied to the caster/ally when resolved (0 = non-healing).
@export var base_heal: int = 0
## Absorb before HP (Guard).
@export var base_shield: int = 0
@export var base_class: BaseClass = BaseClass.WARRIOR
@export var rarity: Rarity = Rarity.COMMON
@export var card_type: CardType = CardType.ATTACK
@export var damage_type: DamageType = DamageType.NONE
@export var is_dormant: bool = false
@export var drains_full_mana: bool = false
@export var can_weapon_proc: bool = false


func is_playable(current_mana: int) -> bool:
	if is_dormant or card_type == CardType.DORMANT:
		return false
	if drains_full_mana:
		return current_mana > 0
	return mana_cost <= current_mana


func can_proc_from_weapon() -> bool:
	return is_dormant or card_type == CardType.DORMANT or can_weapon_proc or base_damage > 0
