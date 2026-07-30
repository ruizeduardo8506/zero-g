extends Node

## Global game-flow controller (autoload).
## Owns exploration ↔ combat scene transitions for random encounters.

enum GameState {
	MAIN_MENU,
	EXPLORATION,
	GUILDHALL,
	COMBAT,
	CUTSCENE,
}

const OVERWORLD_SCENE: String = "res://scenes/overworld/Overworld3D.tscn"
const COMBAT_SCENE: String = "res://scenes/combat/CombatScene.tscn"
const POST_COMBAT_DELAY_SEC: float = 1.2

var current_state: GameState = GameState.MAIN_MENU

## Restored onto the overworld Player after a victorious (or finished) fight.
var pending_player_position: Vector3 = Vector3.ZERO
var has_pending_player_position: bool = false

var _transitioning: bool = false


func _ready() -> void:
	EventBus.random_encounter_triggered.connect(_on_random_encounter_triggered)
	EventBus.combat_ended.connect(_on_combat_ended)
	# Boot into exploration when the overworld is the main scene (avoids a one-frame freeze).
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene == OVERWORLD_SCENE:
		change_state(GameState.EXPLORATION)
	call_deferred("_sync_state_to_current_scene")


func change_state(new_state: GameState) -> void:
	current_state = new_state


func is_in_combat() -> bool:
	return current_state == GameState.COMBAT


func is_exploring() -> bool:
	return current_state == GameState.EXPLORATION and not _transitioning


func _sync_state_to_current_scene() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var path: String = str(tree.current_scene.scene_file_path)
	if path == OVERWORLD_SCENE:
		change_state(GameState.EXPLORATION)
	elif path == COMBAT_SCENE:
		change_state(GameState.COMBAT)


func _on_random_encounter_triggered() -> void:
	if _transitioning or current_state == GameState.COMBAT:
		return
	_save_overworld_player()
	_enter_combat()


func _save_overworld_player() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var player: Node = tree.get_first_node_in_group("overworld_player")
	if player == null and tree.current_scene != null:
		player = tree.current_scene.get_node_or_null("%Player")
	if player is Node3D:
		pending_player_position = (player as Node3D).global_position
		has_pending_player_position = true


func _enter_combat() -> void:
	_transitioning = true
	change_state(GameState.COMBAT)
	EventBus.combat_log.emit("A wild encounter appears!")
	var err: Error = get_tree().change_scene_to_file(COMBAT_SCENE)
	if err != OK:
		push_error("GameManager: failed to load combat scene (%s)" % error_string(err))
		_transitioning = false
		change_state(GameState.EXPLORATION)
		return
	_transitioning = false


func _on_combat_ended(victory: bool) -> void:
	if _transitioning:
		return
	_transitioning = true
	if victory:
		EventBus.combat_log.emit("Victory! Returning to the overworld…")
	else:
		EventBus.combat_log.emit("Defeated… Returning to the overworld.")
	await get_tree().create_timer(POST_COMBAT_DELAY_SEC).timeout
	_return_to_overworld()


func _return_to_overworld() -> void:
	change_state(GameState.EXPLORATION)
	if CombatStateMachine.has_method("reset"):
		CombatStateMachine.reset()
	var err: Error = get_tree().change_scene_to_file(OVERWORLD_SCENE)
	if err != OK:
		push_error("GameManager: failed to load overworld scene (%s)" % error_string(err))
	_transitioning = false
