extends Area3D
class_name TrashPickup

@export_range(1, 10, 1) var trash_value: int = 1

func _ready() -> void:
	add_to_group("garbage")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
