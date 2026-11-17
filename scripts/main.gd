extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TRASH_SCENE := preload("res://scenes/garbage/trash.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const WILDLIFE_SCRIPT := preload("res://scripts/environment/wildlife_actor.gd")
const SAVE_PATH := "user://trush_save.cfg"

@export_group("World")
@export var starting_trash_count: int = 48
@export var day_duration: float = 210.0
@export var night_duration: float = 90.0
@export var value_per_trash: int = 5

var player: TRushPlayer
var hud: TRushHUD
var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var money: int = 0
var total_trash: int = 0
var collected_trash: int = 0
var day_time: float = 0.0
var is_day: bool = true
var prestige_count: int = 0
var upgrades := {"speed": 0, "capacity": 0, "value": 0, "range": 0, "day": 0, "vacuum": 0, "discount": 0}
var species_unlocked: Array[String] = []
var notification_cooldown: float = 0.0
var station: Node3D
var session_start_time: float = 0.0
var unlocked_zones: Array[String] = []
var skill_points: int = 0
var player_xp: int = 0
var player_level: int = 1
var skill_levels := {"agility": 0, "capacity": 0, "combo": 0, "magnet": 0}
var combo_multiplier: float = 1.0
var last_deposit_time: float = -100.0
var cloud_nodes: Array[Node3D] = []
var reserved_positions: Array[Vector3] = []
var shop_node: Node3D
var sleep_hut: Node3D

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_build_world()
	_load_game()
	_spawn_player()
	_spawn_trash()
	_spawn_station()
	_create_hud()
	_restore_unlocked_wildlife()
	_apply_upgrades()
	_update_hud()

func _process(delta: float) -> void:
	if is_day:
		day_time += delta
		if day_time >= day_duration + float(upgrades["day"]) * 30.0:
			day_time = 0.0
			is_day = false
			_on_phase_changed()
	notification_cooldown = maxf(0.0, notification_cooldown - delta)
	var duration := _current_phase_duration()
	if not is_day and player and hud and hud.shop_open:
		if shop_node == null or player.global_position.distance_to(shop_node.global_position) > 4.2:
			hud.close_shop()
	_update_sun()
	_check_zone_unlocks()
	_update_clouds(delta)
	if hud:
		hud.update_phase(is_day, int(ceil(duration - day_time)) if is_day else 0)
		hud.update_stats(money, collected_trash, prestige_count, int(Time.get_ticks_msec() / 1000.0 - session_start_time))

func _current_phase_duration() -> float:
	return day_duration + float(upgrades["day"]) * 30.0 if is_day else night_duration

func _on_phase_changed() -> void:
	if player:
		player.collection_enabled = is_day
	for animal in get_tree().get_nodes_in_group("wildlife"):
		if animal.has_method("set_night_resting"):
			animal.set_night_resting(not is_day)
	if hud:
		hud.set_upgrade_access(not is_day)
		hud.show_message("Comienza el día: ¡a limpiar!" if is_day else "Llegó la noche: momento de invertir en mejoras.")
	if not is_day:
		_save_game()

func _update_sun() -> void:
	if sun == null:
		return
	var phase := day_time / _current_phase_duration()
	if is_day:
		sun.light_energy = lerpf(1.1, 0.65, phase)
		sun.rotation_degrees.x = lerpf(-48.0, -8.0, phase)
	else:
		sun.light_energy = 0.12
		sun.rotation_degrees.x = -12.0
	if world_environment and world_environment.environment:
		world_environment.environment.ambient_light_energy = 0.65 if is_day else 0.18

func _build_world() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.position.y = -0.5
	add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(120, 1, 120)
	ground_mesh.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.20, 0.32, 0.19)
	ground_mesh.material_override = ground_material
	ground.add_child(ground_mesh)
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	ground_shape.shape = box
	ground.add_child(ground_shape)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	world_environment = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.16, 0.30, 0.43)
	sky_material.sky_horizon_color = Color(0.65, 0.73, 0.68)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.52)
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	add_child(world_environment)

	var trees := Node3D.new()
	trees.name = "Trees"
	add_child(trees)
	var rng := RandomNumberGenerator.new()
	rng.seed = 74129
	for i in range(64):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(19.0, 54.0)
		var tree_position := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if _is_clear_location(tree_position, 4.2):
			_create_tree(trees, tree_position)
			reserved_positions.append(tree_position)
	_populate_ground_detail(rng, trees)
	_create_zone_markers()
	_create_pond()
	_create_clouds()

