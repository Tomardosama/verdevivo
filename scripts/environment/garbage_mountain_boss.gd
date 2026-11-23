extends CharacterBody3D
class_name TRushGarbageMountainBoss

signal health_changed(current_health: float, maximum_health: float, damage_stage: int)
signal garbage_release_requested(trash_type: String, is_final_drop: bool)
signal final_drop_batch_requested(trash_types: Array[String])
signal defeated(boss_id: String, reward: int)
signal split_requested(boss_id: String, world_position: Vector3, children: Array[Dictionary], reward: int)

enum SeismicState { READY, TELEGRAPH, WAVE }

@export var boss_id: String = "plastic_mountain"
@export var boss_name: String = "Plastón, el Devorador"
@export_enum("plastic", "scrap", "mixed", "forest", "stream", "landfill") var archetype: String = "plastic"
@export_range(100.0, 5000.0, 10.0) var maximum_health: float = 520.0
@export_range(1.0, 5000.0, 1.0) var defeat_reward: int = 180
@export_range(0.2, 5.0, 0.05) var drop_interval: float = 0.72
@export_range(1, 80, 1) var maximum_drops: int = 24
@export_range(1, 30, 1) var final_drop_count: int = 7
@export_range(0.2, 5.0, 0.05) var movement_speed: float = 1.25
@export_range(5.0, 40.0, 0.5) var attack_range: float = 26.0
@export_range(5.0, 18.0, 0.5) var preferred_range: float = 11.0
@export_range(8.0, 36.0, 0.5) var leash_radius: float = 22.0
@export_range(1.0, 8.0, 0.1) var attack_interval: float = 3.5
@export_range(0.45, 3.0, 0.05) var telegraph_duration: float = 1.15
@export_range(20.0, 100.0, 1.0) var cone_angle_degrees: float = 58.0
@export_range(8.0, 40.0, 0.5) var shockwave_speed: float = 19.0
@export_range(4.0, 40.0, 1.0) var attack_damage: float = 18.0
@export var drop_types: Array[String] = ["Botella plastica", "Bolsa plastica", "Envase plastico"]
@export var split_parent_id: String = ""
@export var is_miniboss: bool = false
@export_range(0.35, 1.2, 0.01) var size_scale: float = 1.0
@export var split_children: Array[Dictionary] = []

var current_health: float = 0.0
var damage_stage: int = 0
var is_defeated: bool = false
var is_being_vacuumed: bool = false
var drops_released: int = 0
var drop_timer: float = 0.0
var feedback_clock: float = 0.0
var attack_timer: float = 2.0
var seismic_state: SeismicState = SeismicState.READY
var telegraph_time_left: float = 0.0
var attack_origin: Vector3 = Vector3.ZERO
var attack_direction: Vector3 = Vector3.FORWARD
var shockwave_front: float = 0.0
var shockwave_update_timer: float = 0.0
var player_hit_this_wave: bool = false
var home_position: Vector3 = Vector3.ZERO
var combat_target: CharacterBody3D
var debris_parts: Array[MeshInstance3D] = []
var debris_home: Array[Transform3D] = []
var visual_root: Node3D
var damage_particles: CPUParticles3D
var health_label: Label3D
var telegraph_visual: MeshInstance3D
var shockwave_visual: MeshInstance3D
var telegraph_material: StandardMaterial3D
var visual_scale_factor: float = 1.0
var arm_pivots: Array[Node3D] = []
var leg_pivots: Array[Node3D] = []

