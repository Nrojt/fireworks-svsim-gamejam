class_name ShopUI
extends CanvasLayer
# Side panel. The shell (panel, title, money label) is defined in shop_ui.tscn
# and accessed via %unique names; only the per-firework buttons are built in
# code, since their count depends on the catalog.

@onready var column: VBoxContainer = %Column
@onready var money_label: Label = %MoneyLabel

var _buttons: Dictionary = {}

func _ready() -> void:
	_build_buttons()
	ShopManager.money_changed.connect(_on_money_changed)
	ShopManager.selection_changed.connect(_on_selection_changed)
	_on_money_changed(ShopManager.get_money())
	_on_selection_changed(ShopManager.get_selected())

func _build_buttons() -> void:
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

func _on_money_changed(new_amount: int) -> void:
	if money_label != null:
		money_label.text = "Money: $%d" % new_amount
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