func _create_tree(parent: Node3D, location: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = location
	var tree_scale := randf_range(0.88, 1.22)
	tree.scale = Vector3(tree_scale, tree_scale, tree_scale)
	parent.add_child(tree)

	# Tronco ligeramente cónico y raíces visibles para evitar la silueta de cilindro simple.
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.radial_segments = 24
	trunk_mesh.rings = 8
	trunk_mesh.top_radius = 0.17
	trunk_mesh.bottom_radius = 0.36
	trunk_mesh.height = 2.85
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.42
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.24 + randf() * 0.07, 0.13 + randf() * 0.035, 0.075 + randf() * 0.025)
	bark.roughness = 0.96
	trunk.material_override = bark
	tree.add_child(trunk)
	_add_box_collision(tree, Vector3(0, 1.4, 0), Vector3(0.72, 2.8, 0.72))

	for root_index in range(4):
		var root := MeshInstance3D.new()
		var root_mesh := CylinderMesh.new()
		root_mesh.radial_segments = 12
		root_mesh.top_radius = 0.045
		root_mesh.bottom_radius = 0.19
		root_mesh.height = 0.92
		root.mesh = root_mesh
		root.position = Vector3(0, 0.28, 0)
		root.rotation_degrees.y = float(root_index) * 90.0
		root.rotation_degrees.z = 48.0 if root_index % 2 == 0 else -48.0
		root.material_override = bark
		tree.add_child(root)

	# Ramas que nacen del tronco y se integran bajo la copa.
	for branch_index in range(3):
		var branch := MeshInstance3D.new()
		var branch_mesh := CylinderMesh.new()
		branch_mesh.radial_segments = 12
		branch_mesh.top_radius = 0.035
		branch_mesh.bottom_radius = 0.105
		branch_mesh.height = 1.25
		branch.mesh = branch_mesh
		branch.position = Vector3(0, 1.75 + float(branch_index) * 0.22, 0)
		branch.rotation_degrees = Vector3(22.0 * float(branch_index - 1), 0.0, -38.0 + float(branch_index) * 38.0)
		branch.material_override = bark
		tree.add_child(branch)

	# Copa compuesta por volúmenes irregulares: evita el aspecto de una esfera perfecta.
	var foliage_palette := [
		Color(0.075, 0.22, 0.105),
		Color(0.105, 0.29, 0.125),
		Color(0.15, 0.34, 0.15),
		Color(0.19, 0.38, 0.17)
	]
	var foliage_materials: Array[StandardMaterial3D] = []
	for foliage_color in foliage_palette:
		var foliage_material := StandardMaterial3D.new()
		foliage_material.albedo_color = foliage_color
		foliage_material.roughness = 1.0
		foliage_material.cull_mode = BaseMaterial3D.CULL_BACK
		foliage_materials.append(foliage_material)

	for cluster_index in range(11):
		var cluster := MeshInstance3D.new()
		var cluster_mesh := SphereMesh.new()
		cluster_mesh.radial_segments = 32
		cluster_mesh.rings = 20
		cluster_mesh.radius = randf_range(0.72, 1.12)
		cluster_mesh.height = cluster_mesh.radius * randf_range(1.25, 1.75)
		cluster.mesh = cluster_mesh
		if cluster_index == 0:
			cluster.position = Vector3(0.0, 3.35, 0.0)
		else:
			var angle := TAU * float(cluster_index - 1) / 10.0 + randf_range(-0.22, 0.22)
			var ring_radius := randf_range(0.55, 1.05)
			cluster.position = Vector3(cos(angle) * ring_radius, randf_range(2.75, 3.75), sin(angle) * ring_radius)
		cluster.scale = Vector3(randf_range(0.88, 1.18), randf_range(0.82, 1.16), randf_range(0.88, 1.2))
		cluster.material_override = foliage_materials[randi_range(0, foliage_materials.size() - 1)]
		tree.add_child(cluster)

	tree.rotation.y = randf_range(0.0, TAU)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as TRushPlayer
	add_child(player)
	player.global_position = Vector3(0, 1, 7)
	player.inventory_changed.connect(_on_inventory_changed)
	player.deposit_requested.connect(_on_deposit_requested)
	player.trash_collected.connect(_on_trash_collected)
	player.shop_requested.connect(_open_shop)
	player.sleep_requested.connect(_start_new_day)
	player.pause_requested.connect(_on_pause_requested)

