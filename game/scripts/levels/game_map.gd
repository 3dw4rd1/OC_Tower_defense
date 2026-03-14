extends TileMap

const GRID_SIZE: int = 32
# Dark earthy brown — placeholder ground tile
const GROUND_COLOR: Color = Color(0.22, 0.17, 0.12, 1.0)


func _ready() -> void:
	_build_tileset()
	_fill_ground()


func _build_tileset() -> void:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(GROUND_COLOR)
	var tex: ImageTexture = ImageTexture.create_from_image(img)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i(0, 0))

	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_source(source)
	tile_set = tileset


func _fill_ground() -> void:
	for y: int in range(GRID_SIZE):
		for x: int in range(GRID_SIZE):
			set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