func configure(settings: Dictionary) -> void:
	boss_id = str(settings.get("id", boss_id))
	boss_name = str(settings.get("name", boss_name))
	archetype = str(settings.get("archetype", archetype))
	maximum_health = float(settings.get("health", maximum_health))
	defeat_reward = int(settings.get("reward", defeat_reward))
	drop_interval = float(settings.get("drop_interval", drop_interval))
	maximum_drops = int(settings.get("max_drops", maximum_drops))
	final_drop_count = int(settings.get("final_drops", final_drop_count))
	movement_speed = float(settings.get("movement_speed", movement_speed))
	attack_range = float(settings.get("attack_range", attack_range))
	preferred_range = float(settings.get("preferred_range", preferred_range))
	leash_radius = float(settings.get("leash_radius", leash_radius))
	attack_interval = float(settings.get("attack_interval", attack_interval))
	telegraph_duration = float(settings.get("telegraph_duration", telegraph_duration))
	cone_angle_degrees = float(settings.get("cone_angle_degrees", cone_angle_degrees))
	shockwave_speed = float(settings.get("shockwave_speed", shockwave_speed))
	attack_damage = float(settings.get("attack_damage", attack_damage))
	split_parent_id = str(settings.get("split_parent_id", split_parent_id))
	is_miniboss = bool(settings.get("is_miniboss", is_miniboss))
	size_scale = clampf(float(settings.get("size_scale", 0.72 if is_miniboss else 1.0)), 0.35, 1.2)
	split_children.clear()
	var children: Variant = settings.get("split_children", [])
	if children is Array:
		for child in children:
			if child is Dictionary:
				split_children.append(child.duplicate(true))
	drop_types.clear()
	for item_type in settings.get("drop_types", []):
		drop_types.append(str(item_type))
	if drop_types.is_empty():
		drop_types = ["Botella plastica", "Lata de aluminio"]

func _ready() -> void:
	add_to_group("garbage_boss")
	collision_layer = 5
	collision_mask = 1
	home_position = global_position
	attack_timer = randf_range(1.2, 2.8)
	if current_health <= 0.0:
		current_health = maximum_health
	_build_boss()
	visual_scale_factor = size_scale
	visual_root.scale = Vector3.ONE * visual_scale_factor
	_build_physics()
	_build_seismic_visuals()
	if damage_stage > 0:
		_apply_damage_stage()
	health_changed.emit(current_health, maximum_health, damage_stage)

func set_combat_target(target: CharacterBody3D) -> void:
	combat_target = target

func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	var target_active := combat_target != null and is_instance_valid(combat_target)
	if target_active and combat_target.has_method("get"):
		target_active = bool(combat_target.get("collection_enabled"))
	var horizontal_to_target := Vector3.ZERO
	var target_distance := INF
	var movement := Vector3.ZERO
	if seismic_state != SeismicState.READY and not target_active:
		_cancel_seismic_attack()
	if seismic_state == SeismicState.READY and target_active:
		horizontal_to_target = combat_target.global_position - global_position
		horizontal_to_target.y = 0.0
		target_distance = horizontal_to_target.length()
		if target_distance > preferred_range:
			var from_home := global_position - home_position
			from_home.y = 0.0
			if from_home.length() >= leash_radius:
				movement = -from_home.normalized() * movement_speed * 0.55
			else:
				movement = horizontal_to_target.normalized() * movement_speed
		if horizontal_to_target.length_squared() > 0.01:
			look_at(Vector3(combat_target.global_position.x, global_position.y, combat_target.global_position.z), Vector3.UP)
		if movement.length_squared() > 0.01:
			movement = _steer_around_obstacles(movement)
		attack_timer -= delta
		if target_distance <= attack_range and attack_timer <= 0.0:
			_begin_seismic_attack(horizontal_to_target)
			movement = Vector3.ZERO
	elif seismic_state != SeismicState.READY:
		_advance_seismic_attack(delta)
	velocity.x = movement.x
	velocity.z = movement.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()

func _steer_around_obstacles(desired_movement: Vector3) -> Vector3:
	var direction := desired_movement.normalized()
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.0, global_position + Vector3.UP * 1.0 + direction * 3.4)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var space := get_world_3d().direct_space_state
	if space.intersect_ray(query).is_empty():
		return desired_movement
	var left := Vector3(-direction.z, 0.0, direction.x)
	for candidate in [left, -left]:
		var side_query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.0, global_position + Vector3.UP * 1.0 + (direction + candidate * 0.85).normalized() * 2.8)
		side_query.collision_mask = 1
		side_query.exclude = [get_rid()]
		if space.intersect_ray(side_query).is_empty():
			return (direction + candidate * 0.85).normalized() * desired_movement.length()
	return Vector3.ZERO

func _begin_seismic_attack(target_offset: Vector3) -> void:
	if target_offset.length_squared() < 0.01:
		return
	attack_origin = global_position
	attack_direction = target_offset.normalized()
	attack_direction.y = 0.0
	look_at(attack_origin + attack_direction, Vector3.UP)
	telegraph_time_left = telegraph_duration
	seismic_state = SeismicState.TELEGRAPH
	player_hit_this_wave = false
	shockwave_front = 0.0
	shockwave_update_timer = 0.0
	if telegraph_visual:
		telegraph_visual.visible = true
	if shockwave_visual:
		shockwave_visual.visible = false
	_update_telegraph_intensity()

