extends CharacterBody3D
class_name TRushPlayer

signal inventory_changed(current: int, capacity: int)
signal deposit_requested
signal trash_collected(value: int)
signal trash_item_collected(item: TrashPickup)
signal shop_requested
signal skill_requested
signal pause_requested
signal sleep_requested
<<<<<<< Updated upstream
signal health_changed(current: float, maximum: float)
=======
signal boss_target_changed(boss: TRushGarbageMountainBoss)
signal fruit_requested
signal cleaner_interaction_requested
signal health_changed(current_health: float, maximum_health: float)
signal health_depleted
signal took_damage(amount: float)
>>>>>>> Stashed changes

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var camera_min_angle: float = -80.0
@export var camera_max_angle: float = 80.0

@export_group("Inventory")
@export var bag_capacity: int = 5
@export var interaction_range: float = 5.0

@export_group("Health")
@export_range(40.0, 300.0, 10.0) var maximum_health: float = 100.0

var bag_count: int = 0
var bag_reward_total: int = 0
var current_health: float = 100.0
var knocked_out: bool = false
var invulnerability_time: float = 0.0
var active_fruit_boost: String = ""
var fruit_boost_time: float = 0.0
var fruit_movement_multiplier: float = 1.0
var fruit_vacuum_damage_multiplier: float = 1.0
var fruit_vacuum_range_multiplier: float = 1.0
var fruit_damage_received_multiplier: float = 1.0
var collection_enabled: bool = true
var camera_pivot: Node3D
var game_camera: Camera3D
var vacuum_unlocked: bool = false
var vacuum_radius: float = 3.2
var vacuum_pull_time: float = 0.24
var vacuum_nozzle: MeshInstance3D
var vacuum_model_root: Node3D
var vacuum_evolution_level: int = 0
var suction_flow: MeshInstance3D
var suction_rings: Array[MeshInstance3D] = []
var suction_particles: CPUParticles3D
var suction_animation_clock: float = 0.0
var cleaner_carry_mount: Node3D
var cleaner_interaction_priority: bool = false
var vacuum_active: bool = false
var suppress_deposit_input: bool = false
<<<<<<< Updated upstream
@export_group("Health")
@export var max_health: float = 100.0
var current_health: float = 100.0
=======
@export_group("Vacuum Combat")
@export var vacuum_damage_per_second: float = 22.0
var vacuum_damage_multiplier: float = 1.0
var targeted_boss: TRushGarbageMountainBoss
var boss_target_refresh_timer: float = 0.0
>>>>>>> Stashed changes

func _ready() -> void:
	camera_pivot = get_node_or_null("CameraPivot")
	game_camera = get_node_or_null("CameraPivot/Camera3D")
	if camera_pivot == null or game_camera == null:
		push_error("TRushPlayer: faltan CameraPivot o Camera3D.")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_create_input_actions()
	cleaner_carry_mount = Node3D.new()
	cleaner_carry_mount.name = "PortableCleanerCarryMount"
	cleaner_carry_mount.position = Vector3(-0.50, -0.48, -0.92)
	cleaner_carry_mount.rotation_degrees = Vector3(-5.0, 8.0, -7.0)
	game_camera.add_child(cleaner_carry_mount)
	_create_vacuum_model()
<<<<<<< Updated upstream
	current_health = clampf(current_health, 0.0, max_health)
=======
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)
>>>>>>> Stashed changes
	inventory_changed.emit(bag_count, bag_capacity)
	health_changed.emit(current_health, max_health)

