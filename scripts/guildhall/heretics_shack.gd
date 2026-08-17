extends Node2D

## Heretic's Shack tutorial interior: save, inventory, dispatch stub, Brynnael.

const MAP_SIZE := Vector2i(24, 18)


func _ready() -> void:
	var ground: TileMapLayer = %Ground
	ground.tile_set = PlaceholderTileset.build()
	_paint(ground)
	_add_walls()
	_wire_hotspots()
	_refresh_inventory()
	EventBus.inventory_changed.connect(_refresh_inventory)
	GameManager.change_state(GameManager.GameState.GUILDHALL)
	GameManager.exploration_scene = GameManager.SHACK_SCENE
	%BrynnaelNpc.visible = not PartyManager.is_recruited(PartyManager.BRYNNAEL)
	%BrynnaelNpc.monitoring = %BrynnaelNpc.visible


func _process(_delta: float) -> void:
	if InventoryManager.poll_dispatch():
		EventBus.combat_log.emit("Dispatch returned with wood.")
		_refresh_inventory()
	_refresh_dispatch_label()


func _paint(ground: TileMapLayer) -> void:
	ZonePainter.fill(ground, MAP_SIZE, PlaceholderTileset.WALL)
	ZonePainter.rect(ground, Vector2i(2, 2), Vector2i(21, 15), PlaceholderTileset.FLOOR)
	ZonePainter.rect(ground, Vector2i(11, 15), Vector2i(13, 16), PlaceholderTileset.PATH)


func _add_walls() -> void:
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(2, 2), Vector2i(21, 2)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(2, 2), Vector2i(2, 15)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(21, 2), Vector2i(21, 15)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(2, 15), Vector2i(10, 15)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(14, 15), Vector2i(21, 15)))


func _wire_hotspots() -> void:
	%ExitDoor.interacted.connect(_on_exit)
	%SaveBed.interacted.connect(_on_save)
	%DispatchBoard.interacted.connect(_on_dispatch)
	%Workbench.interacted.connect(_on_workbench)
	%BrynnaelNpc.interacted.connect(_on_brynnael)


func _on_exit() -> void:
	GameManager.enter_overworld(Vector2(320, 240))


func _on_save() -> void:
	GameManager.last_player_position = %Player.global_position
	SaveManager.save_game()
	EventBus.interact_prompt_changed.emit("Saved.")


func _on_dispatch() -> void:
	if InventoryManager.start_dispatch():
		EventBus.combat_log.emit("Rook dispatched to gather wood.")
		_refresh_inventory()
	else:
		EventBus.combat_log.emit("A gather mission is already running.")


func _on_workbench() -> void:
	EventBus.combat_log.emit("Workbench — card crafting comes later.")


func _on_brynnael() -> void:
	if PartyManager.recruit(PartyManager.BRYNNAEL):
		%BrynnaelNpc.visible = false
		%BrynnaelNpc.monitoring = false
		SaveManager.save_game()


func _refresh_inventory() -> void:
	%InventoryLabel.text = (
		"GOLD %d    WOOD %d    ORE %d    ROCK %d    ESSENCE %d"
		% [
			InventoryManager.gold,
			int(InventoryManager.materials.get("wood", 0)),
			int(InventoryManager.materials.get("ore", 0)),
			int(InventoryManager.materials.get("rock", 0)),
			InventoryManager.primal_essence,
		]
	)
	_refresh_dispatch_label()


func _refresh_dispatch_label() -> void:
	if InventoryManager.dispatch_active:
		%DispatchLabel.text = "DISPATCH  Rook gathering… %.0fs" % InventoryManager.dispatch_remaining_sec()
	else:
		%DispatchLabel.text = "DISPATCH  Ready — interact with the board"
