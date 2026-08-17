class_name PlaceholderTileset
extends RefCounted

## Runtime 16×16 atlas for top-down prototype maps (no 3D art).

const SOURCE_ID: int = 0

const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)
const WALL := Vector2i(2, 0)
const FLOOR := Vector2i(3, 0)
const PATH := Vector2i(4, 0)
const RIFT := Vector2i(5, 0)

const _COLORS: Array[Color] = [
	Color(0.24, 0.36, 0.22, 1.0),
	Color(0.42, 0.33, 0.24, 1.0),
	Color(0.16, 0.16, 0.20, 1.0),
	Color(0.32, 0.27, 0.22, 1.0),
	Color(0.55, 0.45, 0.32, 1.0),
	Color(0.28, 0.16, 0.34, 1.0),
]


static func build() -> TileSet:
	var tile_size: int = GameConstants.TILE_SIZE
	var image := Image.create(tile_size * _COLORS.size(), tile_size, false, Image.FORMAT_RGBA8)
	for i in _COLORS.size():
		_fill_tile(image, i, tile_size, _COLORS[i])
	var texture := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(tile_size, tile_size)
	for i in _COLORS.size():
		atlas.create_tile(Vector2i(i, 0))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)
	tileset.add_source(atlas, SOURCE_ID)
	return tileset


static func _fill_tile(image: Image, index: int, tile_size: int, color: Color) -> void:
	var origin_x: int = index * tile_size
	for y in tile_size:
		for x in tile_size:
			var shade: float = 1.0
			if x == 0 or y == 0 or x == tile_size - 1 or y == tile_size - 1:
				shade = 0.82
			elif int((x + y) / 4.0) % 2 == 0:
				shade = 0.94
			image.set_pixel(origin_x + x, y, Color(color.r * shade, color.g * shade, color.b * shade, 1.0))
