extends Area3D
class_name TrashPickup

@export_range(1, 10, 1) var trash_value: int = 1
@export_range(1, 100, 1) var reward_value: int = 5
@export var trash_type: String = "Residuo"

func _ready() -> void:
	add_to_group("garbage")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
