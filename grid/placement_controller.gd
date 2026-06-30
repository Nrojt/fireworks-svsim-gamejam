class_name PlacementController
extends Node2D

@export var grid_manager: GridManager
@export var firework_scene: PackedScene
@export var rotation_step_degrees: float = 15.0

var _ghost: FireworkBase = null
var _current_rotation: float = 0.0

func _ready() -> void:
	if grid_manager == null:
		var parent_node: Node = get_parent()
		if parent_node is GridManager:
			grid_manager = parent_node
	if grid_manager != null and firework_scene != null:
		_create_ghost()

func _create_ghost() -> void:
	_ghost = firework_scene.instantiate()
	_ghost.z_index = 10
	add_child(_ghost)
	_ghost.fit_to_cell(grid_manager.cell_size)
	_ghost.modulate.a = 0.5
	_ghost.visible = false

func _process(_delta: float) -> void:
	if _ghost == null or grid_manager == null:
		return
	_ghost.rotation = _current_rotation
	var mouse_position: Vector2 = get_global_mouse_position()
	var cell: Vector2i = grid_manager.world_to_cell(mouse_position)
	if grid_manager.is_valid_cell(cell):
		_ghost.visible = true
		_ghost.position = grid_manager.cell_center(cell)
		var occupied: bool = grid_manager.is_occupied(cell)
		_ghost.modulate = Color(1, 1, 1, 0.5) if not occupied else Color(1, 0.35, 0.35, 0.6)
		grid_manager.set_hover(cell)
	else:
		_ghost.visible = false
		grid_manager.clear_hover()

func _unhandled_input(event: InputEvent) -> void:
	var step: float = deg_to_rad(rotation_step_degrees)
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_try_place()
			MOUSE_BUTTON_RIGHT:
				_try_remove()
			MOUSE_BUTTON_WHEEL_UP:
				_rotate(step)
			MOUSE_BUTTON_WHEEL_DOWN:
				_rotate(-step)
	elif event is InputEventKey:
		if not event.pressed:
			return
		match event.keycode:
			KEY_Q:
				_rotate(step)
			KEY_E:
				_rotate(-step)
			KEY_SPACE:
				if not event.echo:
					_ignite()

func _rotate(step: float) -> void:
	if grid_manager == null:
		return
	var cell: Vector2i = grid_manager.world_to_cell(get_global_mouse_position())
	if grid_manager.is_valid_cell(cell) and grid_manager.is_occupied(cell):
		var firework: FireworkBase = grid_manager.get_at(cell)
		if firework != null and firework.state == FireworkBase.State.PLACED:
			firework.rotation += step
	else:
		_current_rotation = wrapf(_current_rotation + step, -PI, PI)

func _try_place() -> void:
	if grid_manager == null or firework_scene == null:
		return
	var cell: Vector2i = grid_manager.world_to_cell(get_global_mouse_position())
	if not grid_manager.is_valid_cell(cell) or grid_manager.is_occupied(cell):
		return
	var firework: FireworkBase = firework_scene.instantiate()
	grid_manager.add_child(firework)
	if not grid_manager.place(firework, cell):
		firework.queue_free()
		return
	firework.rotation = _current_rotation
	firework.fit_to_cell(grid_manager.cell_size)
	grid_manager.queue_redraw()

func _try_remove() -> void:
	if grid_manager == null:
		return
	var cell: Vector2i = grid_manager.world_to_cell(get_global_mouse_position())
	var firework: FireworkBase = grid_manager.remove_at(cell)
	if firework != null:
		firework.queue_free()
		grid_manager.queue_redraw()

func _ignite() -> void:
	if grid_manager != null:
		grid_manager.ignite_from_rope()
