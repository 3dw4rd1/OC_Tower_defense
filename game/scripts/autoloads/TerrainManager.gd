extends Node

const GRID_COLS: int = 71
const GRID_ROWS: int = 33
const BASE_TILE: Vector2i = Vector2i(35, 16)
# Keep this many tiles clear from every edge so spawn points are never blocked
const EDGE_BUFFER: int = 2

# Noise parameters — adjust OBSTACLE_THRESHOLD to tune coverage (~10% of full grid)
const NOISE_SEED: int = 12345
const NOISE_FREQUENCY: float = 0.10
const OBSTACLE_THRESHOLD: float = 0.60  # Perlin values above this become obstacle tiles

var obstacle_tiles: Dictionary = {}
var _game_map: Node = null


func initialise(game_map: Node) -> void:
	print("TerrainManager.initialise() called, game_map: ", game_map)
	_game_map = game_map
	_generate_obstacles()
	print("Obstacles generated: ", obstacle_tiles.size())
	_validate_paths()
	print("Obstacles after path validation: ", obstacle_tiles.size())
	_paint_obstacles()


func is_obstacle(cell: Vector2i) -> bool:
	return obstacle_tiles.has(cell)


# Removes an obstacle tile at runtime — stub ready for future mechanics (e.g. bulldozing)
func clear_obstacle_tile(cell: Vector2i) -> void:
	if not obstacle_tiles.has(cell):
		return
	obstacle_tiles.erase(cell)
	PathfindingManager.remove_obstacle(cell)
	if _game_map:
		# Restore ground tile
		_game_map.set_cell(0, cell, 0, Vector2i(0, 0))


# ─── Private ──────────────────────────────────────────────────────────────────

func _generate_obstacles() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = NOISE_SEED
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = NOISE_FREQUENCY

	for y: int in range(EDGE_BUFFER, GRID_ROWS - EDGE_BUFFER):
		for x: int in range(EDGE_BUFFER, GRID_COLS - EDGE_BUFFER):
			var cell := Vector2i(x, y)
			if cell == BASE_TILE:
				continue
			var value: float = noise.get_noise_2d(float(x), float(y))
			if value > OBSTACLE_THRESHOLD:
				obstacle_tiles[cell] = true
				PathfindingManager.place_obstacle(cell)


func _validate_paths() -> void:
	# Three sample points per edge ensure no quarter of an edge is fully cut off.
	# Edge tiles themselves are always clear (outside EDGE_BUFFER); we validate
	# that interior terrain hasn't built a wall between the edge and the base.
	var edge_samples: Array[Vector2i] = [
		# Top edge
		Vector2i(GRID_COLS / 4,         0),
		Vector2i(GRID_COLS / 2,         0),
		Vector2i(3 * GRID_COLS / 4,     0),
		# Bottom edge
		Vector2i(GRID_COLS / 4,         GRID_ROWS - 1),
		Vector2i(GRID_COLS / 2,         GRID_ROWS - 1),
		Vector2i(3 * GRID_COLS / 4,     GRID_ROWS - 1),
		# Left edge
		Vector2i(0, GRID_ROWS / 4),
		Vector2i(0, GRID_ROWS / 2),
		Vector2i(0, 3 * GRID_ROWS / 4),
		# Right edge
		Vector2i(GRID_COLS - 1, GRID_ROWS / 4),
		Vector2i(GRID_COLS - 1, GRID_ROWS / 2),
		Vector2i(GRID_COLS - 1, 3 * GRID_ROWS / 4),
	]

	for sample: Vector2i in edge_samples:
		if not PathfindingManager.has_valid_path(sample, BASE_TILE):
			_carve_corridor(sample, BASE_TILE)


# Removes obstacle tiles along the direct Bresenham line to restore connectivity
func _carve_corridor(from: Vector2i, to: Vector2i) -> void:
	for cell: Vector2i in _bresenham_line(from, to):
		if obstacle_tiles.has(cell):
			obstacle_tiles.erase(cell)
			PathfindingManager.remove_obstacle(cell)


func _bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x0: int = from.x
	var y0: int = from.y
	var x1: int = to.x
	var y1: int = to.y
	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return cells


func _paint_obstacles() -> void:
	print("_paint_obstacles() called with ", obstacle_tiles.size(), " tiles, game_map: ", _game_map)
	if _game_map == null:
		push_error("TerrainManager._paint_obstacles(): _game_map is null — initialise() not called correctly")
		return
	for cell: Variant in obstacle_tiles.keys():
		_game_map.paint_obstacle_tile(cell as Vector2i)
	print("_paint_obstacles() complete")
