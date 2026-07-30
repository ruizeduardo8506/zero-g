class_name EnemyAI
extends CombatEntity

## Simple fixed-pattern enemy for Phase 2 combat (GDD: standard enemies use fixed AI).
## Attach to an Enemy node with entity_id = "enemy".

@export var attack_damage: int = 5
@export var telegraph_text: String = "Enemy prepares a strike."

var _telegraphed_damage: int = 0


func _ready() -> void:
	if entity_id.is_empty():
		entity_id = "enemy"
	super._ready()


## Called during the enemy phase. Telegraphs next hit, then resolves last telegraph.
func take_turn(player_target: CombatEntity = null) -> void:
	if not is_alive():
		return
	if _telegraphed_damage > 0 and player_target != null and player_target.is_alive():
		player_target.take_damage(_telegraphed_damage)
		EventBus.combat_log.emit(
			"Enemy hits for %d damage." % _telegraphed_damage
		)
	_telegraphed_damage = attack_damage
	EventBus.combat_log.emit(telegraph_text)
