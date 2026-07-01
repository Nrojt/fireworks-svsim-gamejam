class_name ShopUI
extends CanvasLayer
# Side panel built at runtime from ShopManager.available_fireworks. Runtime is better, since the amount of fireworks could change
# Clicking a button selects that firework type. Unaffordable buttons are disabled.

var _money_label: Label
var _buttons: Dictionary = {}

func _ready() -> void:
	layer = 10
	var background: Control = Control.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -220.0
	panel.offset_right = -10.0
	panel.offset_top = 10.0
	panel.offset_bottom = -10.0
	background.add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)

	var title: Label = Label.new()
	title.text = "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_money_label)

	column.add_child(HSeparator.new())

	# One toggle button per firework type in the catalog.
	for resource in ShopManager.available_fireworks:
		if not (resource is FireworkResource):
			continue
		var firework: FireworkResource = resource
		if firework.scene == null:
			continue
		var button: Button = Button.new()
		button.text = "%s  ($%d)" % [firework.name, firework.cost]
		button.tooltip_text = firework.description
		button.custom_minimum_size = Vector2(0, 44)
		button.toggle_mode = true
		button.pressed.connect(_on_button_pressed.bind(firework))
		column.add_child(button)
		_buttons[firework] = button

	ShopManager.money_changed.connect(_on_money_changed)
	ShopManager.selection_changed.connect(_on_selection_changed)
	_on_money_changed(ShopManager.get_money())
	_on_selection_changed(ShopManager.get_selected())

func _on_money_changed(new_amount: int) -> void:
	if _money_label != null:
		_money_label.text = "Money: $%d" % new_amount
	for resource in _buttons:
		var firework: FireworkResource = resource
		var button: Button = _buttons[resource]
		button.disabled = not ShopManager.can_afford(firework.cost)

func _on_selection_changed(_selected: FireworkResource) -> void:
	_sync_button_states()

func _on_button_pressed(resource: FireworkResource) -> void:
	ShopManager.select(resource)
	_sync_button_states()

# Keep the pressed highlight in sync with ShopManager's selection. Uses
# set_pressed_no_signal so it doesn't re-emit `pressed` and loop.
func _sync_button_states() -> void:
	var selected: FireworkResource = ShopManager.get_selected()
	for resource in _buttons:
		var button: Button = _buttons[resource]
		button.set_pressed_no_signal(resource == selected)
