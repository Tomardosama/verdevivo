extends Node3D
class_name TRushPlayerFacingSign

@export var player_group: StringName = &"player"
@export var turn_speed: float = 12.0
var target: Node3D

func _ready() -> void:
	add_to_group("player_facing_sign")
	_find_target()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		_find_target()
		return
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var desired_yaw := readable_front_yaw(direction)
	rotation.y = lerp_angle(rotation.y, desired_yaw, clampf(delta * turn_speed, 0.0, 1.0))

static func readable_front_yaw(direction: Vector3) -> float:
	var horizontal := Vector2(direction.x, direction.z)
	if horizontal.length_squared() < 0.0001:
		return 0.0
	# Label3D reads from its local +Z face; point that face toward the player.
	return atan2(horizontal.x, horizontal.y)

func set_target(player: Node3D) -> void:
	target = player

func _find_target() -> void:
	var players := get_tree().get_nodes_in_group(player_group)
	if not players.is_empty() and players[0] is Node3D:
		target = players[0] as Node3D