func _advance_seismic_attack(delta: float) -> void:
	if seismic_state == SeismicState.TELEGRAPH:
		telegraph_time_left -= delta
		_update_telegraph_intensity()
		if telegraph_time_left <= 0.0:
			seismic_state = SeismicState.WAVE
			shockwave_front = 0.0
			if telegraph_visual:
				telegraph_visual.visible = false
			if shockwave_visual:
				shockwave_visual.visible = true
			_update_shockwave_visual()
	elif seismic_state == SeismicState.WAVE:
		var previous_front := shockwave_front
		shockwave_front = minf(attack_range, shockwave_front + shockwave_speed * delta)
		shockwave_update_timer -= delta
		if shockwave_update_timer <= 0.0 or shockwave_front >= attack_range:
			shockwave_update_timer = 0.06
			_update_shockwave_visual()
		_check_shockwave_hit(previous_front, shockwave_front)
		if shockwave_front >= attack_range:
			seismic_state = SeismicState.READY
			attack_timer = attack_interval
			if shockwave_visual:
				shockwave_visual.visible = false

func _check_shockwave_hit(previous_front: float, current_front: float) -> void:
	if player_hit_this_wave or not is_instance_valid(combat_target) or not combat_target.has_method("take_damage"):
		return
	var player_offset := combat_target.global_position - attack_origin
	player_offset.y = 0.0
	var distance := player_offset.length()
	if distance > attack_range or distance > current_front + 0.12 or distance < maxf(0.0, previous_front - 0.12):
		return
	if distance > 0.001 and attack_direction.dot(player_offset.normalized()) < cos(deg_to_rad(cone_angle_degrees * 0.5)):
		return
	player_hit_this_wave = true
	combat_target.call("take_damage", attack_damage)

func _cancel_seismic_attack() -> void:
	seismic_state = SeismicState.READY
	attack_timer = maxf(attack_timer, attack_interval * 0.5)
	if telegraph_visual:
		telegraph_visual.visible = false
	if shockwave_visual:
		shockwave_visual.visible = false

func _update_telegraph_intensity() -> void:
	if telegraph_material == null:
		return
	var progress := 1.0 - clampf(telegraph_time_left / maxf(telegraph_duration, 0.01), 0.0, 1.0)
	var telegraph_color := telegraph_material.albedo_color
	telegraph_color.a = lerpf(0.14, 0.48, progress)
	telegraph_material.albedo_color = telegraph_color
	telegraph_material.emission_energy_multiplier = lerpf(0.3, 1.35, progress)

func _update_shockwave_visual() -> void:
	if shockwave_visual == null:
		return
	shockwave_visual.mesh = _create_shockwave_mesh(shockwave_front, 0.9)

func restore_progress(state: Dictionary) -> void:
	current_health = clampf(float(state.get("health", maximum_health)), 0.0, maximum_health)
	drops_released = clampi(int(state.get("drops_released", 0)), 0, maximum_drops)
	damage_stage = int(state.get("stage", 0))
	if current_health <= maximum_health * 0.32:
		damage_stage = 2
	elif current_health <= maximum_health * 0.66:
		damage_stage = maxi(damage_stage, 1)

func progress_snapshot() -> Dictionary:
	return {"health": current_health, "drops_released": drops_released, "stage": damage_stage}

func _process(delta: float) -> void:
	if is_defeated:
		return
	feedback_clock += delta
	if visual_root:
		var locomotion := Vector2(velocity.x, velocity.z).length()
		var gait := sin(feedback_clock * 7.2) * clampf(locomotion / maxf(0.1, movement_speed), 0.0, 1.0)
		visual_root.position.y = sin(feedback_clock * 1.4) * 0.055 + gait * 0.035
		var attack_pose := 0.56 if seismic_state == SeismicState.TELEGRAPH else -0.34 if seismic_state == SeismicState.WAVE else 0.0
		for index in range(arm_pivots.size()):
			var side := -1.0 if index == 0 else 1.0
			arm_pivots[index].rotation.x = attack_pose + gait * 0.28 * side
		for index in range(leg_pivots.size()):
			var side := -1.0 if index == 0 else 1.0
			leg_pivots[index].rotation.x = -gait * 0.25 * side
		visual_root.rotation.x = lerpf(visual_root.rotation.x, -0.08 if seismic_state == SeismicState.TELEGRAPH else 0.0, delta * 4.0)
		if feedback_clock < 0.18:
			visual_root.rotation.z = sin(feedback_clock * 50.0) * 0.035
		else:
			visual_root.rotation.z = lerpf(visual_root.rotation.z, 0.0, delta * 5.0)
	if is_being_vacuumed and drops_released < maximum_drops:
		drop_timer -= delta
		if drop_timer <= 0.0:
			drop_timer = drop_interval
			var item_type := drop_types[drops_released % drop_types.size()]
			drops_released += 1
			garbage_release_requested.emit(item_type, false)

