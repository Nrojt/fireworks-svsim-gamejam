class_name ObstacleBase
extends Node2D
# A destructible obstacle occupying one or more grid cells. Loses health from
# firework explosions and is freed when health hits 0. Drawn as a placeholder
# box with a depleting health bar (swap _draw for a sprite later).

@export var resource: ObstacleResource

var occupied_cells: Array[Vector2i] = []

var _cell_size: int = 64
var _health: int = 0
var _max_health: int = 1

signal destroyed(obstacle: ObstacleBase)

func _ready() -> void:
	if resource != null:
		_health = resource.health
		_max_health = max(1, resource.health)

# Called by GridManager once it has chosen the obstacle's origin cell; records
# every covered cell and centers the node on the footprint.
func setup(manager: GridManager, origin_cell: Vector2i) -> void:
	_cell_size = manager.cell_size
	var footprint: Vector2i = resource.size if resource != null else Vector2i(1, 1)
	occupied_cells.clear()
	for dx in range(footprint.x):
		for dy in range(footprint.y):
			occupied_cells.append(origin_cell + Vector2i(dx, dy))
	var top_left: Vector2 = manager.cell_to_world(origin_cell)
	var pixel_size: Vector2 = Vector2(footprint.x * _cell_size, footprint.y * _cell_size)
	position = top_left + pixel_size * 0.5
	queue_redraw()

func take_damage(amount: int) -> void:
	if _health <= 0 or amount <= 0:
		return
	_health = max(0, _health - amount)
	queue_redraw()
	if _health <= 0:
		destroyed.emit(self)
		Events.obstacle_destroyed.emit(self)
		queue_free()

func _draw() -> void:
	var footprint: Vector2i = resource.size if resource != null else Vector2i(1, 1)
	var pixel_size: Vector2 = Vector2(footprint.x * _cell_size, footprint.y * _cell_size)
	var body_rect: Rect2 = Rect2(-pixel_size * 0.5, pixel_size)
	draw_rect(body_rect, Color(0.55, 0.38, 0.28, 0.95), true)
	draw_rect(body_rect, Color(1, 1, 1, 0.5), false, 2.0)
	var fraction: float = float(_health) / float(max(_max_health, 1))
	var bar_width: float = max(pixel_size.x - 8.0, 1.0)
	var bar_rect: Rect2 = Rect2(Vector2(-bar_width * 0.5, -pixel_size.y * 0.5 + 5.0), Vector2(bar_width * fraction, 5.0))
	draw_rect(bar_rect, Color(0.2, 0.9, 0.3), true)
