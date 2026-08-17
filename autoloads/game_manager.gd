extends Node

## Global game-flow controller (autoload).
## Owns menu / intro / exploration / guildhall / combat scene transitions.

enum GameState {
	MAIN_MENU,
	EXPLORATION,
	GUILDHALL,
	COMBAT,
	CUTSCENE,
}

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const INTRO_SCENE: String = "res://scenes/ui/IntroNarrative.tscn"
const OVERWORLD_SCENE: String = "res://scenes/overworld/Overworld2D.tscn"
const SHACK_SCENE: String = "res://scenes/guildhall/HereticsShack.tscn"
const RIFT_SCENE: String = "res://scenes/world/PrimalRift2D.tscn"
const COMBAT_SCENE: String = "res://scenes/combat/CombatScene.tscn"
const POST_COMBAT_DELAY_SEC: float = 1.2

var current_state: GameState = GameState.MAIN_MENU
var exploration_scene: String = OVERWORLD_SCENE
## Restored onto the 2D player after combat or a loaded save.
var pending_player_position: Vector2 = Vector2.ZERO
var has_pending_player_position: bool = false
var last_player_position: Vector2 = Vector2.ZERO
var encounter_kind: String = "default"

var _transitioning: bool = false


func _ready() -> void:
	EventBus.random_encounter_triggered.connect(_on_random_encounter_triggered)
	EventBus.combat_ended.connect(_on_combat_ended)
	call_deferred("_sync_state_to_current_scene")


func change_state(new_state: GameState) -> void:
	current_state = new_state


func is_in_combat() -> bool:
	return current_state == GameState.COMBAT


func is_exploring() -> bool:
	return current_state == GameState.EXPLORATION and not _transitioning


func is_in_guildhall() -> bool:
	return current_state == GameState.GUILDHALL and not _transitioning


func start_new_game() -> void:
	PartyManager.reset()
	InventoryManager.reset()
	exploration_scene = OVERWORLD_SCENE
	has_pending_player_position = false
	pending_player_position = Vector2.ZERO
	last_player_position = Vector2.ZERO
	_change_to(INTRO_SCENE, GameState.CUTSCENE)


func continue_game() -> void:
	if not SaveManager.load_game():
		start_new_game()
		return
	var scene: String = exploration_scene
	var state: GameState = GameState.EXPLORATION
	if scene == SHACK_SCENE:
		state = GameState.GUILDHALL
	_change_to(scene, state)


func finish_intro() -> void:
	exploration_scene = OVERWORLD_SCENE
	_change_to(OVERWORLD_SCENE, GameState.EXPLORATION)


func enter_overworld(spawn: Vector2 = Vector2.ZERO) -> void:
	if spawn != Vector2.ZERO:
		pending_player_position = spawn
		has_pending_player_position = true
	exploration_scene = OVERWORLD_SCENE
	_change_to(OVERWORLD_SCENE, GameState.EXPLORATION)


func enter_guildhall(spawn: Vector2 = Vector2.ZERO) -> void:
	_capture_player_position()
	if spawn != Vector2.ZERO:
		pending_player_position = spawn
		has_pending_player_position = true
	exploration_scene = SHACK_SCENE
	_change_to(SHACK_SCENE, GameState.GUILDHALL)


func enter_rift(spawn: Vector2 = Vector2.ZERO) -> void:
	_capture_player_position()
	if spawn != Vector2.ZERO:
		pending_player_position = spawn
		has_pending_player_position = true
	exploration_scene = RIFT_SCENE
	_change_to(RIFT_SCENE, GameState.EXPLORATION)


func go_to_main_menu() -> void:
	_change_to(MAIN_MENU_SCENE, GameState.MAIN_MENU)


func _sync_state_to_current_scene() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var path: String = str(tree.current_scene.scene_file_path)
	if path == OVERWORLD_SCENE or path == RIFT_SCENE:
		change_state(GameState.EXPLORATION)
		exploration_scene = path
	elif path == SHACK_SCENE:
		change_state(GameState.GUILDHALL)
		exploration_scene = path
	elif path == COMBAT_SCENE:
		change_state(GameState.COMBAT)
	elif path == MAIN_MENU_SCENE:
		change_state(GameState.MAIN_MENU)
	elif path == INTRO_SCENE:
		change_state(GameState.CUTSCENE)


func _on_random_encounter_triggered() -> void:
	if _transitioning or current_state == GameState.COMBAT:
		return
	encounter_kind = "rift" if exploration_scene == RIFT_SCENE else "default"
	_capture_player_position()
	_enter_combat()


func _capture_player_position() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var player: Node = tree.get_first_node_in_group("overworld_player")
	if player == null and tree.current_scene != null:
		player = tree.current_scene.get_node_or_null("%Player")
	if player is Node2D:
		pending_player_position = (player as Node2D).global_position
		last_player_position = pending_player_position
		has_pending_player_position = true
	if tree.current_scene != null:
		var path: String = str(tree.current_scene.scene_file_path)
		if path == OVERWORLD_SCENE or path == SHACK_SCENE or path == RIFT_SCENE:
			exploration_scene = path


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


func _on_combat_ended(_victory: bool) -> void:
	if _transitioning:
		return
	_transitioning = true
	if _victory:
		EventBus.combat_log.emit("Victory! Returning…")
	else:
		EventBus.combat_log.emit("Defeated… Returning.")
	await get_tree().create_timer(POST_COMBAT_DELAY_SEC).timeout
	_return_from_combat()


func _return_from_combat() -> void:
	if CombatStateMachine.has_method("reset"):
		CombatStateMachine.reset()
	var scene: String = exploration_scene
	var state: GameState = GameState.EXPLORATION
	if scene == SHACK_SCENE:
		state = GameState.GUILDHALL
	_change_to(scene, state)


func _change_to(scene_path: String, state: GameState) -> void:
	_transitioning = true
	change_state(state)
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("GameManager: failed to load %s (%s)" % [scene_path, error_string(err)])
	_transitioning = false
