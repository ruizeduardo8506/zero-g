class_name EnemyAI
extends CombatEntity

## Simple fixed-pattern enemy for Phase 2 combat (GDD: standard enemies use fixed AI).
## Attach to an Enemy node with entity_id = "enemy".

const THINK_DELAY_SEC: float = 0.55
const LUNGE_OFFSET := Vector2(-48, 0)
const LUNGE_OUT_SEC: float = 0.08
const LUNGE_BACK_SEC: float = 0.12

@export var attack_damage: int = 5
@export var telegraph_text: String = "Enemy prepares a strike."


func _ready() -> void:
	if entity_id.is_empty():
		entity_id = "enemy"
	super._ready()


## Entry point from CombatController during ENEMY_TURN.
func take_turn(_player_target: Node = null) -> void:
	await _on_turn_started()


## Think → pick a random living party member → damage + lunge → end turn.
func _on_turn_started() -> void:
	if not is_alive():
		CombatStateMachine.end_enemy_turn()
		return

	EventBus.combat_log.emit(telegraph_text)
	await get_tree().create_timer(THINK_DELAY_SEC).timeout

	if not is_alive():
		CombatStateMachine.end_enemy_turn()
		return

	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	var living: Array[Node] = []
	for node: Node in players:
		if is_instance_valid(node) and node.has_method("is_alive") and node.call("is_alive"):
			living.append(node)

	if living.is_empty():
		EventBus.combat_log.emit("Enemy finds no targets.")
		CombatStateMachine.end_enemy_turn()
		return

	var target: Node = living[randi() % living.size()]
	if target.has_method("take_damage"):
		target.call("take_damage", attack_damage)
		var target_id: String = str(target.get("entity_id")) if "entity_id" in target else target.name
		EventBus.combat_log.emit("Enemy hits %s for %d damage." % [target_id, attack_damage])

	await _play_attack_lunge()
	CombatStateMachine.end_enemy_turn()


func _play_attack_lunge() -> void:
	var origin: Vector2 = position
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin + LUNGE_OFFSET, LUNGE_OUT_SEC)
	tween.tween_property(self, "position", origin, LUNGE_BACK_SEC)
	await tween.finished