func _spawn_trash() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90317 + prestige_count
	var base_target_count := maxi(starting_trash_count, 48)
	var trash_mound_count := 50
	var target_count := base_target_count + trash_mound_count
	var first_remaining := clampi(collected_trash, 0, target_count)
	var type_names := ["Botella plastica", "Lata de aluminio", "Papel y carton", "Envase de vidrio"]
	var rewards := [5, 8, 6, 12]
	var colors := [Color(0.20, 0.55, 0.72), Color(0.72, 0.76, 0.78), Color(0.72, 0.57, 0.32), Color(0.25, 0.62, 0.48)]
	for i in range(first_remaining, target_count):
		var trash := TRASH_SCENE.instantiate() as TrashPickup
		var location := Vector3.ZERO
		for attempt in range(60):
			if i >= base_target_count:
				var mound_index := int((i - base_target_count) / 10)
				var mound_angle := TAU * float(mound_index) / 5.0
				var mound_center := Vector3(cos(mound_angle) * 34.0, 0.0, sin(mound_angle) * 34.0)
				location = mound_center + Vector3(rng.randf_range(-1.15, 1.15), 0.0, rng.randf_range(-0.65, 0.65))
			else:
				location = Vector3(rng.randf_range(-49.0, 49.0), 0.0, rng.randf_range(-49.0, 49.0))
			if location.length() > 8.0 and (i >= base_target_count or _is_clear_location(location, 2.0)):
				break
		reserved_positions.append(location)
		trash.position = location
		var kind := i % type_names.size()
		trash.trash_type = type_names[kind]
		trash.reward_value = rewards[kind]
		trash.trash_value = 1
		var visual := trash.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if visual:
			var material := StandardMaterial3D.new()
			material.albedo_color = colors[kind]
			material.metallic = 0.48 if kind == 1 else 0.08
			material.roughness = 0.38 if kind == 3 else 0.72
			visual.material_override = material
			match kind:
				0:
					var bottle := CylinderMesh.new()
					bottle.top_radius = 0.09
					bottle.bottom_radius = 0.15
					bottle.height = 0.52
					visual.mesh = bottle
					var cap := MeshInstance3D.new()
					var cap_mesh := CylinderMesh.new()
					cap_mesh.top_radius = 0.055
					cap_mesh.bottom_radius = 0.055
					cap_mesh.height = 0.055
					cap.mesh = cap_mesh
					cap.position = Vector3(0.0, 0.29, 0.0)
					cap.material_override = _detail_material(Color(0.98, 0.22, 0.06))
					trash.add_child(cap)
					var bottle_band := MeshInstance3D.new()
					var band_mesh := TorusMesh.new()
					band_mesh.inner_radius = 0.105
					band_mesh.outer_radius = 0.125
					bottle_band.mesh = band_mesh
					bottle_band.position.y = 0.17
					bottle_band.material_override = _detail_material(Color(0.95, 0.82, 0.22))
					trash.add_child(bottle_band)
				1:
					var can := CylinderMesh.new()
					can.top_radius = 0.14
					can.bottom_radius = 0.14
					can.height = 0.34
					visual.mesh = can
					var label := MeshInstance3D.new()
					var label_mesh := BoxMesh.new()
					label_mesh.size = Vector3(0.018, 0.20, 0.25)
					label.mesh = label_mesh
					label.position = Vector3(0.145, 0.0, 0.0)
					label.rotation.y = 0.0
					label.material_override = _detail_material(Color(0.98, 0.18, 0.08))
					trash.add_child(label)
					var can_stripe := MeshInstance3D.new()
					var stripe_mesh := BoxMesh.new()
					stripe_mesh.size = Vector3(0.02, 0.22, 0.045)
					can_stripe.mesh = stripe_mesh
					can_stripe.position = Vector3(0.151, 0.0, -0.055)
					can_stripe.material_override = _detail_material(Color(0.08, 0.22, 0.68))
					trash.add_child(can_stripe)
				2:
					var paper := BoxMesh.new()
					paper.size = Vector3(0.34, 0.035, 0.27)
					visual.mesh = paper
					visual.position.y = 0.05
				3:
					var glass := SphereMesh.new()
					glass.radial_segments = 3
					glass.rings = 1
					glass.radius = 0.22
					glass.height = 0.10
					visual.mesh = glass
					visual.rotation = Vector3(0.15, rng.randf_range(0.0, TAU), 0.28)
					for shard_index in range(2):
						var shard := MeshInstance3D.new()
						var shard_mesh := PrismMesh.new()
						shard_mesh.size = Vector3(0.18, 0.08, 0.12)
						shard.mesh = shard_mesh
						shard.position = Vector3(rng.randf_range(-0.18, 0.18), 0.025, rng.randf_range(-0.15, 0.15))
						shard.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.0, TAU), rng.randf_range(-0.4, 0.4))
						shard.material_override = material
						trash.add_child(shard)
		add_child(trash)
	total_trash = target_count

