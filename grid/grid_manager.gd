class_name GridManager
extends Node2D
# Owns the play-field grid: cell<->world conversion, firework + obstacle
# occupancy, the grid + hover drawing, the ignition rope, obstacle scatter, and
# the round lifecycle (launch -> settle -> end screen).

const _CRATE = preload("res://obstacles/resources/crate.tres")
const _HOUSE = preload("res://obstacles/resources/house.tres")

@export var cell_size: int = 64
@export var columns: int = 16
@export var rows: int = 8
@export var grid_origin: Vector2 = Vector2.ZERO
@export var grid_color: Color = Color(1, 1, 1, 0.12)
@export var hover_color: Color = Color(1, 1, 1, 0.25)
@export var blocked_color: Color = Color(1, 0.35, 0.35, 0.4)
@export var obstacle_resources: Array[ObstacleResource] = [_CRATE, _HOUSE]
@export var obstacle_count: int = 10
@export var win_ratio: float = 0.7  # fraction of obstacles that must be destroyed to win

var hover_cell: Vector2i = Vector2i(-1, -1)
var _cells: Dictionary = {}  # Vector2i cell -> FireworkBase (PLACED ones only)
var _obstacle_cells: Dictionary = {}  # Vector2i cell -> ObstacleBase
var _obstacles: Array = []  # unique ObstacleBase instances
@onready var _rope: IgnitionRope = %IgnitionRope

# Round state.
var _launched: bool = false
var _game_ended: bool = false
var _flying_count: int = 0
var _destroyed_points: int = 0
var _obstacles_total: int = 0
var _obstacles_destroyed_count: int = 0

func _ready() -> void:
	# Scatter first, then tell the fuse child node to pick a clear cell — so it
	# never ends up hidden under an obstacle.
	_scatter_obstacles()
	_rope.spawn()
	Events.firework_ignited.connect(_on_firework_ignited)
	Events.firework_exploded.connect(_on_firework_exploded)
	Events.obstacle_destroyed.connect(_on_obstacle_destroyed)

# True while the player can still place/remove fireworks (before launch).
func is_active() -> bool:
	return not _launched and not _game_ended

func launch() -> void:
	if _game_ended or _launched:
		return
	_launched = true
	ignite_from_rope()
	_check_settled()  # handles the case where nothing was next to the fuse

func ignite_from_rope() -> void:
	if _rope != null:
		_rope.ignite_neighbors()

func _on_firework_ignited() -> void:
	_flying_count += 1

func _on_firework_exploded() -> void:
	_flying_count = max(0, _flying_count - 1)
	_check_settled()

func _on_obstacle_destroyed(obstacle: ObstacleBase) -> void:
	if obstacle.resource != null:
		_destroyed_points += obstacle.resource.points
	_obstacles_destroyed_count += 1
	unregister_obstacle(obstacle)

func _check_settled() -> void:
	if not _game_ended and _launched and _flying_count <= 0:
		_game_ended = true
		# Small delay so the final explosion animation can play out.
		get_tree().create_timer(0.8).timeout.connect(_show_end_screen)

func _show_end_screen() -> void:
	var money_leftover: int = ShopManager.get_money()
	var total: int = money_leftover + _destroyed_points
	var needed: int = int(ceil(_obstacles_total * win_ratio))
	var won: bool = _obstacles_destroyed_count >= needed
	Events.round_ended.emit(won, money_leftover, _destroyed_points, total, _obstacles_destroyed_count, _obstacles_total)

# ---- Obstacles ----

func get_obstacles() -> Array:
	return _obstacles.duplicate()

func add_obstacle(obstacle: ObstacleBase, origin_cell: Vector2i) -> void:
	add_child(obstacle)
	obstacle.setup(self, origin_cell)
	for cell in obstacle.occupied_cells:
		_obstacle_cells[cell] = obstacle
	_obstacles.append(obstacle)

func unregister_obstacle(obstacle: ObstacleBase) -> void:
	for cell in obstacle.occupied_cells:
		if _obstacle_cells.get(cell) == obstacle:
			_obstacle_cells.erase(cell)
	_obstacles.erase(obstacle)

