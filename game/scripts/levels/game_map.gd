extends TileMap

const GRID_COLS: int = 71
const GRID_ROWS: int = 33
# Dark green — placeholder ground tile (grass)
const GROUND_COLOR: Color = Color(0.18, 0.38, 0.18, 1.0)

const TOWER_SCENES: Dictionary = {
	"basic":  "res://scenes/towers/TowerBasic.tscn",
	"sniper": "res://scenes/towers/TowerSniper.tscn",
	"splash": "res://scenes/towers/TowerSplash.tscn",
	"slow":   "res://scenes/towers/TowerSlow.tscn",
}

const TOWER_COSTS: Dictionary = {
	"basic":  50,
	"sniper": 100,
	"splash": 120,
	"slow":   80,
}

const BASE_TILE: Vector2i = Vector2i(35, 16)

var selected_tower_type: String = ""
var _placed_tiles: Dictionary = {}
var _towers_container: Node2D = null


func _ready() -> void:
	_build_tileset()
	_fill_ground()


func set_towers_container(container: Node2D) -> void:
	_towers_container = container


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if selected_tower_type.is_empty():
		return

	var world_pos: Vector2 = get_global_mouse_position()
	var tile_pos: Vector2i = PathfindingManager.world_to_tile(world_pos)

	# Validate tile is within grid
	if tile_pos.x < 0 or tile_pos.x >= GRID_COLS or tile_pos.y < 0 or tile_pos.y >= GRID_ROWS:
		return

	# Reject placement on base tile
	if tile_pos == BASE_TILE:
		return

	# Reject placement on impassable obstacle tile
	if TerrainManager.is_obstacle(tile_pos):
		return

	# Check if tile is already occupied
	if _placed_tiles.has(tile_pos):
		return

	# Check if player can afford the tower
	var cost: int = TOWER_COSTS.get(selected_tower_type, 0) as int
	if GameManager.gold < cost:
		return

	# Place obstacle temporarily and validate path still exists (BUG-04)
	PathfindingManager.place_obstacle(tile_pos)
	var path_valid: bool = (
		PathfindingManager.has_valid_path(Vector2i(0, 16), BASE_TILE) or
		PathfindingManager.has_valid_path(Vector2i(16, 0), BASE_TILE)
	)

	if not path_valid:
		# Reject — restore and notify
		PathfindingManager.remove_obstacle(tile_pos)
		push_warning("Tower placement rejected: would fully block path")
		return

	# Confirm placement
	GameManager.spend_gold(cost)
	_placed_tiles[tile_pos] = true

	# Spawn tower scene
	var scene_path: String = TOWER_SCENES.get(selected_tower_type, "") as String
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var packed: PackedScene = load(scene_path)
		var tower: Node2D = packed.instantiate() as Node2D
		tower.position = PathfindingManager.tile_to_world(tile_pos)
		if _towers_container:
			_towers_container.add_child(tower)
		else:
			get_parent().add_child(tower)


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
	tileset.add_source(source)  # source_id 0 — ground
	tile_set = tileset


func _fill_ground() -> void:
	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLS):
			set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