func _populate_ground_detail(rng: RandomNumberGenerator, parent: Node3D) -> void:
	var grass_materials: Array[StandardMaterial3D] = []
	for color in [Color(0.24, 0.39, 0.18), Color(0.34, 0.43, 0.20), Color(0.43, 0.42, 0.22)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		grass_materials.append(material)
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.34, 0.36, 0.32)
	rock_material.roughness = 1.0
	for i in range(324):
		var tuft := Node3D.new()
		var grass_center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		tuft.position = grass_center + Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.6, 1.6))
		var blade_count := rng.randi_range(3, 5)
		for blade in range(blade_count):
			var mesh_node := MeshInstance3D.new()
			var blade_mesh := BoxMesh.new()
			blade_mesh.size = Vector3(0.035, rng.randf_range(0.18, 0.42), 0.045)
			mesh_node.mesh = blade_mesh
			mesh_node.position = Vector3(rng.randf_range(-0.12, 0.12), blade_mesh.size.y * 0.5, rng.randf_range(-0.12, 0.12))
			mesh_node.rotation.z = rng.randf_range(-0.35, 0.35)
			mesh_node.material_override = grass_materials[rng.randi_range(0, grass_materials.size() - 1)]
			tuft.add_child(mesh_node)
		parent.add_child(tuft)
	for plant_index in range(135):
		var plant := Node3D.new()
		plant.position = Vector3(rng.randf_range(-56, 56), 0.0, rng.randf_range(-56, 56))
		var leaf_material := StandardMaterial3D.new()
		leaf_material.albedo_color = [Color(0.15, 0.34, 0.13), Color(0.25, 0.43, 0.17), Color(0.36, 0.48, 0.21)][rng.randi_range(0, 2)]
		for leaf_index in range(5):
			var leaf := MeshInstance3D.new()
			var leaf_mesh := SphereMesh.new()
			leaf_mesh.radial_segments = 20
			leaf_mesh.rings = 14
			leaf_mesh.radius = rng.randf_range(0.12, 0.22)
			leaf_mesh.height = leaf_mesh.radius * 1.7
			leaf.mesh = leaf_mesh
			leaf.position = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.12, 0.38), rng.randf_range(-0.2, 0.2))
			leaf.scale = Vector3(0.7, 1.0, 1.35)
			leaf.material_override = leaf_material
			plant.add_child(leaf)
		parent.add_child(plant)
		if rng.randf() < 0.22:
			var berry_material := _detail_material(Color(0.72, 0.12, 0.16))
			for berry_index in range(rng.randi_range(3, 6)):
				var berry := MeshInstance3D.new()
				var berry_mesh := SphereMesh.new()
				berry_mesh.radial_segments = 16
				berry_mesh.rings = 10
				berry_mesh.radius = 0.055
				berry.mesh = berry_mesh
				berry.position = plant.position + Vector3(rng.randf_range(-0.22, 0.22), rng.randf_range(0.18, 0.42), rng.randf_range(-0.22, 0.22))
				berry.material_override = berry_material
				parent.add_child(berry)
	for big_rock_index in range(16):
		var boulder := MeshInstance3D.new()
		var boulder_mesh := SphereMesh.new()
		boulder_mesh.radial_segments = 32
		boulder_mesh.rings = 22
		boulder_mesh.radius = rng.randf_range(1.1, 2.4)
		boulder_mesh.height = boulder_mesh.radius * rng.randf_range(0.65, 1.15)
		boulder.mesh = boulder_mesh
		var boulder_pos := Vector3(rng.randf_range(-55, 55), 0.0, rng.randf_range(-55, 55))
		if not _is_clear_location(boulder_pos, boulder_mesh.radius * 2.2):
			continue
		reserved_positions.append(boulder_pos)
		boulder.position = Vector3(boulder_pos.x, boulder_mesh.radius * 0.32, boulder_pos.z)
		boulder.scale = Vector3(rng.randf_range(1.0, 1.5), rng.randf_range(0.65, 0.95), rng.randf_range(1.0, 1.4))
		boulder.material_override = rock_material
		parent.add_child(boulder)
		if boulder_mesh.radius >= 1.1:
			_add_box_collision(parent, boulder.position + Vector3(0.0, boulder_mesh.height * 0.18, 0.0), Vector3(boulder_mesh.radius * 1.55, boulder_mesh.height * 0.52, boulder_mesh.radius * 1.55))
	for i in range(64):
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = rng.randf_range(0.22, 0.72)
		rock_mesh.height = rock_mesh.radius * rng.randf_range(0.75, 1.35)
		rock.mesh = rock_mesh
		var rock_ground_position := Vector3(rng.randf_range(-56, 56), 0.0, rng.randf_range(-56, 56))
		if not _is_clear_location(rock_ground_position, rock_mesh.radius * 2.3):
			continue
		reserved_positions.append(rock_ground_position)
		rock.position = Vector3(rock_ground_position.x, rock_mesh.radius * 0.34, rock_ground_position.z)
		rock.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.55, 0.9), rng.randf_range(0.8, 1.5))
		rock.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2))
		rock.material_override = rock_material
		parent.add_child(rock)

func _create_zone_markers() -> void:
	var zones := [
		{"name": "CLARO DEL BOSQUE", "position": Vector3(0, 0, -29), "color": Color(0.45, 0.75, 0.48)},
		{"name": "ARROYO · 35% DE RESTAURACION", "position": Vector3(0, 0, -48), "color": Color(0.35, 0.68, 0.82)},
		{"name": "BORDE SALVAJE · 70% DE RESTAURACION", "position": Vector3(43, 0, 0), "color": Color(0.78, 0.68, 0.36)}
	]
	for zone in zones:
		var sign_root := Node3D.new()
		sign_root.position = zone["position"]
		add_child(sign_root)
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.16, 1.8, 0.16)
		post.mesh = post_mesh
		post.position.y = 0.9
		sign_root.add_child(post)
		var label := Label3D.new()
		label.text = zone["name"]
		label.position.y = 2.0
		label.font_size = 32
		label.modulate = zone["color"]
		sign_root.add_child(label)

func _check_zone_unlocks() -> void:
	var percent := _restoration_percent()
	var milestones := [{"percent": 35, "id": "arroyo", "name": "Arroyo"}, {"percent": 70, "id": "borde", "name": "Borde salvaje"}]
	for milestone in milestones:
		var zone_id: String = milestone["id"]
		if percent >= int(milestone["percent"]) and not unlocked_zones.has(zone_id):
			unlocked_zones.append(zone_id)
			if hud:
				hud.show_message("Nueva zona desbloqueada: " + str(milestone["name"]))
				hud.update_mission("Explora la nueva zona: " + str(milestone["name"]))
			_save_game()

func _spawn_station() -> void:
	station = Node3D.new()
	station.name = "RecyclingStation"
	station.position = Vector3(0, 0, 0)
	_add_box_collision(station, Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 2.4))
	station.add_to_group("recycling_station")
	add_child(station)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.0
	base_mesh.bottom_radius = 1.15
	base_mesh.height = 0.8
	base.mesh = base_mesh
	base.position.y = 0.4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.48, 0.35)
	base.material_override = material
	station.add_child(base)
	var bin_colors := [Color(0.15, 0.55, 0.78), Color(0.78, 0.68, 0.18), Color(0.18, 0.62, 0.38)]
	for i in range(3):
		var bin := MeshInstance3D.new()
		var bin_mesh := BoxMesh.new()
		bin_mesh.size = Vector3(0.48, 0.78, 0.48)
		bin.mesh = bin_mesh
		bin.position = Vector3(-0.68 + float(i) * 0.68, 0.82, 0.0)
		var bin_material := StandardMaterial3D.new()
		bin_material.albedo_color = bin_colors[i]
		bin.material_override = bin_material
		station.add_child(bin)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.18
	ring_mesh.outer_radius = 1.28
	ring.mesh = ring_mesh
	ring.position.y = 0.82
	ring.material_override = material
	station.add_child(ring)
	var station_sign := Label3D.new()
	station_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	station_sign.text = "RECICLAJE\n[E]"
	station_sign.position.y = 1.6
	station_sign.font_size = 48
	station_sign.modulate = Color(0.85, 1.0, 0.88)
	station.add_child(station_sign)
	_create_upgrade_kiosk()
	_create_sleep_hut()


