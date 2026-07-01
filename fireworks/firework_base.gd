class_name FireworkBase
extends Node2D
# A firework on the grid. Lifecycle: PLACED -> FLYING -> EXPLODED.

enum State { PLACED, FLYING, EXPLODED }

@export var resource: FireworkResource

@onready var fireworkSprite: AnimatedSprite2D = %FireworkExplosionSprite

var state: State = State.PLACED
var placed_cell: Vector2i = Vector2i(-1, -1)
var grid_manager: GridManager = null

var _fly_time_remaining: float = 0.0
var _flight_direction: Vector2 = Vector2.UP

func _ready() -> void:
	_show_idle()

func _process(delta: float) -> void:
	if state == State.FLYING:
		position += _flight_direction * _get_fly_speed() * delta
		_fly_time_remaining -= delta
		if _check_impact() or _fly_time_remaining <= 0.0:
			_explode()

func _show_idle() -> void:
	if fireworkSprite == null:
		return
	fireworkSprite.show()
	fireworkSprite.stop()

func ignite() -> void:
	if state != State.PLACED:
		return
	Events.firework_ignited.emit()
	# Static firework (fly_time <= 0): skip flight and explode on the spot.
	if _get_fly_time() <= 0.0:
		_explode()
		return
	state = State.FLYING
	_flight_direction = Vector2.UP.rotated(rotation)  # UP == "forward" at rotation 0
	_fly_time_remaining = _get_fly_time()
	queue_redraw()

func _explode() -> void:
	if state == State.EXPLODED:
		return
	state = State.EXPLODED
	queue_redraw()
	# Propagate the chain: any still-placed firework inside the blast ignites.
	_ignite_neighbors_in_radius()
	# Damage every obstacle inside the blast.
	_damage_obstacles_in_radius()
	if fireworkSprite != null:
		fireworkSprite.show()
		fireworkSprite.play()
	Events.firework_exploded.emit()

func _ignite_neighbors_in_radius() -> void:
	if grid_manager == null:
		return
	var explosion_radius: float = _get_explosion_radius()
	for firework in grid_manager.get_fireworks():
		if firework is FireworkBase and firework.state == State.PLACED:
			if position.distance_to(firework.position) <= explosion_radius:
				grid_manager.remove_at(firework.placed_cell)
				firework.ignite()

func _damage_obstacles_in_radius() -> void:
	if grid_manager == null:
		return
	var explosion_radius: float = _get_explosion_radius()
	var damage: int = _get_damage()
	for obstacle in grid_manager.get_obstacles():
		if is_instance_valid(obstacle) and position.distance_to(obstacle.position) <= explosion_radius:
			obstacle.take_damage(damage)

# True if this flying firework has entered a solid cell (a placed firework or an
# obstacle) — i.e. it bumped into something.
func _check_impact() -> bool:
	if grid_manager == null:
		return false
	var current_cell: Vector2i = grid_manager.world_to_cell(position)
	return grid_manager.is_valid_cell(current_cell) and grid_manager.is_blocked(current_cell)

func _get_fly_time() -> float:
	if resource != null:
		return resource.fly_time  # 0.0 means a static firework (no flight)
	push_error("Firework has no resource.")
	return 0.0

func _get_fly_speed() -> float:
	if resource != null and resource.fly_speed > 0.0:
		return resource.fly_speed
	push_error("Firework resource missing fly_speed, using default.")
	return 0.0

func _get_explosion_radius() -> float:
	if resource != null and resource.explosion_radius > 0.0:
		return resource.explosion_radius
	push_error("Firework resource missing explosion_radius, using default.")
	return 0.0

func _get_damage() -> int:
	if resource != null and resource.damage > 0:
		return resource.damage
	push_error("Firework resource missing damage.")
	return 0

# Scales the node so its first sprite frame fits inside one grid cell.
func fit_to_cell(cell_size: int) -> void:
	if fireworkSprite == null or fireworkSprite.sprite_frames == null:
		return
	var animation_name: StringName = fireworkSprite.animation
	if not fireworkSprite.sprite_frames.has_animation(animation_name):
		var animation_names: PackedStringArray = fireworkSprite.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			return
		animation_name = StringName(animation_names[0])
	var frame_texture: Texture2D = fireworkSprite.sprite_frames.get_frame_texture(animation_name, 0)
	if frame_texture == null:
		return
	var max_dimension: float = float(max(frame_texture.get_width(), frame_texture.get_height()))
	if max_dimension <= 0.0:
		return
	scale = Vector2.ONE * (float(cell_size) / max_dimension)

# Draws an aim arrow.
# TODO: change for a firework sprite?
func _draw() -> void:
	if state == State.EXPLODED:
		return
	if _get_fly_time() <= 0.0:
		return  # static firework has no aim direction
	var arrow_color: Color = Color(1, 0.9, 0.3, 0.9)
	var arrow_length: float = 60.0
	var arrow_width: float = 4.0
	var tip: Vector2 = Vector2(0, -arrow_length)
	draw_line(Vector2.ZERO, tip, arrow_color, arrow_width)
	draw_line(tip, Vector2(-8, -arrow_length + 14), arrow_color, arrow_width)
	draw_line(tip, Vector2(8, -arrow_length + 14), arrow_color, arrow_width)

func _on_firework_sprite_animation_finished() -> void:
	if fireworkSprite != null:
		fireworkSprite.hide()
	state = State.EXPLODED
	queue_free()