# Scatter `obstacle_count` random obstacles, keeping the fuse area clear.
func _scatter_obstacles() -> void:
	if obstacle_resources.is_empty() or obstacle_count <= 0:
		return
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = obstacle_count * 30
	while placed < obstacle_count and attempts < max_attempts:
		attempts += 1
		var resource: ObstacleResource = obstacle_resources[randi() % obstacle_resources.size()]
		var footprint: Vector2i = resource.size
		var max_origin_x: int = columns - footprint.x
		var max_origin_y: int = rows - footprint.y
		if max_origin_x < 0 or max_origin_y < 0:
			continue
		var origin: Vector2i = Vector2i(randi() % (max_origin_x + 1), randi() % (max_origin_y + 1))
		if _can_place_obstacle(origin, footprint):
			var obstacle: ObstacleBase = resource.scene.instantiate()
			obstacle.resource = resource
			add_obstacle(obstacle, origin)
			placed += 1
	_obstacles_total = _obstacles.size()

func _can_place_obstacle(origin: Vector2i, footprint: Vector2i) -> bool:
	for dx in range(footprint.x):
		for dy in range(footprint.y):
			var cell: Vector2i = origin + Vector2i(dx, dy)
			if not is_valid_cell(cell) or is_blocked(cell):
				return false
	return true

# Pick a fuse cell where it (and its 4 neighbours) is free, so it's never hidden
# under an obstacle and the chain has room to start.
func find_clear_fuse_cell() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for column in range(columns):
		for row in range(rows):
			var cell: Vector2i = Vector2i(column, row)
			if _is_fuse_spot_clear(cell):
				candidates.append(cell)
	if candidates.is_empty():
		return Vector2i(randi() % columns, randi() % rows)
	return candidates[randi() % candidates.size()]

func _is_fuse_spot_clear(cell: Vector2i) -> bool:
	var offsets: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset in offsets:
		var neighbor: Vector2i = cell + offset
		if not is_valid_cell(neighbor) or is_blocked(neighbor):
			return false
	return true

# ---- Drawing ----

func _draw() -> void:
	var grid_width: float = columns * cell_size
	var grid_height: float = rows * cell_size
	for col_index in range(columns + 1):
		var line_x: float = grid_origin.x + col_index * cell_size
		draw_line(Vector2(line_x, grid_origin.y), Vector2(line_x, grid_origin.y + grid_height), grid_color)
	for row_index in range(rows + 1):
		var line_y: float = grid_origin.y + row_index * cell_size
		draw_line(Vector2(grid_origin.x, line_y), Vector2(grid_origin.x + grid_width, line_y), grid_color)
	if is_valid_cell(hover_cell):
		var cell_rect: Rect2 = Rect2(cell_to_world(hover_cell), Vector2(cell_size, cell_size))
		var cell_color: Color = hover_color if not is_blocked(hover_cell) else blocked_color
		draw_rect(cell_rect, cell_color, true)

# ---- Cell helpers ----

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = world_pos - grid_origin
	# floori (not int()) so positions left/above the grid map to -1 -> invalid cell.
	var column: int = floori(local_pos.x / float(cell_size))
	var row: int = floori(local_pos.y / float(cell_size))
	return Vector2i(column, row)

func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * cell_size, cell.y * cell_size)

func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(cell_size * 0.5, cell_size * 0.5)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows

# Firework occupancy only (used by chain-reaction logic).
func is_occupied(cell: Vector2i) -> bool:
	return _cells.has(cell)

# Anything solid (firework or obstacle) — used for placement + flight impact.
func is_blocked(cell: Vector2i) -> bool:
	return _cells.has(cell) or _obstacle_cells.has(cell)

func get_at(cell: Vector2i) -> FireworkBase:
	return _cells.get(cell)

func place(firework: FireworkBase, cell: Vector2i) -> bool:
	if not is_valid_cell(cell) or is_blocked(cell):
		return false
	firework.position = cell_center(cell)
	# Back-references the firework needs to fly and chain-explode later.
	firework.grid_manager = self
	firework.placed_cell = cell
	_cells[cell] = firework
	return true

func get_fireworks() -> Array:
	return _cells.values()

func remove_at(cell: Vector2i) -> FireworkBase:
	if not is_occupied(cell):
		return null
	var firework: FireworkBase = _cells[cell]
	_cells.erase(cell)
	return firework

func set_hover(cell: Vector2i) -> void:
	if cell != hover_cell:
		hover_cell = cell
		queue_redraw()

func clear_hover() -> void:
	set_hover(Vector2i(-1, -1))