func _create_upgrade_kiosk() -> void:
	var kiosk := Node3D.new()
	kiosk.name = "UpgradeKiosk"
	kiosk.position = Vector3(7.5, 0.0, 0.0)
	kiosk.rotation.y = PI / 2.0
	shop_node = kiosk
	kiosk.add_to_group("upgrade_shop")
	add_child(kiosk)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.13)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.16, 0.42, 0.27)
	var counter := MeshInstance3D.new()
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(2.8, 1.1, 1.2)
	counter.mesh = counter_mesh
	counter.position.y = 0.55
	counter.material_override = wood
	kiosk.add_child(counter)
	_add_box_collision(kiosk, Vector3(0, 0.55, 0), Vector3(2.8, 1.1, 1.2))
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(3.2, 0.22, 1.6)
	roof.mesh = roof_mesh
	roof.position.y = 2.05
	roof.material_override = green
	kiosk.add_child(roof)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.height = 2.0
		post_mesh.top_radius = 0.07
		post_mesh.bottom_radius = 0.09
		post.mesh = post_mesh
		post.position = Vector3(side * 1.35, 1.0, 0.0)
		post.material_override = wood
		kiosk.add_child(post)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = "TIENDA DE MEJORAS\n[E]"
	label.position.y = 2.35
	label.font_size = 34
	label.modulate = Color(0.9, 1.0, 0.84)
	kiosk.add_child(label)

func _detail_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	return material

func _add_box_collision(parent: Node3D, local_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = local_position
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	parent.add_child(body)

func _create_sleep_hut() -> void:
	sleep_hut = Node3D.new()
	sleep_hut.name = "NightRestHut"
	sleep_hut.position = Vector3(-7.5, 0.0, 0.0)
	sleep_hut.rotation.y = -PI / 2.0
	add_child(sleep_hut)
	var wood := _detail_material(Color(0.31, 0.20, 0.12))
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.8, 2.5, 0.22)
	wall.mesh = wall_mesh
	wall.position = Vector3(0, 1.25, 1.45)
	wall.material_override = wood
	sleep_hut.add_child(wall)
	for side in [-1.0, 1.0]:
		var side_wall := MeshInstance3D.new()
		var side_mesh := BoxMesh.new()
		side_mesh.size = Vector3(0.22, 2.5, 2.9)
		side_wall.mesh = side_mesh
		side_wall.position = Vector3(side * 1.8, 1.25, 0)
		side_wall.material_override = wood
		sleep_hut.add_child(side_wall)
		_add_box_collision(sleep_hut, side_wall.position, side_mesh.size)
	_add_box_collision(sleep_hut, wall.position, wall_mesh.size)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(4.2, 0.28, 3.6)
	roof.mesh = roof_mesh
	roof.position.y = 2.65
	roof.material_override = _detail_material(Color(0.18, 0.32, 0.20))
	sleep_hut.add_child(roof)
	var bed := MeshInstance3D.new()
	var bed_mesh := BoxMesh.new()
	bed_mesh.size = Vector3(1.35, 0.28, 0.72)
	bed.mesh = bed_mesh
	bed.position = Vector3(0, 0.42, 0.25)
	bed.material_override = _detail_material(Color(0.56, 0.43, 0.30))
	sleep_hut.add_child(bed)
	var bed_marker := Area3D.new()
	bed_marker.name = "SleepInteraction"
	bed_marker.position = Vector3(0, 0.4, 0.25)
	bed_marker.add_to_group("sleep_bed")
	sleep_hut.add_child(bed_marker)
	var bed_shape := CollisionShape3D.new()
	var bed_sphere := SphereShape3D.new()
	bed_sphere.radius = 1.8
	bed_shape.shape = bed_sphere
	bed_marker.add_child(bed_shape)
	var sign := Label3D.new()
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.text = "DESCANSAR\n[E]"
	sign.position = Vector3(0, 2.0, -1.55)
	sign.font_size = 32
	sign.modulate = Color(0.9, 1.0, 0.84)
	sleep_hut.add_child(sign)
	_add_box_collision(sleep_hut, Vector3(0, 0.45, 1.35), Vector3(3.4, 0.9, 0.25))

func _start_new_day() -> void:
	if is_day:
		if hud:
			hud.show_message("La cama solo permite iniciar el día durante la noche.")
		return
	is_day = true
	day_time = 0.0
	_on_phase_changed()
	if hud:
		hud.show_message("¡Nuevo día! El bosque te espera.")

func _is_clear_location(location: Vector3, clearance: float) -> bool:
	if location.length() < 8.0:
		return false
	if Vector2(location.x + 18.0, location.z + 20.0).length() < 8.0:
		return false
	for reserved in reserved_positions:
		if Vector2(location.x, location.z).distance_to(Vector2(reserved.x, reserved.z)) < clearance:
			return false
	return true

