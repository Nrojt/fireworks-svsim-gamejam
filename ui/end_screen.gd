class_name EndScreen
extends CanvasLayer
# End-of-round overlay shown by the GridManager once the chain settles. Reports
# the score (leftover money + destroyed-obstacle points), win/lose, and restarts
# by reloading the scene.

var _title: Label
var _breakdown: Label

func _ready() -> void:
	layer = 20
	add_to_group("end_screen")
	_build()
	visible = false

func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 230)
	center.add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	column.add_child(_title)

	_breakdown = Label.new()
	_breakdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_breakdown)

	var restart_button: Button = Button.new()
	restart_button.text = "Restart"
	restart_button.custom_minimum_size = Vector2(0, 44)
	restart_button.pressed.connect(_on_restart_pressed)
	column.add_child(restart_button)

func show_result(won: bool, money_leftover: int, obstacle_points: int, total: int, obstacles_destroyed: int, obstacles_total: int) -> void:
	if _title != null:
		_title.text = "YOU WIN!" if won else "GAME OVER"
		_title.add_theme_color_override("font_color", Color(0.3, 1, 0.4) if won else Color(1, 0.4, 0.4))
	if _breakdown != null:
		_breakdown.text = "Destroyed: %d / %d  (%d pts)\nMoney left: $%d\nScore: %d" % [obstacles_destroyed, obstacles_total, obstacle_points, money_leftover, total]
	visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
