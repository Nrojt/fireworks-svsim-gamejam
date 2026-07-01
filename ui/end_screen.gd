class_name EndScreen
extends CanvasLayer
# End-of-round overlay. The whole layout lives in end_screen.tscn (accessed via
# %unique names). It listens for Events.round_ended to populate itself, and the
# restart button reloads the scene.

@onready var title: Label = %Title
@onready var breakdown: Label = %Breakdown
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	Events.round_ended.connect(show_result)

func show_result(won: bool, money_leftover: int, obstacle_points: int, total: int, obstacles_destroyed: int, obstacles_total: int) -> void:
	if title != null:
		title.text = "YOU WIN!" if won else "GAME OVER"
		title.add_theme_color_override("font_color", Color(0.3, 1, 0.4) if won else Color(1, 0.4, 0.4))
	if breakdown != null:
		breakdown.text = "Destroyed: %d / %d  (%d pts)\nMoney left: $%d\nScore: %d" % [obstacles_destroyed, obstacles_total, obstacle_points, money_leftover, total]
	visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