func set_vacuumed(active: bool) -> void:
	if is_defeated:
		is_being_vacuumed = false
		return
	if active and not is_being_vacuumed:
		drop_timer = minf(drop_timer, drop_interval * 0.55) if drop_timer > 0.0 else 0.25
	is_being_vacuumed = active

func apply_vacuum_damage(amount: float) -> void:
	if is_defeated or amount <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	feedback_clock = 0.0
	var next_stage := 0
	if current_health <= maximum_health * 0.66:
		next_stage = 1
	if current_health <= maximum_health * 0.32:
		next_stage = 2
	if next_stage != damage_stage:
		damage_stage = next_stage
		_apply_damage_stage()
	if damage_particles and not damage_particles.emitting:
		damage_particles.restart()
		damage_particles.emitting = true
	health_changed.emit(current_health, maximum_health, damage_stage)
	if current_health <= 0.0:
		_defeat()

func get_drop_types() -> Array[String]:
	return drop_types.duplicate()

func _build_boss() -> void:
	visual_root = Node3D.new()
	visual_root.name = "BossVisual"
	add_child(visual_root)
	var palette := _palette()
	var mound := MeshInstance3D.new()
	mound.name = "CompressedWasteCore"
	var mound_mesh := SphereMesh.new()
	mound_mesh.radial_segments = 36
	mound_mesh.rings = 24
	mound_mesh.radius = 1.3
	mound_mesh.height = 3.05
	mound.mesh = mound_mesh
	mound.position.y = 2.25
	mound.scale = Vector3(1.12, 1.0, 0.78)
	mound.material_override = palette[0]
	visual_root.add_child(mound)
	_build_humanoid_silhouette(palette)
	for part_index in range(15):
		var part := MeshInstance3D.new()
		part.name = "CompactedDebris_%02d" % part_index
		var angle := TAU * float(part_index) / 15.0 + float(abs(boss_id.hash() % 100)) * 0.002
		var radius := randf_range(1.15, 2.15)
		var part_mesh: Mesh
		if archetype == "scrap" and part_index % 3 == 0:
			var tire := TorusMesh.new()
			tire.inner_radius = 0.36
			tire.outer_radius = 0.64
			part_mesh = tire
			part.rotation.x = PI * 0.5 + randf_range(-0.2, 0.2)
		elif archetype == "plastic" and part_index % 3 == 0:
			var bottle := CylinderMesh.new()
			bottle.top_radius = 0.075
			bottle.bottom_radius = 0.16
			bottle.height = 0.68
			part_mesh = bottle
		else:
			var scrap := BoxMesh.new()
			scrap.size = Vector3(randf_range(0.35, 1.1), randf_range(0.22, 0.65), randf_range(0.4, 1.2))
			part_mesh = scrap
		part.mesh = part_mesh
		part.position = Vector3(cos(angle) * radius, randf_range(0.55, 4.1), sin(angle) * radius)
		part.rotation.y = randf_range(0.0, TAU)
		part.scale = Vector3(randf_range(0.85, 1.25), randf_range(0.78, 1.2), randf_range(0.85, 1.25))
		part.material_override = palette[1 + part_index % (palette.size() - 1)]
		visual_root.add_child(part)
		debris_parts.append(part)
		debris_home.append(part.transform)
	var nameplate := Label3D.new()
	nameplate.text = boss_name
	nameplate.position.y = 5.0
	nameplate.font_size = 48
	nameplate.modulate = Color(1.0, 0.87, 0.63)
	nameplate.outline_size = 8
	nameplate.outline_modulate = Color(0.08, 0.07, 0.055, 0.95)
	visual_root.add_child(nameplate)
	health_label = nameplate
	damage_particles = CPUParticles3D.new()
	damage_particles.name = "DamageDebris"
	damage_particles.amount = 20
	damage_particles.lifetime = 0.48
	damage_particles.one_shot = true
	damage_particles.explosiveness = 0.88
	damage_particles.emitting = false
	damage_particles.direction = Vector3(0.0, 1.0, 0.0)
	damage_particles.spread = 72.0
	damage_particles.initial_velocity_min = 1.2
	damage_particles.initial_velocity_max = 3.4
	damage_particles.gravity = Vector3(0.0, -5.0, 0.0)
	var particle_mesh := BoxMesh.new()
	particle_mesh.size = Vector3(0.12, 0.12, 0.12)
	damage_particles.mesh = particle_mesh
	var particle_material := StandardMaterial3D.new()
	particle_material.albedo_color = _palette_color(1)
	damage_particles.material_override = particle_material
	damage_particles.position.y = 1.7
	visual_root.add_child(damage_particles)