func _create_input_actions() -> void:
	var actions := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"sprint": KEY_SHIFT,
		"deposit": KEY_E,
		"jump": KEY_SPACE,
		"vacuum": KEY_F,
		"eat_fruit": KEY_R
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = actions[action_name]
		InputMap.action_add_event(action_name, key_event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if cleaner_interaction_priority:
			cleaner_interaction_requested.emit()
			suppress_deposit_input = true
			return
		if _try_sleep():
			return
		if _try_open_shop():
			suppress_deposit_input = true
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		skill_requested.emit()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		pause_requested.emit()
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
	_update_temporary_effects(delta)
	if knocked_out:
		velocity = Vector3.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 5.2
	var direction := (global_basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	speed *= fruit_movement_multiplier
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor() or velocity.y > 0.0:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	boss_target_refresh_timer -= delta
	if boss_target_refresh_timer <= 0.0:
		boss_target_refresh_timer = 0.12
		_refresh_boss_target()
	if Input.is_action_just_pressed("deposit") and not suppress_deposit_input:
		_request_deposit()
	if Input.is_action_just_pressed("eat_fruit"):
		fruit_requested.emit()
	suppress_deposit_input = false
	if collection_enabled and vacuum_unlocked and Input.is_action_pressed("vacuum"):
		_play_vacuum_wind(delta)
		_damage_targeted_boss(delta)
		_vacuum_collect()
	else:
		_stop_vacuum_feedback()
		if targeted_boss:
			targeted_boss.set_vacuumed(false)


func _try_open_shop() -> bool:
	for shop in get_tree().get_nodes_in_group("upgrade_shop"):
		if shop is Node3D and global_position.distance_to(shop.global_position) <= 3.0:
			shop_requested.emit()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return true
	return false

func _try_sleep() -> bool:
	for bed in get_tree().get_nodes_in_group("sleep_bed"):
		if bed is Node3D and global_position.distance_to(bed.global_position) <= 3.0:
			sleep_requested.emit()
			return true
	return false

func _create_vacuum_model() -> void:
	if vacuum_model_root and is_instance_valid(vacuum_model_root):
		vacuum_model_root.queue_free()
	var root := Node3D.new()
	root.name = "VacuumViewModel"
	root.position = Vector3(0.34, -0.32, -0.58)
	root.rotation_degrees = Vector3(4.0, -8.0, -8.0)
	game_camera.add_child(root)
	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.075
	body_mesh.bottom_radius = 0.12
	body_mesh.height = 0.62
	body.mesh = body_mesh
	body.rotation_degrees.x = 90.0
	body.position.z = 0.20
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.16, 0.22, 0.19)
	body_material.metallic = 0.35
	body.material_override = body_material
	root.add_child(body)
	vacuum_nozzle = MeshInstance3D.new()
	var nozzle_mesh := CylinderMesh.new()
	nozzle_mesh.top_radius = 0.19
	nozzle_mesh.bottom_radius = 0.075
	nozzle_mesh.height = 0.22
	vacuum_nozzle.mesh = nozzle_mesh
	vacuum_nozzle.rotation_degrees.x = 90.0
	vacuum_nozzle.position.z = -0.16
	var nozzle_material := StandardMaterial3D.new()
	nozzle_material.albedo_color = Color(0.28, 0.55, 0.39)
	nozzle_material.metallic = 0.25
	vacuum_nozzle.material_override = nozzle_material
	root.add_child(vacuum_nozzle)
	vacuum_model_root = root
	root.visible = vacuum_unlocked
	_add_vacuum_upgrade_details(root, vacuum_evolution_level)
	_build_vacuum_suction_feedback(root)

func set_vacuum_level(level: int) -> void:
	var safe_level := clampi(level, 0, 10)
	if safe_level == vacuum_evolution_level and vacuum_model_root and is_instance_valid(vacuum_model_root):
		return
	vacuum_evolution_level = safe_level
	_create_vacuum_model()

func _add_vacuum_upgrade_details(root: Node3D, level: int) -> void:
	var steel := _vacuum_material(Color(0.52, 0.63, 0.59), 0.72, 0.55)
	var brass := _vacuum_material(Color(0.82, 0.61, 0.25), 0.42, 0.82)
	var enamel := _vacuum_material(Color(0.12, 0.31, 0.25), 0.35, 0.32)
	var dark := _vacuum_material(Color(0.045, 0.08, 0.07), 0.85, 0.2)
	if level >= 1:
		_add_vacuum_part(root, _vacuum_torus(0.13, 0.20), Vector3(0.0, 0.0, -0.28), steel, Vector3(0.38, 0.38, 0.38), Vector3(PI * 0.5, 0.0, 0.0), "RimmedIntake")
	if level >= 2:
		_add_vacuum_part(root, _vacuum_box(Vector3(0.15, 0.13, 0.45)), Vector3(-0.13, 0.12, 0.18), dark, Vector3.ONE, Vector3(0.0, 0.0, -0.28), "RubberGrip")
	if level >= 3:
		_add_vacuum_part(root, _vacuum_box(Vector3(0.21, 0.23, 0.28)), Vector3(0.0, 0.13, 0.28), enamel, Vector3.ONE, Vector3.ZERO, "ReinforcedHousing")
	if level >= 4:
		_add_vacuum_part(root, _vacuum_cylinder(0.105, 0.11, 0.04), Vector3(0.0, 0.30, 0.16), steel, Vector3(1.0, 0.18, 1.0), Vector3.ZERO, "PressureGauge")
		_add_vacuum_part(root, _vacuum_box(Vector3(0.025, 0.025, 0.15)), Vector3(0.0, 0.33, 0.10), brass, Vector3.ONE, Vector3(0.0, 0.0, -0.25), "GaugeNeedle")
	if level >= 5:
		_add_vacuum_part(root, _vacuum_torus(0.105, 0.145), Vector3(0.0, 0.0, 0.12), brass, Vector3(0.75, 0.75, 0.75), Vector3(PI * 0.5, 0.0, 0.0), "GoldDriveCollar")
	if level >= 6:
		_add_vacuum_part(root, _vacuum_cylinder(0.105, 0.16, 0.29), Vector3(0.0, -0.10, 0.42), enamel, Vector3.ONE, Vector3(PI * 0.5, 0.0, 0.0), "CycloneCanister")
		_add_vacuum_part(root, _vacuum_torus(0.10, 0.14), Vector3(0.0, -0.10, 0.28), brass, Vector3.ONE, Vector3(PI * 0.5, 0.0, 0.0), "CanisterSeal")
	if level >= 7:
		_add_vacuum_part(root, _vacuum_torus(0.075, 0.105), Vector3(0.0, 0.31, 0.30), brass, Vector3(0.62, 0.62, 0.62), Vector3(PI * 0.5, 0.0, 0.0), "CompassBezel")
		_add_vacuum_part(root, _vacuum_box(Vector3(0.018, 0.13, 0.02)), Vector3(0.0, 0.31, 0.30), steel, Vector3.ONE, Vector3(0.0, 0.0, -0.2), "CompassNeedle")
	if level >= 8:
		for side in [-1.0, 1.0]:
			_add_vacuum_part(root, _vacuum_box(Vector3(0.045, 0.20, 0.40)), Vector3(side * 0.135, -0.02, 0.36), steel, Vector3.ONE, Vector3(0.0, 0.0, side * 0.12), "TwinReinforcementRail")
	if level >= 9:
		_add_vacuum_part(root, _vacuum_torus(0.17, 0.215), Vector3(0.0, 0.0, -0.30), brass, Vector3.ONE * 0.46, Vector3(PI * 0.5, 0.0, 0.0), "CeramicNozzleRing")
	if level >= 10:
		_add_vacuum_part(root, _vacuum_box(Vector3(0.17, 0.09, 0.12)), Vector3(0.0, 0.24, -0.04), brass, Vector3.ONE, Vector3(-0.18, 0.0, 0.0), "MasterCrest")
		_add_vacuum_part(root, _vacuum_cylinder(0.07, 0.09, 0.16), Vector3(0.0, 0.08, 0.59), steel, Vector3.ONE, Vector3(PI * 0.5, 0.0, 0.0), "ExhaustRotor")

func _build_vacuum_suction_feedback(root: Node3D) -> void:
	var flow_material := _vacuum_material(Color(0.42, 0.84, 0.78, 0.16), 0.2, 0.0)
	flow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	suction_flow = MeshInstance3D.new()
	suction_flow.name = "VisibleSuctionFlow"
	suction_flow.mesh = _vacuum_cylinder(0.25, 0.07, 0.82)
	suction_flow.rotation_degrees.x = 90.0
	suction_flow.position.z = -0.58
	suction_flow.material_override = flow_material
	suction_flow.visible = false
	root.add_child(suction_flow)
	suction_rings.clear()
	for ring_index in range(3):
		var ring := MeshInstance3D.new()
		ring.name = "SuctionPulse_%d" % ring_index
		ring.mesh = _vacuum_torus(0.08, 0.13)
		ring.rotation_degrees.x = 90.0
		ring.material_override = flow_material
		ring.visible = false
		root.add_child(ring)
		suction_rings.append(ring)
	suction_particles = CPUParticles3D.new()
	suction_particles.name = "NozzleAirflowParticles"
	suction_particles.amount = 14 + vacuum_evolution_level * 2
	suction_particles.lifetime = 0.34
	suction_particles.emitting = false
	suction_particles.direction = Vector3(0.0, 0.0, -1.0)
	suction_particles.spread = 14.0
	suction_particles.initial_velocity_min = 2.2 + float(vacuum_evolution_level) * 0.12
	suction_particles.initial_velocity_max = 4.1 + float(vacuum_evolution_level) * 0.16
	suction_particles.gravity = Vector3.ZERO
	suction_particles.position = Vector3(0.0, 0.0, -0.30)
	var particle_mesh := SphereMesh.new()
	particle_mesh.radial_segments = 8
	particle_mesh.rings = 4
	particle_mesh.radius = 0.035
	particle_mesh.height = 0.07
	suction_particles.mesh = particle_mesh
	suction_particles.material_override = _vacuum_material(Color(0.56, 0.88, 0.82), 0.28, 0.0)
	root.add_child(suction_particles)

func _play_vacuum_wind(delta: float) -> void:
	if vacuum_model_root == null or suction_flow == null:
		return
	suction_animation_clock += delta
	suction_flow.visible = true
	suction_flow.scale = Vector3.ONE * (0.92 + 0.10 * sin(suction_animation_clock * 18.0))
	if suction_particles:
		suction_particles.emitting = true
	for index in range(suction_rings.size()):
		var ring := suction_rings[index]
		var distance := fposmod(suction_animation_clock * 1.9 + float(index) * 0.28, 0.82)
		ring.position = Vector3(0.0, 0.0, -0.24 - distance)
		ring.scale = Vector3.ONE * (0.62 + distance * 0.6)
		ring.visible = true
	if vacuum_evolution_level >= 5:
		vacuum_model_root.position.y = -0.32 + sin(suction_animation_clock * 19.0) * 0.012

func _stop_vacuum_feedback() -> void:
	if suction_flow:
		suction_flow.visible = false
	for ring in suction_rings:
		ring.visible = false
	if suction_particles:
		suction_particles.emitting = false
	if vacuum_model_root:
		vacuum_model_root.position.y = -0.32

func _vacuum_material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func _add_vacuum_part(root: Node3D, mesh: Mesh, location: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, rotation_value: Vector3 = Vector3.ZERO, part_name: String = "VacuumPart") -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = location
	part.scale = scale_value
	part.rotation = rotation_value
	part.material_override = material
	root.add_child(part)
	return part

func _vacuum_box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _vacuum_cylinder(top_radius: float, bottom_radius: float, height_value: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height_value
	mesh.radial_segments = 24
	return mesh

func _vacuum_torus(inner_radius: float, outer_radius: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 24
	mesh.ring_segments = 10
	return mesh

func unlock_vacuum() -> void:
	vacuum_unlocked = true
	if vacuum_model_root:
		vacuum_model_root.visible = true

func lock_vacuum() -> void:
	vacuum_unlocked = false
	_stop_vacuum_feedback()
	if vacuum_model_root:
		vacuum_model_root.visible = false

func _refresh_boss_target() -> void:
	var next_target: TRushGarbageMountainBoss
	if game_camera:
		var center := get_viewport().get_visible_rect().size * 0.5
		var origin := game_camera.project_ray_origin(center)
		var ray_direction := game_camera.project_ray_normal(center)
		var query := PhysicsRayQueryParameters3D.create(origin, origin + ray_direction * (interaction_range + vacuum_radius + 5.0))
		query.collision_mask = 7
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider := hit.get("collider") as Node
			if collider and collider.is_in_group("garbage_boss") and collider is TRushGarbageMountainBoss:
				next_target = collider as TRushGarbageMountainBoss
	if next_target == targeted_boss:
		return
	if targeted_boss and is_instance_valid(targeted_boss):
		targeted_boss.set_vacuumed(false)
	targeted_boss = next_target
	boss_target_changed.emit(targeted_boss)

func _damage_targeted_boss(delta: float) -> void:
	if targeted_boss == null or not is_instance_valid(targeted_boss) or targeted_boss.is_defeated:
		return
	var valid_range := vacuum_radius * fruit_vacuum_range_multiplier + 3.35
	if global_position.distance_to(targeted_boss.global_position) > valid_range:
		targeted_boss.set_vacuumed(false)
		return
	targeted_boss.set_vacuumed(true)
	targeted_boss.apply_vacuum_damage(vacuum_damage_per_second * vacuum_damage_multiplier * fruit_vacuum_damage_multiplier * delta)

func _vacuum_collect() -> void:
	if vacuum_active or bag_count >= bag_capacity or vacuum_nozzle == null:
		return
	vacuum_active = true
	var collected_this_pulse := 0
	for item in get_tree().get_nodes_in_group("garbage"):
		if collected_this_pulse >= 6 or bag_count >= bag_capacity:
			break
		if not item is Node3D or not is_instance_valid(item):
			continue
<<<<<<< Updated upstream
		var target_item := item as Node3D
		if target_item.has_meta("vacuum_claimed"):
=======
		if global_position.distance_to(item.global_position) > vacuum_radius * fruit_vacuum_range_multiplier:
>>>>>>> Stashed changes
			continue
		if global_position.distance_to(target_item.global_position) > vacuum_radius:
			continue
		var value := int(target_item.get("trash_value"))
		if value <= 0 or bag_count + value > bag_capacity:
			continue
		target_item.set_meta("vacuum_claimed", true)
		bag_count += value
<<<<<<< Updated upstream
		bag_reward_total += maxi(int(target_item.get("reward_value")), 1)
		collected_this_pulse += 1
=======
		bag_reward_total += maxi(int(item.get("reward_value")), 1)
		trash_item_collected.emit(item as TrashPickup)
>>>>>>> Stashed changes
		trash_collected.emit(value)
		var tween := create_tween()
		tween.tween_property(target_item, "global_position", vacuum_nozzle.global_position, vacuum_pull_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(target_item.queue_free)
	if collected_this_pulse > 0:
		inventory_changed.emit(bag_count, bag_capacity)
	vacuum_active = false

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
	trash_item_collected.emit(target as TrashPickup)
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

<<<<<<< Updated upstream
func apply_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)

func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
=======
func take_damage(amount: float) -> void:
	if amount <= 0.0 or knocked_out or invulnerability_time > 0.0:
		return
	current_health = maxf(0.0, current_health - amount * fruit_damage_received_multiplier)
	health_changed.emit(current_health, maximum_health)
	took_damage.emit(amount * fruit_damage_received_multiplier)
	if current_health <= 0.0:
		knocked_out = true
		velocity = Vector3.ZERO
		health_depleted.emit()

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_health = minf(maximum_health, current_health + amount)
	health_changed.emit(current_health, maximum_health)

func respawn_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	current_health = maximum_health
	knocked_out = false
	invulnerability_time = 3.0
	health_changed.emit(current_health, maximum_health)

func activate_fruit_boost(boost_id: String, duration: float = 60.0) -> void:
	fruit_movement_multiplier = 1.0
	fruit_vacuum_damage_multiplier = 1.0
	fruit_vacuum_range_multiplier = 1.0
	fruit_damage_received_multiplier = 1.0
	active_fruit_boost = boost_id
	fruit_boost_time = maxf(0.0, duration)
	match boost_id:
		"speed": fruit_movement_multiplier = 1.32
		"vacuum": fruit_vacuum_damage_multiplier = 1.5
		"range": fruit_vacuum_range_multiplier = 1.4
		"shield": fruit_damage_received_multiplier = 0.55

func _update_temporary_effects(delta: float) -> void:
	if invulnerability_time > 0.0:
		invulnerability_time = maxf(0.0, invulnerability_time - delta)
	if fruit_boost_time <= 0.0:
		return
	fruit_boost_time = maxf(0.0, fruit_boost_time - delta)
	if fruit_boost_time <= 0.0:
		active_fruit_boost = ""
		fruit_movement_multiplier = 1.0
		fruit_vacuum_damage_multiplier = 1.0
		fruit_vacuum_range_multiplier = 1.0
		fruit_damage_received_multiplier = 1.0
>>>>>>> Stashed changes
