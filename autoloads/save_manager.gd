extends Node

## Demo save/load under user:// (progress, party, inventory, scene).

const SAVE_PATH: String = "user://zero_g_demo.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var payload := {
		"scene": GameManager.exploration_scene,
		"position_x": GameManager.last_player_position.x,
		"position_y": GameManager.last_player_position.y,
		"party": PartyManager.to_dict(),
		"inventory": InventoryManager.to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload))
	EventBus.combat_log.emit("Progress saved.")


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	PartyManager.from_dict(data.get("party", {}))
	InventoryManager.from_dict(data.get("inventory", {}))
	GameManager.exploration_scene = str(
		data.get("scene", GameManager.OVERWORLD_SCENE)
	)
	GameManager.pending_player_position = Vector2(
		float(data.get("position_x", 0.0)),
		float(data.get("position_y", 0.0)),
	)
	GameManager.has_pending_player_position = true
	return true
