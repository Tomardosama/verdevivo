extends CharacterBody3D
class_name TRushPlayer

signal inventory_changed(current: int, capacity: int)
signal deposit_requested
signal trash_collected(value: int)

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var camera_min_angle: float = -80.0
@export var camera_max_angle: float = 80.0

@export_group("Inventory")
@export var bag_capacity: int = 5
@export var interaction_range: float = 5.0

var bag_count: int = 0
var bag_reward_total: int = 0
var collection_enabled: bool = true
var camera_pivot: Node3D
var game_camera: Camera3D

func _ready() -> void:
	camera_pivot = get_node_or_null("CameraPivot")
	game_camera = get_node_or_null("CameraPivot/Camera3D")
	if camera_pivot == null or game_camera == null:
		push_error("TRushPlayer: faltan CameraPivot o Camera3D.")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_create_input_actions()
	inventory_changed.emit(bag_count, bag_capacity)

func _create_input_actions() -> void:
	var actions := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"sprint": KEY_SHIFT,
		"deposit": KEY_E
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = actions[action_name]
		InputMap.action_add_event(action_name, key_event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif collection_enabled:
				_try_collect()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera_pivot:
			camera_pivot.rotation.x = clamp(
				camera_pivot.rotation.x - event.relative.y * mouse_sensitivity,
				deg_to_rad(camera_min_angle),
				deg_to_rad(camera_max_angle)
			)

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if Input.is_action_just_pressed("deposit"):
		_request_deposit()

func _try_collect() -> void:
	if bag_count >= bag_capacity or game_camera == null:
		return
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := game_camera.project_ray_origin(center)
	var ray_direction := game_camera.project_ray_normal(center)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + ray_direction * interaction_range)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target := hit.get("collider") as Node
	if target == null or not target.is_in_group("garbage"):
		return
	var value := int(target.get("trash_value"))
	var reward := int(target.get("reward_value"))
	if value <= 0 or bag_count + value > bag_capacity:
		return
	bag_count += value
	bag_reward_total += maxi(reward, 1)
	if game_camera:
		var original_fov := game_camera.fov
		var collect_tween := create_tween()
		collect_tween.tween_property(game_camera, "fov", original_fov - 3.0, 0.07)
		collect_tween.tween_property(game_camera, "fov", original_fov, 0.16)
	target.queue_free()
	inventory_changed.emit(bag_count, bag_capacity)
	trash_collected.emit(value)

func _request_deposit() -> void:
	for station in get_tree().get_nodes_in_group("recycling_station"):
		if station is Node3D and global_position.distance_to(station.global_position) <= 3.5:
			if bag_count > 0:
				deposit_requested.emit()
			return

func collect_bag_contents() -> int:
	var amount := bag_reward_total
	bag_count = 0
	bag_reward_total = 0
	inventory_changed.emit(bag_count, bag_capacity)
	return amount

func increase_capacity(amount: int) -> void:
	bag_capacity += amount
	inventory_changed.emit(bag_count, bag_capacity)