func _build_humanoid_silhouette(palette: Array[StandardMaterial3D]) -> void:
	var shadow_material := StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0.055, 0.065, 0.058)
	shadow_material.roughness = 0.94
	var accent_color := Color(0.42, 0.78, 0.44)
	match archetype:
		"stream": accent_color = Color(0.25, 0.83, 0.91)
		"scrap", "landfill": accent_color = Color(0.98, 0.61, 0.24)
		"forest": accent_color = Color(0.70, 0.91, 0.43)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = accent_color
	eye_material.emission_enabled = true
	eye_material.emission = accent_color
	eye_material.emission_energy_multiplier = 0.55
	eye_material.roughness = 0.24

	# The compressed mound reads as the torso; layered scrap gives it shoulders,
	# a head and a recognisable stance without adding physics bodies per part.
	_add_boss_part(_cylinder_mesh(0.22, 0.31, 0.42), Vector3(0.0, 3.45, 0.0), palette[1], Vector3.ONE, Vector3.ZERO, "ScrapNeck")
	_add_boss_part(_sphere_mesh(0.68, 1.05), Vector3(0.0, 4.18, 0.0), palette[2], Vector3(1.0, 0.9, 0.82), Vector3.ZERO, "TrashHelmetHead")
	_add_boss_part(_torus_mesh(0.48, 0.64), Vector3(0.0, 4.62, 0.0), palette[1], Vector3(1.0, 0.42, 0.78), Vector3.ZERO, "BentBucketRim")
	_add_boss_part(_box_mesh(Vector3(0.47, 0.15, 0.11)), Vector3(0.0, 3.98, -0.48), shadow_material, Vector3.ONE, Vector3.ZERO, "JawOpening")
	for tooth_index in range(4):
		_add_boss_part(_box_mesh(Vector3(0.055, 0.09, 0.04)), Vector3(-0.15 + float(tooth_index) * 0.10, 3.99, -0.55), palette[2], Vector3.ONE, Vector3.ZERO, "ScrapTooth")
	arm_pivots.clear()
	leg_pivots.clear()
	for side in [-1.0, 1.0]:
		_add_boss_part(_sphere_mesh(0.16, 0.22), Vector3(side * 0.24, 4.28, -0.52), shadow_material, Vector3(1.0, 0.9, 0.46), Vector3.ZERO, "EyeSocket")
		_add_boss_part(_sphere_mesh(0.095, 0.12), Vector3(side * 0.24, 4.28, -0.59), eye_material, Vector3(1.0, 1.0, 0.5), Vector3.ZERO, "GlowingEye")
		var shoulder_origin := Vector3(side * 1.27, 3.08, 0.0)
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmSwingPivot_%s" % ("Left" if side < 0.0 else "Right")
		arm_pivot.position = shoulder_origin
		visual_root.add_child(arm_pivot)
		arm_pivots.append(arm_pivot)
		_add_boss_part(_sphere_mesh(0.53, 0.82), Vector3.ZERO, palette[1], Vector3(1.0, 0.82, 0.9), Vector3.ZERO, "ShoulderHeap", arm_pivot)
		_add_boss_part(_cylinder_mesh(0.27, 0.34, 1.18), Vector3(side * 0.28, -0.66, 0.0), palette[2], Vector3.ONE, Vector3(0.0, 0.0, -side * 0.22), "GarbageUpperArm", arm_pivot)
		_add_boss_part(_torus_mesh(0.25, 0.34), Vector3(side * 0.28, -0.43, 0.0), palette[0], Vector3(0.78, 0.7, 0.72), Vector3(PI * 0.5, 0.0, 0.0), "ArmTireCuff", arm_pivot)
		_add_boss_part(_cylinder_mesh(0.22, 0.29, 0.86), Vector3(side * 0.48, -1.30, -0.01), palette[1], Vector3.ONE, Vector3(0.0, 0.0, side * 0.12), "GarbageForearm", arm_pivot)
		_add_boss_part(_box_mesh(Vector3(0.38, 0.34, 0.42)), Vector3(side * 0.52, -1.80, -0.04), palette[2], Vector3.ONE, Vector3.ZERO, "ScrapFist", arm_pivot)
		for finger_index in range(3):
			var finger_x: float = float(side) * (0.36 + float(finger_index) * 0.15)
			_add_boss_part(_cylinder_mesh(0.045, 0.07, 0.28), Vector3(finger_x, -2.0, -0.12), palette[2], Vector3.ONE, Vector3(0.0, 0.0, -side * 0.28), "BentMetalFinger", arm_pivot)
		var hip_origin := Vector3(side * 0.73, 1.25, 0.0)
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LegSwingPivot_%s" % ("Left" if side < 0.0 else "Right")
		leg_pivot.position = hip_origin
		visual_root.add_child(leg_pivot)
		leg_pivots.append(leg_pivot)
		_add_boss_part(_sphere_mesh(0.43, 0.7), Vector3.ZERO, palette[1], Vector3(1.0, 0.78, 0.82), Vector3.ZERO, "HipScrap", leg_pivot)
		_add_boss_part(_cylinder_mesh(0.38, 0.28, 1.05), Vector3(0.0, -0.57, 0.02), palette[2], Vector3.ONE, Vector3(0.0, 0.0, side * 0.08), "GarbageLeg", leg_pivot)
		_add_boss_part(_torus_mesh(0.28, 0.39), Vector3(0.0, -0.83, 0.02), palette[0], Vector3(0.9, 0.52, 0.82), Vector3(PI * 0.5, 0.0, 0.0), "KneeTirePad", leg_pivot)
		_add_boss_part(_box_mesh(Vector3(0.62, 0.28, 0.78)), Vector3(0.0, -1.08, -0.18), palette[1], Vector3.ONE, Vector3.ZERO, "ScrapBoot", leg_pivot)

	_add_boss_part(_box_mesh(Vector3(0.92, 0.7, 0.17)), Vector3(0.0, 2.72, -1.11), palette[1], Vector3.ONE, Vector3(0.08, 0.0, 0.0), "CrushedChestPlate")
	_add_boss_part(_cylinder_mesh(0.08, 0.20, 0.46), Vector3(-0.43, 2.72, -1.24), palette[2], Vector3(1.0, 1.0, 0.72), Vector3(PI * 0.5, 0.0, 0.0), "BottleArmor")
	_add_boss_part(_torus_mesh(0.26, 0.39), Vector3(0.0, 2.2, -0.78), palette[2], Vector3(1.45, 0.65, 1.0), Vector3(PI * 0.5, 0.0, 0.0), "WasteBelt")
	for rivet_x in [-0.34, 0.34]:
		_add_boss_part(_sphere_mesh(0.07, 0.08), Vector3(rivet_x, 2.72, -1.22), eye_material, Vector3.ONE, Vector3.ZERO, "ChestRivet")
	if archetype == "forest":
		for side in [-1.0, 1.0]:
			_add_boss_part(_cylinder_mesh(0.018, 0.12, 1.12), Vector3(side * 0.46, 4.62, 0.08), palette[0], Vector3.ONE, Vector3(0.0, 0.0, -side * 0.52), "BranchAntler")
			_add_boss_part(_sphere_mesh(0.42, 0.62), Vector3(side * 1.2, 3.38, 0.20), palette[2], Vector3(1.1, 0.78, 0.9), Vector3.ZERO, "LeafMantle")
		_add_boss_part(_cylinder_mesh(0.035, 0.16, 0.92), Vector3(0.0, 0.40, 0.20), palette[0], Vector3.ONE, Vector3(0.0, 0.0, PI * 0.5), "RootedHeel")
	elif archetype == "stream":
		for side in [-1.0, 1.0]:
			_add_boss_part(_cylinder_mesh(0.08, 0.16, 0.55), Vector3(side * 0.52, 2.85, -1.05), palette[2], Vector3(0.9, 1.0, 0.8), Vector3(PI * 0.5, 0.0, side * 0.14), "WaterBottlePauldron")
			_add_boss_part(_torus_mesh(0.20, 0.27), Vector3(side * 1.44, 2.48, 0.0), palette[0], Vector3(1.0, 0.72, 0.88), Vector3.ZERO, "FloatingRingArmor")

