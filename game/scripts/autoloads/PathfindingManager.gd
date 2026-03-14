extends Node

signal obstacle_changed

const GRID_SIZE: int = 32
const TILE_SIZE: int = 16

var _astar: AStar2D = AStar2D.new()


func _ready() -> void:
	_build_grid()


func _build_grid() -> void:
	# Add all grid points
	for y: int in range(GRID_SIZE):
		for x: int in range(GRID_SIZE):
			var id: int = _tile_to_id(Vector2i(x, y))
			_astar.add_point(id, tile_to_world(Vector2i(x, y)))

	# Connect 4-directional neighbours
	for y: int in range(GRID_SIZE):
		for x: int in range(GRID_SIZE):
			var id: int = _tile_to_id(Vector2i(x, y))
			if x + 1 < GRID_SIZE:
				_astar.connect_points(id, _tile_to_id(Vector2i(x + 1, y)))
			if y + 1 < GRID_SIZE:
				_astar.connect_points(id, _tile_to_id(Vector2i(x, y + 1)))


func place_obstacle(tile_pos: Vector2i) -> void:
	_astar.set_point_disabled(_tile_to_id(tile_pos), true)
	obstacle_changed.emit()


func remove_obstacle(tile_pos: Vector2i) -> void:
	_astar.set_point_disabled(_tile_to_id(tile_pos), false)


func has_valid_path(from: Vector2i, to: Vector2i) -> bool:
	var path: PackedVector2Array = _astar.get_point_path(
		_tile_to_id(from), _tile_to_id(to)
	)
	return path.size() > 0


func get_path(from: Vector2i, to: Vector2i) -> Array[Vector2]:
	var raw: PackedVector2Array = _astar.get_point_path(
		_tile_to_id(from), _tile_to_id(to)
	)
	var result: Array[Vector2] = []
	for point: Vector2 in raw:
		result.append(point)
	return result


func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_SIZE + TILE_SIZE / 2,
		tile_pos.y * TILE_SIZE + TILE_SIZE / 2
	)


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)


func _tile_to_id(tile_pos: Vector2i) -> int:
	return tile_pos.y * GRID_SIZE + tile_pos.x