func _create_hud() -> void:
	hud = HUD_SCRIPT.new() as TRushHUD
	add_child(hud)
	hud.upgrade_requested.connect(_buy_upgrade)
	hud.options_changed.connect(_apply_options)
	hud.prestige_requested.connect(_perform_prestige)
	hud.skill_requested.connect(_spend_skill_point)
	player.skill_requested.connect(hud.toggle_skills)
	hud.bestiary_toggled.connect(hud.toggle_bestiary)
	hud.set_upgrade_access(not is_day)
	hud.update_mission("Recolecta residuos y llévalos a reciclar")
	hud.update_skill_status(player_level, skill_points, skill_levels)
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	_refresh_bestiary()

func _on_pause_requested() -> void:
	if hud:
		hud.toggle_pause()

func _apply_options(brightness: float, music_volume: float, effects_volume: float, fov: float) -> void:
	if world_environment and world_environment.environment:
		world_environment.environment.ambient_light_energy = 0.65 * brightness
		world_environment.environment.tonemap_exposure = brightness
	if player and player.game_camera:
		player.game_camera.fov = fov
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_linear(music_bus, music_volume)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_linear(sfx_bus, effects_volume)

func _on_inventory_changed(current: int, capacity: int) -> void:
	if hud:
		hud.update_bag(current, capacity)

func _on_trash_collected(_value: int) -> void:
	collected_trash += 1
	_add_player_xp(2)
	_check_restoration()

func _on_deposit_requested() -> void:
	var deposited_items := player.bag_count
	var amount := player.collect_bag_contents()
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_deposit_time <= 45.0:
		combo_multiplier = minf(2.5, combo_multiplier + 0.25 + float(skill_levels["combo"]) * 0.1)
	else:
		combo_multiplier = 1.0
	last_deposit_time = now
	var combo_bonus := 1.0 + 0.15 * (float(maxi(0, deposited_items - 5)) / 5.0)
	var earned := int(round(float(amount) * (1.0 + int(upgrades["value"])) * combo_multiplier * combo_bonus))
	money += earned
	hud.update_money(money)
	hud.update_mission("Sigue explorando y recupera el ecosistema")
	if station:
		var pulse := create_tween()
		pulse.tween_property(station, "scale", Vector3.ONE * 1.12, 0.12)
		pulse.tween_property(station, "scale", Vector3.ONE, 0.2)
	hud.show_message("¡Reciclaje! +$%d · Combo x%.2f" % [earned, combo_multiplier])
	_add_player_xp(deposited_items * 3)
	_save_game()

func _restoration_percent() -> int:
	if total_trash <= 0:
		return 100
	return mini(100, int(round(float(collected_trash) / float(total_trash) * 100.0)))

func _check_restoration() -> void:
	var percent := _restoration_percent()
	hud.update_progress(percent)
	var milestones := [
		{"percent": 25, "name": "Hornero", "id": "bird", "description": "Ave nativa que construye nidos de barro y ayuda a mantener el equilibrio del ecosistema.", "message": "¡Regresó el hornero al bosque!"},
		{"percent": 60, "name": "Zorro gris", "id": "fox", "description": "Mamífero omnívoro que dispersa semillas y contribuye al control de pequeños animales.", "message": "¡Se observó un zorro gris en el bioma!"},
		{"percent": 100, "name": "Venado de campo", "id": "deer", "description": "Herbívoro nativo de pastizales y ambientes abiertos; su presencia indica un hábitat más saludable.", "message": "¡El venado de campo volvió al ecosistema! Bioma restaurado."}
	]
	for milestone in milestones:
		var species_name: String = milestone["name"]
		if percent >= int(milestone["percent"]) and not species_unlocked.has(species_name):
			species_unlocked.append(species_name)
			hud.show_message(milestone["message"])
			_spawn_species_marker(milestone)
			_refresh_bestiary()
			if hud:
				hud.update_mission("Sigue limpiando para recuperar el ecosistema")
			_save_game()

func _spawn_species_marker(species: Dictionary) -> void:
	var actor := WILDLIFE_SCRIPT.new() as TRushWildlife
	actor.species_id = str(species["id"])
	actor.position = Vector3(randf_range(-7.0, 7.0), 0.0, randf_range(-7.0, 7.0))
	actor.name = "Wildlife_" + str(species["id"])
	add_child(actor)
	if not is_day:
		actor.set_night_resting(true)

func _restore_unlocked_wildlife() -> void:
	for species in _species_catalog():
		if species_unlocked.has(str(species["name"])):
			_spawn_species_marker(species)

func _refresh_bestiary() -> void:
	if hud == null:
		return
	var unlocked: Array[Dictionary] = []
	for species in _species_catalog():
		if species_unlocked.has(str(species["name"])):
			unlocked.append(species)
	hud.set_bestiary(unlocked)

func _species_catalog() -> Array[Dictionary]:
	return [
		{"name": "Hornero", "id": "bird", "description": "Ave nativa que construye nidos de barro y ayuda a mantener el equilibrio del ecosistema."},
		{"name": "Zorro gris", "id": "fox", "description": "Mamífero omnívoro que dispersa semillas y contribuye al control de pequeños animales."},
		{"name": "Venado de campo", "id": "deer", "description": "Herbívoro nativo de pastizales y ambientes abiertos; su presencia indica un hábitat más saludable."}
	]

func _upgrade_cost(upgrade_id: String) -> int:
	var level := int(upgrades[upgrade_id])
	var base_cost := {"speed": 40, "capacity": 55, "value": 70, "range": 45, "day": 60, "vacuum": 240, "discount": 180}
	var discount_factor := pow(0.92, float(upgrades.get("discount", 0)))
	return maxi(1, int(round(float(base_cost.get(upgrade_id, 50)) * float(level + 1) * discount_factor)))

