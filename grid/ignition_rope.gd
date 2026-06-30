class_name IgnitionRope
extends Node2D

@export var grid_manager: GridManager

var cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	if grid_manager == null:
		var parent_node: Node = get_parent()
		if parent_node is GridManager:
			grid_manager = parent_node
	if grid_manager != null:
		_spawn_at_random_cell()

func _spawn_at_random_cell() -> void:
	cell = Vector2i(randi() % grid_manager.columns, randi() % grid_manager.rows)
	position = grid_manager.cell_center(cell)
	z_index = 5
	queue_redraw()

func ignite_neighbors() -> void:
	if grid_manager == null:
		return
	var neighbor_offsets: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]
	for offset in neighbor_offsets:
		var neighbor_cell: Vector2i = cell + offset
		if grid_manager.is_occupied(neighbor_cell):
			var firework: FireworkBase = grid_manager.get_at(neighbor_cell)
			if firework != null and firework.state == FireworkBase.State.PLACED:
				grid_manager.remove_at(neighbor_cell)
				firework.ignite()

func _draw() -> void:
	if grid_manager == null:
		return
	var fill_color: Color = Color(1, 0.55, 0.1, 0.85)
	var ring_color: Color = Color(1, 0.9, 0.4, 0.9)
	var radius: float = float(grid_manager.cell_size) * 0.45
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, ring_color, 2.0)
