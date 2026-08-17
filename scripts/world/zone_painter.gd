class_name ZonePainter
extends RefCounted

## Paints placeholder TileMapLayer cells and axis-aligned wall colliders.


static func fill(layer: TileMapLayer, size: Vector2i, atlas: Vector2i) -> void:
	for y in size.y:
		for x in size.x:
			layer.set_cell(Vector2i(x, y), PlaceholderTileset.SOURCE_ID, atlas)


static func rect(
	layer: TileMapLayer,
	from_cell: Vector2i,
	to_cell: Vector2i,
	atlas: Vector2i
) -> void:
	var min_x: int = mini(from_cell.x, to_cell.x)
	var max_x: int = maxi(from_cell.x, to_cell.x)
	var min_y: int = mini(from_cell.y, to_cell.y)
	var max_y: int = maxi(from_cell.y, to_cell.y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			layer.set_cell(Vector2i(x, y), PlaceholderTileset.SOURCE_ID, atlas)


static func add_wall_body(parent: Node2D, pixel_rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = pixel_rect.position
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = pixel_rect.size
	shape_node.shape = rect
	shape_node.position = pixel_rect.size * 0.5
	body.add_child(shape_node)
	parent.add_child(body)


static func tile_rect_to_pixels(from_cell: Vector2i, to_cell: Vector2i) -> Rect2:
	var tile: int = GameConstants.TILE_SIZE
	var min_x: int = mini(from_cell.x, to_cell.x)
	var max_x: int = maxi(from_cell.x, to_cell.x)
	var min_y: int = mini(from_cell.y, to_cell.y)
	var max_y: int = maxi(from_cell.y, to_cell.y)
	return Rect2(
		Vector2(min_x * tile, min_y * tile),
		Vector2((max_x - min_x + 1) * tile, (max_y - min_y + 1) * tile)
	)
