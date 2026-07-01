extends Node2D
# Level root. Per-level configuration lives here. Currently just the starting
# budget, which is pushed into the ShopManager singleton when the level loads.

@export var starting_money: int = 100

func _ready() -> void:
	ShopManager.start_level(starting_money)
