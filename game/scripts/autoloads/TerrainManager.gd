extends Node

const GRID_COLS: int = 71
const GRID_ROWS: int = 33
const BASE_TILE: Vector2i = Vector2i(35, 16)
# Keep this many tiles clear from every edge so spawn points are never blocked
const EDGE_BUFFER: int = 2

# Noise parameters — adjust OBSTACLE_THRESHOLD to tune coverage (~10% of full grid)
const NOISE_FREQUENCY: float = 0.10
const OBSTACLE_THRESHOLD: float = 0.22  # Perlin values above this become obstacle tiles
# Tiles within this Chebyshev radius of the base are always kept clear
const BASE_CLEAR_RADIUS: int = 5

var obstacle_tiles: Dictionary = {}
var _game_map: Node = null
var _obstacles_container: Node2D = null


func initialise(game_map: Node, obstacles_container: Node2D) -> void:
	_game_map = game_map
	_obstacles_container = obstacles_container
	_generate_obstacles()
	_validate_paths()
	_paint_obstacles()


func is_obstacle(cell: Vector2i) -> bool:
	return obstacle_tiles.has(cell)


# Removes an obstacle tile at runtime — stub ready for future mechanics (e.g. bulldozing)
func clear_obstacle_tile(cell: Vector2i) -> void:
	if not obstacle_tiles.has(cell):
		return
	obstacle_tiles.erase(cell)
	PathfindingManager.remove_obstacle(cell)


# ─── Private ──────────────────────────────────────────────────────────────────

func _generate_obstacles() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = NOISE_FREQUENCY

	for y: int in range(EDGE_BUFFER, GRID_ROWS - EDGE_BUFFER):
		for x: int in range(EDGE_BUFFER, GRID_COLS - EDGE_BUFFER):
			var cell := Vector2i(x, y)
			# Keep a clear zone around the base
			if absi(x - BASE_TILE.x) <= BASE_CLEAR_RADIUS and absi(y - BASE_TILE.y) <= BASE_CLEAR_RADIUS:
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
	for cell in obstacle_tiles.keys():
		_spawn_obstacle(cell)


func _spawn_obstacle(cell: Vector2i) -> void:
	var world_pos: Vector2 = PathfindingManager.tile_to_world(cell)

	var body := StaticBody2D.new()
	body.position = world_pos

	# Visual — 14x14 grey square centred in the tile
	var rect := ColorRect.new()
	rect.color = Color(0.7, 0.7, 0.7, 1.0)
	rect.size = Vector2(14, 14)
	rect.position = Vector2(-7, -7)
	body.add_child(rect)

	# Collision — matches visual size
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	collision.shape = shape
	body.add_child(collision)

	_obstacles_container.add_child(body)
