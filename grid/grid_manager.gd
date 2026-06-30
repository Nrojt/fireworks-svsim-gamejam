class_name GridManager
extends Node2D

@export var cell_size: int = 32
@export var columns: int = 32
@export var rows: int = 18
@export var grid_origin: Vector2 = Vector2.ZERO
@export var grid_color: Color = Color(1, 1, 1, 0.12)
@export var hover_color: Color = Color(1, 1, 1, 0.25)
@export var blocked_color: Color = Color(1, 0.35, 0.35, 0.4)

var hover_cell: Vector2i = Vector2i(-1, -1)
var _cells: Dictionary = {}

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
		var cell_color: Color = hover_color if not is_occupied(hover_cell) else blocked_color
		draw_rect(cell_rect, cell_color, true)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = world_pos - grid_origin
	var column: int = floori(local_pos.x / float(cell_size))
	var row: int = floori(local_pos.y / float(cell_size))
	return Vector2i(column, row)

func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * cell_size, cell.y * cell_size)

func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_world(cell) + Vector2(cell_size * 0.5, cell_size * 0.5)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows

func is_occupied(cell: Vector2i) -> bool:
	return _cells.has(cell)

func get_at(cell: Vector2i) -> FireworkBase:
	return _cells.get(cell)

func place(firework: FireworkBase, cell: Vector2i) -> bool:
	if not is_valid_cell(cell) or is_occupied(cell):
		return false
	firework.position = cell_center(cell)
	_cells[cell] = firework
	return true

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
