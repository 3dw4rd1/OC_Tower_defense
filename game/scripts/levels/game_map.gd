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
var _preview_tower: Node2D = null


func _ready() -> void:
	_build_tileset()
	_fill_ground()


func set_towers_container(container: Node2D) -> void:
	_towers_container = container


func select_tower_type(tower_type: String) -> void:
	selected_tower_type = tower_type
	_refresh_preview()


func cancel_placement() -> void:
	_cancel_selection()


func _cancel_selection() -> void:
	selected_tower_type = ""
	if _preview_tower:
		_preview_tower.queue_free()
		_preview_tower = null
	var hud: Node = get_parent().get_node_or_null("HUD")
	if hud and hud.has_method("set_selected_tower_button"):
		hud.set_selected_tower_button("")


func _refresh_preview() -> void:
	# Remove old preview
	if _preview_tower:
		_preview_tower.queue_free()
		_preview_tower = null
	if selected_tower_type.is_empty():
		return
	# Spawn new ghost preview
	var scene_path: String = TOWER_SCENES.get(selected_tower_type, "") as String
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path)
	_preview_tower = packed.instantiate() as Node2D
	_preview_tower.modulate = Color(1.0, 1.0, 1.0, 0.5)
	# Add to scene first so _ready() runs and @onready vars are set
	add_child(_preview_tower)
	# Disable combat processing after _ready() has initialised the node
	_preview_tower.set_process(false)
	_preview_tower.set_physics_process(false)
	var range_area := _preview_tower.get_node_or_null("RangeArea") as Area2D
	if range_area:
		range_area.monitoring = false
		range_area.monitorable = false
	_preview_tower.show_range_indicator()


func _is_tile_valid(tile_pos: Vector2i) -> bool:
	if tile_pos.x < 0 or tile_pos.x >= GRID_COLS or tile_pos.y < 0 or tile_pos.y >= GRID_ROWS:
		return false
	if tile_pos == BASE_TILE:
		return false
	if TerrainManager.is_obstacle(tile_pos):
		return false
	if _placed_tiles.has(tile_pos):
		return false
	var cost: int = TOWER_COSTS.get(selected_tower_type, 0) as int
	if GameManager.gold < cost:
		return false
	return true


func _process(_delta: float) -> void:
	if _preview_tower == null:
		return
	var world_pos: Vector2 = get_global_mouse_position()
	var tile_pos: Vector2i = PathfindingManager.world_to_tile(world_pos)
	_preview_tower.global_position = PathfindingManager.tile_to_world(tile_pos)
	# Tint ghost based on placement validity
	if _is_tile_valid(tile_pos):
		_preview_tower.modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		_preview_tower.modulate = Color(1.0, 0.3, 0.3, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	# Cancel with ESC
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE and not selected_tower_type.is_empty():
			_cancel_selection()
			return
	# Cancel with right-click
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and not selected_tower_type.is_empty():
			_cancel_selection()
			return
	# Place tower with left-click
	if not event is InputEventMouseButton:
		return
	var lmb: InputEventMouseButton = event as InputEventMouseButton
	if not lmb.pressed or lmb.button_index != MOUSE_BUTTON_LEFT:
		return
	if selected_tower_type.is_empty():
		return

	var world_pos: Vector2 = get_global_mouse_position()
	var tile_pos: Vector2i = PathfindingManager.world_to_tile(world_pos)

	if not _is_tile_valid(tile_pos):
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
	var cost: int = TOWER_COSTS.get(selected_tower_type, 0) as int
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

	# Clear selection after successful placement
	_cancel_selection()


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