func _buy_upgrade(upgrade_id: String) -> void:
	if is_day:
		hud.show_message("Las mejoras solo se compran de noche.")
		return
	if not upgrades.has(upgrade_id):
		return
	var cost := _upgrade_cost(upgrade_id)
	if money < cost:
		hud.show_message("Fondos insuficientes. Necesitas $%d." % cost)
		return
	money -= cost
	upgrades[upgrade_id] = int(upgrades[upgrade_id]) + 1
	_apply_upgrades()
	hud.update_money(money)
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	hud.show_message("Mejora adquirida: %s · -$%d" % [upgrade_id, cost])
	_save_game()

func _apply_upgrades() -> void:
	if player == null:
		return
	if int(upgrades.get("vacuum", 0)) > 0:
		player.unlock_vacuum()
	var vacuum_level := int(upgrades.get("vacuum", 0))
	player.vacuum_radius = (3.2 + float(maxi(0, vacuum_level - 1)) * 0.85) + float(skill_levels.get("magnet", 0)) * 0.35
	player.vacuum_pull_time = maxf(0.08, 0.24 - float(maxi(0, vacuum_level - 1)) * 0.025)
	player.walk_speed = 5.0 + float(upgrades["speed"]) * 0.7
	player.sprint_speed = 8.0 + float(upgrades["speed"]) * 0.9
	if int(upgrades["capacity"]) > 0:
		var target_capacity := 5 + 2 * int(upgrades["capacity"])
		var capacity_increase := target_capacity - player.bag_capacity
		if capacity_increase > 0:
			player.increase_capacity(capacity_increase)
	player.interaction_range = 5.0 + float(upgrades["range"]) * 1.0

func _perform_prestige() -> void:
	if _restoration_percent() < 98:
		hud.show_message("Necesitas restaurar al menos el 98% del bioma para prestigiar.")
		return
	prestige_count += 1
	collected_trash = 0
	total_trash = 0
	for trash in get_tree().get_nodes_in_group("garbage"):
		trash.queue_free()
	await get_tree().create_timer(0.2).timeout
	_spawn_trash()
	money += 100 * prestige_count
	hud.update_progress(0)
	hud.update_money(money)
	hud.show_message("¡Prestigio %d! Mejoras conservadas y +$%d." % [prestige_count, 100 * prestige_count])
	_save_game()

func _update_hud() -> void:
	if hud:
		hud.update_money(money)
		hud.update_bag(player.bag_count, player.bag_capacity)
		hud.update_progress(_restoration_percent())


func _open_shop() -> void:
	if hud:
		hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
		hud.show_shop(not hud.shop_open)

func _all_upgrade_costs() -> Dictionary:
	var costs := {}
	for upgrade_id in upgrades:
		costs[upgrade_id] = _upgrade_cost(str(upgrade_id))
	return costs

func _add_player_xp(amount: int) -> void:
	player_xp += amount
	var next_level_xp := player_level * 30
	while player_xp >= next_level_xp:
		player_xp -= next_level_xp
		player_level += 1
		skill_points += 1
		next_level_xp = player_level * 30
		if hud:
			hud.notify_level_up(player_level)
			hud.show_message("¡Nivel %d! Ganaste 1 punto de habilidad." % player_level)
	if hud:
		hud.update_skill_status(player_level, skill_points, skill_levels)

func _spend_skill_point(skill_id: String = "agility") -> void:
	if skill_points <= 0 or not skill_levels.has(skill_id):
		if hud:
			hud.show_message("Necesitas puntos de habilidad. Gana XP reciclando.")
		return
	skill_points -= 1
	skill_levels[skill_id] = int(skill_levels[skill_id]) + 1
	if skill_id == "agility" and player:
		player.walk_speed += 0.35
		player.sprint_speed += 0.45
	elif skill_id == "capacity" and player:
		player.increase_capacity(1)
	elif skill_id == "magnet" and player:
		player.vacuum_radius += 0.35
	elif skill_id == "combo":
		combo_multiplier = minf(2.5, combo_multiplier + 0.1)
	hud.update_skill_status(player_level, skill_points, skill_levels)
	hud.show_message("Habilidad mejorada: %s" % skill_id)
	_save_game()

