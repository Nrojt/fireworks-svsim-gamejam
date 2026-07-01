class_name PlacementController
extends Node2D
# Player input -> grid actions. Reads the selected firework type and the
# player's money from the ShopManager autoload.
#   LMB: place   RMB: remove (refunds)   wheel / Q-E: rotate   Space: ignite rope

@export var grid_manager: GridManager
@export var rotation_step_degrees: float = 15.0

var _ghost: FireworkBase = null
var _current_rotation: float = 0.0  # aim applied to the NEXT placement (radians)

func _ready() -> void:
	if grid_manager == null:
		var parent_node: Node = get_parent()
		if parent_node is GridManager:
			grid_manager = parent_node
	ShopManager.selection_changed.connect(_on_selection_changed)
	_rebuild_ghost()

func _on_selection_changed(_selected: FireworkResource) -> void:
	_rebuild_ghost()

# The semi-transparent preview following the cursor; rebuilt on selection change.
func _rebuild_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	var selected: FireworkResource = ShopManager.get_selected()
	if selected == null or selected.scene == null or grid_manager == null:
		return
	_ghost = selected.scene.instantiate()
	_ghost.z_index = 10
	add_child(_ghost)
	_ghost.resource = selected
	_ghost.fit_to_cell(grid_manager.cell_size)
	_ghost.modulate.a = 0.5
	_ghost.visible = false

func _process(_delta: float) -> void:
	if _ghost == null or grid_manager == null:
		return
	if not grid_manager.is_active():
		_ghost.visible = false
		return
	_ghost.rotation = _current_rotation
	var mouse_position: Vector2 = get_global_mouse_position()
	var cell: Vector2i = grid_manager.world_to_cell(mouse_position)
	var selected: FireworkResource = ShopManager.get_selected()
	var affordable: bool = selected != null and ShopManager.can_afford(selected.cost)
	if grid_manager.is_valid_cell(cell):
		_ghost.visible = affordable
		_ghost.position = grid_manager.cell_center(cell)
		var blocked: bool = grid_manager.is_blocked(cell)
		if not affordable:
			_ghost.modulate = Color(0.6, 0.6, 0.6, 0.4)
		elif blocked:
			_ghost.modulate = Color(1, 0.35, 0.35, 0.6)
		else:
			_ghost.modulate = Color(1, 1, 1, 0.5)
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
	# Rotate the placed firework under the cursor if any; otherwise adjust the
	# aim used for the next placement (and the ghost).
	if grid_manager.is_valid_cell(cell) and grid_manager.is_occupied(cell):
		var firework: FireworkBase = grid_manager.get_at(cell)
		if firework != null and firework.state == FireworkBase.State.PLACED:
			firework.rotation += step
	else:
		_current_rotation = wrapf(_current_rotation + step, -PI, PI)

func _try_place() -> void:
	if grid_manager == null or not grid_manager.is_active():
		return
	var selected: FireworkResource = ShopManager.get_selected()
	if selected == null or selected.scene == null:
		return
	if not ShopManager.can_afford(selected.cost):
		return
	var cell: Vector2i = grid_manager.world_to_cell(get_global_mouse_position())
	if not grid_manager.is_valid_cell(cell) or grid_manager.is_blocked(cell):
		return
	var firework: FireworkBase = selected.scene.instantiate()
	grid_manager.add_child(firework)
	firework.resource = selected
	if not grid_manager.place(firework, cell):
		firework.queue_free()
		return
	firework.rotation = _current_rotation
	firework.fit_to_cell(grid_manager.cell_size)
	ShopManager.spend(selected.cost)
	grid_manager.queue_redraw()

func _try_remove() -> void:
	if grid_manager == null or not grid_manager.is_active():
		return
	var cell: Vector2i = grid_manager.world_to_cell(get_global_mouse_position())
	var firework: FireworkBase = grid_manager.remove_at(cell)
	if firework != null:
		# Only placed (not yet launched) fireworks can be removed, so refund.
		if firework.resource != null and firework.state == FireworkBase.State.PLACED:
			ShopManager.refund(firework.resource.cost)
		firework.queue_free()
		grid_manager.queue_redraw()

func _ignite() -> void:
	if grid_manager != null:
		grid_manager.launch()
