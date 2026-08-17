extends Control

## Demo boot screen. New Game runs intro; Continue restores user:// save.


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	%ContinueButton.disabled = not SaveManager.has_save()
	%NewGameButton.pressed.connect(_on_new_game)
	%ContinueButton.pressed.connect(_on_continue)
	%QuitButton.pressed.connect(_on_quit)


func _on_new_game() -> void:
	GameManager.start_new_game()


func _on_continue() -> void:
	GameManager.continue_game()


func _on_quit() -> void:
	get_tree().quit()
