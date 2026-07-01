class_name IgnitionRope
extends Node2D
# The fuse (a child node of GridManager). Placed on a clear cell by GridManager
# once obstacles are scattered; on launch (Space) it ignites fireworks on and
# adjacent to its cell, kicking off the chain reaction.

@export var grid_manager: GridManager

var cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	# Resolve the grid from the parent. Cell placement is deferred to spawn(),
	# which GridManager calls AFTER obstacles are scattered so the fuse can pick a
	# free cell (and not land under an obstacle).
	if grid_manager == null:
		var parent_node: Node = get_parent()
		if parent_node is GridManager:
			grid_manager = parent_node

# Pick a clear cell and move there. Called by GridManager once obstacles exist.
func spawn() -> void:
	if grid_manager == null:
		return
	cell = grid_manager.find_clear_fuse_cell()
	position = grid_manager.cell_center(cell)
	z_index = 50
	queue_redraw()

func ignite_neighbors() -> void:
	if grid_manager == null:
		return
	# Own cell + the full 3x3 (all 8 neighbours).
	var neighbor_offsets: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
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