func _create_pond() -> void:
	var pond := Node3D.new()
	pond.name = "LilyPond"
	pond.position = Vector3(-18.0, 0.0, -20.0)
	add_child(pond)
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 5.8
	water_mesh.bottom_radius = 5.8
	water_mesh.height = 0.18
	water.mesh = water_mesh
	water.position.y = -0.05
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.10, 0.38, 0.43)
	water_material.metallic = 0.18
	water_material.roughness = 0.12
	water.material_override = water_material
	pond.add_child(water)
	var rng := RandomNumberGenerator.new()
	rng.seed = 62381 + prestige_count
	var lily_positions: Array[Vector3] = []
	var attempts := 0
	while lily_positions.size() < 4 and attempts < 80:
		attempts += 1
		var candidate := Vector3(rng.randf_range(-3.65, 3.65), 0.08, rng.randf_range(-3.65, 3.65))
		if candidate.length() > 4.55 or candidate.length() < 1.15:
			continue
		var spaced := true
		for existing in lily_positions:
			if candidate.distance_to(existing) < 1.65:
				spaced = false
				break
		if spaced:
			lily_positions.append(candidate)
	for lily_index in range(lily_positions.size()):
		var lily := MeshInstance3D.new()
		var lily_mesh := CylinderMesh.new()
		lily_mesh.top_radius = 0.62
		lily_mesh.bottom_radius = 0.62
		lily_mesh.height = 0.06
		lily.mesh = lily_mesh
		lily.position = lily_positions[lily_index]
		lily.rotation.y = rng.randf_range(0.0, TAU)
		var lily_material := StandardMaterial3D.new()
		lily_material.albedo_color = Color(0.20, 0.48, 0.25)
		lily.material_override = lily_material
		pond.add_child(lily)
		if lily_index == 0:
			var frog := MeshInstance3D.new()
			var frog_mesh := SphereMesh.new()
			frog_mesh.radial_segments = 32
			frog_mesh.rings = 20
			frog_mesh.radius = 0.18
			frog_mesh.height = 0.22
			frog.mesh = frog_mesh
			frog.position = lily.position + Vector3(0.0, 0.16, 0.0)
			var frog_material := _detail_material(Color(0.28, 0.55, 0.22))
			frog.material_override = frog_material
			pond.add_child(frog)
			var eye_material := _detail_material(Color(0.025, 0.022, 0.018))
			for eye_side in [-1.0, 1.0]:
				var frog_eye := MeshInstance3D.new()
				var eye_mesh := SphereMesh.new()
				eye_mesh.radial_segments = 24
				eye_mesh.rings = 16
				eye_mesh.radius = 0.035
				eye_mesh.height = 0.07
				frog_eye.mesh = eye_mesh
				frog_eye.position = frog.position + Vector3(eye_side * 0.085, 0.055, -0.105)
				frog_eye.material_override = eye_material
				pond.add_child(frog_eye)
			for leg_side in [-1.0, 1.0]:
				var rear_leg := MeshInstance3D.new()
				var leg_mesh := CapsuleMesh.new()
				leg_mesh.radius = 0.055
				leg_mesh.height = 0.27
				rear_leg.mesh = leg_mesh
				rear_leg.position = frog.position + Vector3(leg_side * 0.19, -0.045, 0.13)
				rear_leg.rotation.z = leg_side * -0.65
				rear_leg.material_override = frog_material
				pond.add_child(rear_leg)

func _create_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41827
	for cloud_index in range(6):
		var cloud := Node3D.new()
		cloud.name = "Cloud_%d" % cloud_index
		cloud.position = Vector3(rng.randf_range(-65, 65), rng.randf_range(27, 35), rng.randf_range(-60, 60))
		cloud.set_meta("speed", rng.randf_range(0.55, 1.15))
		add_child(cloud)
		var cloud_material := StandardMaterial3D.new()
		cloud_material.albedo_color = Color(0.88, 0.92, 0.94)
		for puff in range(12):
			var puff_node := MeshInstance3D.new()
			var puff_mesh := SphereMesh.new()
			puff_mesh.radial_segments = 24
			puff_mesh.rings = 16
			puff_mesh.radius = rng.randf_range(1.0, 2.0)
			puff_mesh.height = puff_mesh.radius * 0.8
			puff_node.mesh = puff_mesh
			puff_node.position = Vector3(rng.randf_range(-3.5, 3.5), rng.randf_range(-0.5, 0.6), rng.randf_range(-1.2, 1.2))
			puff_node.material_override = cloud_material
			cloud.add_child(puff_node)
		cloud_nodes.append(cloud)

func _update_clouds(delta: float) -> void:
	for cloud in cloud_nodes:
		cloud.position.x += float(cloud.get_meta("speed", 0.8)) * delta
		if cloud.position.x > 75.0:
			cloud.position.x = -75.0

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("economy", "money", money)
	config.set_value("progress", "prestige", prestige_count)
	config.set_value("progress", "collected_trash", collected_trash)
	config.set_value("progress", "species_unlocked", species_unlocked)
	config.set_value("progress", "unlocked_zones", unlocked_zones)
	config.set_value("upgrades", "levels", upgrades)
	config.set_value("skills", "levels", skill_levels)
	config.set_value("skills", "points", skill_points)
	config.set_value("skills", "xp", player_xp)
	config.set_value("skills", "level", player_level)
	config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	money = int(config.get_value("economy", "money", 0))
	prestige_count = int(config.get_value("progress", "prestige", 0))
	collected_trash = int(config.get_value("progress", "collected_trash", 0))
	var saved_species: Variant = config.get_value("progress", "species_unlocked", [])
	species_unlocked.clear()
	if saved_species is Array:
		for species_id in saved_species:
			species_unlocked.append(str(species_id))

	var saved_zones: Variant = config.get_value("progress", "unlocked_zones", [])
	unlocked_zones.clear()
	if saved_zones is Array:
		for zone_id in saved_zones:
			unlocked_zones.append(str(zone_id))
	var saved_upgrades: Dictionary = config.get_value("upgrades", "levels", upgrades)
	for key in upgrades:
		upgrades[key] = int(saved_upgrades.get(key, 0))
	var saved_skills: Dictionary = config.get_value("skills", "levels", skill_levels)
	for key in skill_levels:
		skill_levels[key] = int(saved_skills.get(key, 0))
	skill_points = int(config.get_value("skills", "points", 0))
	player_xp = int(config.get_value("skills", "xp", 0))
	player_level = int(config.get_value("skills", "level", 1))