func _add_boss_part(mesh: Mesh, location: Vector3, material: Material, scale_value: Vector3, rotation_value: Vector3, part_name: String, parent: Node3D = null) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = location
	part.scale = scale_value
	part.rotation = rotation_value
	part.material_override = material
	if parent == null:
		visual_root.add_child(part)
	else:
		parent.add_child(part)
	debris_parts.append(part)
	debris_home.append(part.transform)
	return part

func _sphere_mesh(radius_value: float, height_value: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 32
	mesh.rings = 20
	mesh.radius = radius_value
	mesh.height = height_value
	return mesh

func _cylinder_mesh(top_radius: float, bottom_radius: float, height_value: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height_value
	mesh.radial_segments = 24
	return mesh

func _torus_mesh(inner_radius: float, outer_radius: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 24
	mesh.ring_segments = 8
	return mesh

func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _build_physics() -> void:
	var body_shape := CollisionShape3D.new()
	var body_box := BoxShape3D.new()
	body_box.size = (Vector3(3.0, 3.4, 2.0) if is_miniboss else Vector3(4.8, 5.2, 2.8)) * visual_scale_factor
	body_shape.shape = body_box
	body_shape.position.y = body_box.size.y * 0.5
	add_child(body_shape)

func _build_seismic_visuals() -> void:
	telegraph_material = StandardMaterial3D.new()
	telegraph_material.albedo_color = Color(1.0, 0.30, 0.075, 0.20)
	telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	telegraph_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	telegraph_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	telegraph_material.emission_enabled = true
	telegraph_material.emission = Color(1.0, 0.22, 0.035)
	telegraph_material.emission_energy_multiplier = 0.3
	_build_telegraph_visual()
	shockwave_visual = MeshInstance3D.new()
	shockwave_visual.name = "SeismicShockwave"
	shockwave_visual.position.y = 0.12
	shockwave_visual.visible = false
	var wave_material := StandardMaterial3D.new()
	wave_material.albedo_color = Color(1.0, 0.54, 0.18, 0.90)
	wave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wave_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wave_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wave_material.emission_enabled = true
	wave_material.emission = Color(1.0, 0.30, 0.06)
	wave_material.emission_energy_multiplier = 1.7
	shockwave_visual.material_override = wave_material
	add_child(shockwave_visual)

func _build_telegraph_visual() -> void:
	telegraph_visual = MeshInstance3D.new()
	telegraph_visual.name = "SeismicDangerCone"
	telegraph_visual.position.y = 0.08
	telegraph_visual.mesh = _create_sector_mesh(attack_range)
	telegraph_visual.material_override = telegraph_material
	telegraph_visual.visible = false
	add_child(telegraph_visual)

func _create_sector_mesh(radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_angle := deg_to_rad(cone_angle_degrees * 0.5)
	var segments := 30
	for segment_index in range(segments):
		var angle_a := lerpf(-half_angle, half_angle, float(segment_index) / segments)
		var angle_b := lerpf(-half_angle, half_angle, float(segment_index + 1) / segments)
		var edge_a := Vector3(sin(angle_a) * radius, 0.0, -cos(angle_a) * radius)
		var edge_b := Vector3(sin(angle_b) * radius, 0.0, -cos(angle_b) * radius)
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(edge_b)
		surface.add_vertex(edge_a)
	surface.generate_normals()
	return surface.commit()

func _create_shockwave_mesh(front: float, width: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer_radius := maxf(0.35, front)
	var inner_radius := maxf(0.0, outer_radius - width)
	var half_angle := deg_to_rad(cone_angle_degrees * 0.5)
	var segments := 26
	for segment_index in range(segments):
		var angle_a := lerpf(-half_angle, half_angle, float(segment_index) / segments)
		var angle_b := lerpf(-half_angle, half_angle, float(segment_index + 1) / segments)
		var inner_a := Vector3(sin(angle_a) * inner_radius, 0.0, -cos(angle_a) * inner_radius)
		var outer_a := Vector3(sin(angle_a) * outer_radius, 0.0, -cos(angle_a) * outer_radius)
		var inner_b := Vector3(sin(angle_b) * inner_radius, 0.0, -cos(angle_b) * inner_radius)
		var outer_b := Vector3(sin(angle_b) * outer_radius, 0.0, -cos(angle_b) * outer_radius)
		surface.add_vertex(inner_a)
		surface.add_vertex(outer_b)
		surface.add_vertex(outer_a)
		surface.add_vertex(inner_a)
		surface.add_vertex(inner_b)
		surface.add_vertex(outer_b)
	surface.generate_normals()
	return surface.commit()

func _palette() -> Array[StandardMaterial3D]:
	var colors: Array[Color]
	match archetype:
		"plastic":
			colors = [Color(0.16, 0.35, 0.29), Color(0.20, 0.48, 0.39), Color(0.33, 0.61, 0.52)]
		"scrap":
			colors = [Color(0.25, 0.29, 0.28), Color(0.43, 0.39, 0.29), Color(0.54, 0.57, 0.51)]
		"forest":
			colors = [Color(0.25, 0.16, 0.09), Color(0.30, 0.39, 0.20), Color(0.50, 0.62, 0.31)]
		"stream":
			colors = [Color(0.12, 0.28, 0.28), Color(0.18, 0.46, 0.47), Color(0.30, 0.69, 0.72)]
		"landfill":
			colors = [Color(0.24, 0.23, 0.19), Color(0.42, 0.39, 0.32), Color(0.60, 0.54, 0.39)]
		_:
			colors = [Color(0.31, 0.29, 0.22), Color(0.45, 0.38, 0.28), Color(0.43, 0.53, 0.35)]
	var materials: Array[StandardMaterial3D] = []
	for color in colors:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.82
		material.metallic = 0.52 if archetype in ["scrap", "landfill"] else 0.06
		materials.append(material)
	return materials

func _palette_color(index: int) -> Color:
	return [Color(0.20, 0.48, 0.39), Color(0.43, 0.39, 0.29), Color(0.43, 0.53, 0.35)][index % 3]

func _apply_damage_stage() -> void:
	for index in range(debris_parts.size()):
		var part := debris_parts[index]
		var home := debris_home[index]
		if damage_stage == 0:
			part.transform = home
		elif damage_stage == 1 and index % 3 == 0:
			part.position += Vector3(0.12, -0.16, 0.08)
			part.rotation.z += 0.12
		elif damage_stage == 2 and index % 2 == 0:
			part.position += Vector3(-0.18, -0.28, 0.14)
			part.rotation.x += 0.18
			part.material_override = _palette()[1]
	if damage_stage == 1:
		visual_root.scale = Vector3(1.025, 0.985, 1.025) * visual_scale_factor
	elif damage_stage == 2:
		visual_root.scale = Vector3(1.045, 0.96, 1.045) * visual_scale_factor
	if health_label:
		health_label.text = "%s · %s" % [boss_name, ["ESTABLE", "DAÑADO", "CRÍTICO"][damage_stage]]

func _defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	is_being_vacuumed = false
	collision_layer = 0
	velocity = Vector3.ZERO
	set_physics_process(false)
	if split_children.is_empty():
		garbage_release_requested.emit("", true)
		var final_drops: Array[String] = []
		for index in range(final_drop_count):
			final_drops.append(drop_types[index % drop_types.size()])
		final_drop_batch_requested.emit(final_drops)
		defeated.emit(boss_id, defeat_reward)
	else:
		split_requested.emit(boss_id, global_position, split_children.duplicate(true), defeat_reward)
	if damage_particles:
		damage_particles.amount = 48
		damage_particles.explosiveness = 1.0
		damage_particles.restart()
		damage_particles.emitting = true
	if visual_root:
		var collapse := create_tween()
		collapse.set_parallel(true)
		collapse.tween_property(visual_root, "scale", Vector3(1.3, 0.08, 1.3), 1.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		collapse.tween_property(visual_root, "rotation", Vector3(0.0, rotation.y + TAU, 0.0), 1.05)
		collapse.chain().tween_callback(queue_free)
	set_process(false)
