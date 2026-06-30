class_name FireworkBase
extends Node2D

enum State { PLACED, IGNITED, EXPLODED }

@export var resource: FireworkResource

@onready var fireworkSprite: AnimatedSprite2D = %FireworkExplosionSprite

var state: State = State.PLACED

func _ready() -> void:
	_show_idle()

func _show_idle() -> void:
	if fireworkSprite == null:
		return
	fireworkSprite.show()
	fireworkSprite.stop()

func ignite() -> void:
	if state != State.PLACED:
		return
	state = State.IGNITED
	if fireworkSprite != null:
		fireworkSprite.show()
		fireworkSprite.play()

func fit_to_cell(cell_size: int) -> void:
	if fireworkSprite == null or fireworkSprite.sprite_frames == null:
		return
	var animation_name: String = fireworkSprite.animation
	if animation_name == "" or not fireworkSprite.sprite_frames.has_animation(animation_name):
		var animation_names: PackedStringArray = fireworkSprite.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			return
		animation_name = animation_names[0]
	var frame_texture: Texture2D = fireworkSprite.sprite_frames.get_frame_texture(animation_name, 0)
	if frame_texture == null:
		return
	var max_dimension: float = float(max(frame_texture.get_width(), frame_texture.get_height()))
	if max_dimension <= 0.0:
		return
	scale = Vector2.ONE * (float(cell_size) / max_dimension)

func _on_firework_sprite_animation_finished() -> void:
	if fireworkSprite != null:
		fireworkSprite.hide()
	state = State.EXPLODED
