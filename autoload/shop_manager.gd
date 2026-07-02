extends Node
# Autoload singleton. Holds the player's money, the shop catalog, and the
# currently selected firework type. Both the ShopUI and PlacementController
# read/write through here.

signal money_changed(new_amount: int)
signal selection_changed(selected: FireworkResource)

const _BLUE_CRYSTAL = preload("uid://4p4kt3x6nn11")
const _GREEN_CRYSTAL = preload("uid://6nuvhw0ltch5")
const _ORANGE_CRYSTAL = preload("uid://b0wiovfpg75dy")
const _WHITE_CRYSTAL = preload("uid://bn30l0b6etth")
const _BLUE_EXPLOSION = preload("uid://bri31g47pvt8s")

var available_fireworks: Array[FireworkResource] = [_BLUE_CRYSTAL, _GREEN_CRYSTAL, _ORANGE_CRYSTAL, _WHITE_CRYSTAL, _BLUE_EXPLOSION]
var _money: int = 0
var _selected: FireworkResource = null

func _ready() -> void:
	if available_fireworks.size() > 0:
		_selected = available_fireworks[0]
	selection_changed.emit(_selected)

# Called by the level (GameMain) when it loads, with that level's budget.
func start_level(starting_money: int) -> void:
	_money = max(0, starting_money)
	if available_fireworks.size() > 0:
		_selected = available_fireworks[0]
	money_changed.emit(_money)
	selection_changed.emit(_selected)

func get_money() -> int:
	return _money

func get_selected() -> FireworkResource:
	return _selected

func select(resource: FireworkResource) -> void:
	if _selected != resource:
		_selected = resource
		selection_changed.emit(_selected)

func can_afford(cost: int) -> bool:
	return _money >= cost

func spend(cost: int) -> void:
	_money = max(0, _money - cost)
	money_changed.emit(_money)

func refund(cost: int) -> void:
	_money += cost
	money_changed.emit(_money)
