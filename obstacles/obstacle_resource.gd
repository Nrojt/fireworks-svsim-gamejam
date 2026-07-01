class_name ObstacleResource
extends Resource
# Data for one obstacle type. `size` is the footprint in grid cells (e.g. 1x1 or
# 2x2). `health` is depleted by firework explosion damage; the obstacle is
# destroyed when it reaches 0.

@export_category("Obstacle Properties")
@export var name: String = "Obstacle"
@export var health: int = 20
@export var size: Vector2i = Vector2i(1, 1)
@export var points: int = 0
@export_category("Prefab")
@export var scene: PackedScene
