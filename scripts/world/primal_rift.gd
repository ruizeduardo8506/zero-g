extends Node2D

## Small 2D rift zone for recruiting Seluc. Encounters stay 2D.

const MAP_SIZE := Vector2i(20, 16)


func _ready() -> void:
	var ground: TileMapLayer = %Ground
	ground.tile_set = PlaceholderTileset.build()
	ZonePainter.fill(ground, MAP_SIZE, PlaceholderTileset.RIFT)
	ZonePainter.rect(ground, Vector2i(1, 1), Vector2i(18, 14), PlaceholderTileset.FLOOR)
	_add_walls()
	%ExitPortal.interacted.connect(_on_exit)
	%SelucNpc.interacted.connect(_on_seluc)
	%SelucNpc.visible = not PartyManager.is_recruited(PartyManager.SELUC)
	%SelucNpc.monitoring = %SelucNpc.visible
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.exploration_scene = GameManager.RIFT_SCENE


func _add_walls() -> void:
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(1, 1), Vector2i(18, 1)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(1, 1), Vector2i(1, 14)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(18, 1), Vector2i(18, 14)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(1, 14), Vector2i(18, 14)))


func _on_exit() -> void:
	GameManager.enter_overworld(Vector2(560, 112))


func _on_seluc() -> void:
	if PartyManager.recruit(PartyManager.SELUC):
		%SelucNpc.visible = false
		%SelucNpc.monitoring = false
		SaveManager.save_game()
