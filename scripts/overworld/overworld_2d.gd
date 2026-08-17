extends Node2D

## Starter outdoor zone: Heretic's Shack exterior, path, recruit + rift doors.

const MAP_SIZE := Vector2i(40, 28)
const PLAYER_SPAWN := Vector2(320, 368)


func _ready() -> void:
	var ground: TileMapLayer = %Ground
	ground.tile_set = PlaceholderTileset.build()
	_paint(ground)
	_add_walls()
	_wire_hotspots()
	GameManager.change_state(GameManager.GameState.EXPLORATION)
	GameManager.exploration_scene = GameManager.OVERWORLD_SCENE


func _paint(ground: TileMapLayer) -> void:
	ZonePainter.fill(ground, MAP_SIZE, PlaceholderTileset.GRASS)
	ZonePainter.rect(ground, Vector2i(18, 10), Vector2i(22, 26), PlaceholderTileset.PATH)
	ZonePainter.rect(ground, Vector2i(16, 22), Vector2i(24, 26), PlaceholderTileset.DIRT)
	ZonePainter.rect(ground, Vector2i(15, 6), Vector2i(25, 14), PlaceholderTileset.DIRT)
	ZonePainter.rect(ground, Vector2i(16, 7), Vector2i(24, 13), PlaceholderTileset.WALL)
	ZonePainter.rect(ground, Vector2i(17, 8), Vector2i(23, 12), PlaceholderTileset.FLOOR)
	ZonePainter.rect(ground, Vector2i(19, 12), Vector2i(21, 13), PlaceholderTileset.PATH)
	ZonePainter.rect(ground, Vector2i(32, 3), Vector2i(38, 8), PlaceholderTileset.RIFT)


func _add_walls() -> void:
	# Shack outer walls (leave south door gap).
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(16, 7), Vector2i(24, 7)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(16, 7), Vector2i(16, 13)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(24, 7), Vector2i(24, 13)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(16, 13), Vector2i(18, 13)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(22, 13), Vector2i(24, 13)))
	# Trees / rocks
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(6, 8), Vector2i(8, 10)))
	ZonePainter.add_wall_body(self, ZonePainter.tile_rect_to_pixels(Vector2i(30, 16), Vector2i(32, 18)))


func _wire_hotspots() -> void:
	%ShackDoor.interacted.connect(_on_shack_door)
	%EdwardNpc.interacted.connect(_on_edward)
	%RiftPortal.interacted.connect(_on_rift)
	%EdwardNpc.visible = not PartyManager.is_recruited(PartyManager.EDWARD)
	%EdwardNpc.monitoring = %EdwardNpc.visible


func _on_shack_door() -> void:
	GameManager.enter_guildhall(Vector2(192, 240))


func _on_edward() -> void:
	if PartyManager.recruit(PartyManager.EDWARD):
		EventBus.interact_prompt_changed.emit("")
		%EdwardNpc.visible = false
		%EdwardNpc.monitoring = false
		SaveManager.save_game()


func _on_rift() -> void:
	GameManager.enter_rift(Vector2(160, 176))
