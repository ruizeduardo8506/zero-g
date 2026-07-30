extends Node

## Global game-flow controller (autoload).
## Tracks which high-level mode the game is in (menu, world, combat, etc.).

enum GameState {
	MAIN_MENU,
	EXPLORATION,
	GUILDHALL,
	COMBAT,
	CUTSCENE,
}

var current_state: GameState = GameState.MAIN_MENU


func change_state(new_state: GameState) -> void:
	current_state = new_state


func is_in_combat() -> bool:
	return current_state == GameState.COMBAT
