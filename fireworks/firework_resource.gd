class_name FireworkResource
extends Resource

@export_category("Firework Properties")
@export var name : String = "Placeholder Firework"
@export var description : String = "This is a placeholder firework. Please replace it with a real one."
@export var cost : int = 1
@export_category("Flight Properties")
@export var fly_time : float = 0.8
@export var fly_speed : float = 300.0
@export_category("Explosion Properties")
@export var damage : int = 5
@export var explosion_radius : float = 48.0
@export_category("Prefab")
@export var scene : PackedScene
