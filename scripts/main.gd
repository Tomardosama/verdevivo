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
var upgrades := {"speed": 0, "capacity": 0, "value": 0, "range": 0, "day": 0}
var species_unlocked: Array[String] = []
var notification_cooldown: float = 0.0
var station: Node3D
var session_start_time: float = 0.0
var unlocked_zones: Array[String] = []

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
	day_time += delta
	notification_cooldown = maxf(0.0, notification_cooldown - delta)
	var duration := _current_phase_duration()
	if day_time >= duration:
		day_time = 0.0
		is_day = not is_day
		_on_phase_changed()
	_update_sun()
	_update_clouds(delta)
	_check_zone_unlocks()
	if hud:
		hud.update_phase(is_day, int(ceil(duration - day_time)))
		hud.update_stats(money, collected_trash, prestige_count, int(Time.get_ticks_msec() / 1000.0 - session_start_time))

func _current_phase_duration() -> float:
	return day_duration + float(upgrades["day"]) * 30.0 if is_day else night_duration

func _on_phase_changed() -> void:
	if player:
		player.collection_enabled = is_day
	if hud:
		hud.set_upgrade_access(not is_day)
		hud.show_message("Comienza el día: ¡a limpiar!" if is_day else "Llegó la noche: momento de invertir en mejoras.")
	for actor in get_tree().get_nodes_in_group("wildlife"):
		if actor.has_method("set_night_resting"):
			actor.set_night_resting(not is_day)
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
		_create_tree(trees, Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	_populate_ground_detail(rng, trees)
	_create_zone_markers()
	_create_clouds()

func _create_tree(parent: Node3D, location: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = location
	parent.add_child(tree)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 2.4
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.2
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.28, 0.16, 0.09)
	trunk.material_override = bark
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.35
	crown_mesh.height = 2.7
	crown.mesh = crown_mesh
	crown.position.y = 3.0
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.10 + randf() * 0.08, 0.27 + randf() * 0.12, 0.12 + randf() * 0.07)
	leaves.roughness = 1.0
	crown.material_override = leaves
	tree.add_child(crown)
	var crown_second := MeshInstance3D.new()
	var crown_mesh_second := SphereMesh.new()
	crown_mesh_second.radius = 0.95
	crown_mesh_second.height = 1.9
	crown_second.mesh = crown_mesh_second
	crown_second.position = Vector3(0.65, 3.25, 0.15)
	crown_second.material_override = leaves
	tree.add_child(crown_second)
	tree.rotation.y = randf_range(0.0, TAU)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as TRushPlayer
	add_child(player)
	player.global_position = Vector3(0, 1, 7)
	player.inventory_changed.connect(_on_inventory_changed)
	player.deposit_requested.connect(_on_deposit_requested)
	player.trash_collected.connect(_on_trash_collected)
	player.shop_requested.connect(_open_shop)
	player.shop_preview_changed.connect(_on_shop_preview_changed)

func _spawn_trash() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90317 + prestige_count
	var target_count := maxi(starting_trash_count, 48)
	var first_remaining := clampi(collected_trash, 0, target_count)
	var type_names := ["Botella plastica", "Lata de aluminio", "Papel y carton", "Envase de vidrio"]
	var rewards := [5, 8, 6, 12]
	var colors := [Color(0.20, 0.55, 0.72), Color(0.72, 0.76, 0.78), Color(0.72, 0.57, 0.32), Color(0.25, 0.62, 0.48)]
	for i in range(first_remaining, target_count):
		var trash := TRASH_SCENE.instantiate() as TrashPickup
		var location := Vector3.ZERO
		for attempt in range(20):
			location = Vector3(rng.randf_range(-49.0, 49.0), 0.0, rng.randf_range(-49.0, 49.0))
			if location.length() > 7.0:
				break
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
				1:
					var can := CylinderMesh.new()
					can.top_radius = 0.14
					can.bottom_radius = 0.14
					can.height = 0.34
					visual.mesh = can
				2:
					var paper := BoxMesh.new()
					paper.size = Vector3(0.34, 0.035, 0.27)
					visual.mesh = paper
					visual.position.y = 0.05
				3:
					var glass := SphereMesh.new()
					glass.radius = 0.19
					glass.height = 0.38
					visual.mesh = glass
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
	for i in range(360):
		var tuft := Node3D.new()
		tuft.position = Vector3(rng.randf_range(-57, 57), 0.0, rng.randf_range(-57, 57))
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
	for i in range(95):
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radial_segments = 24
		rock_mesh.rings = 16
		rock_mesh.radius = rng.randf_range(0.22, 0.72)
		rock_mesh.height = rock_mesh.radius * rng.randf_range(0.75, 1.35)
		rock.mesh = rock_mesh
		rock.position = Vector3(rng.randf_range(-56, 56), rock_mesh.radius * 0.34, rng.randf_range(-56, 56))
		rock.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.55, 0.9), rng.randf_range(0.8, 1.5))
		rock.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2))
		rock.material_override = rock_material
		parent.add_child(rock)
		for fragment_index in range(3):
			var fragment := MeshInstance3D.new()
			var fragment_mesh := SphereMesh.new()
			fragment_mesh.radial_segments = 16
			fragment_mesh.rings = 10
			fragment_mesh.radius = rng.randf_range(0.12, 0.28)
			fragment_mesh.height = fragment_mesh.radius * rng.randf_range(0.7, 1.2)
			fragment.mesh = fragment_mesh
			fragment.position = rock.position + Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.08, 0.08), rng.randf_range(-0.4, 0.4))
			fragment.material_override = rock_material
			parent.add_child(fragment)

func _create_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44219
	for cloud_index in range(5):
		var cloud := Node3D.new()
		cloud.name = "Cloud_%d" % cloud_index
		cloud.position = Vector3(rng.randf_range(-65.0, 65.0), rng.randf_range(25.0, 34.0), rng.randf_range(-55.0, 55.0))
		cloud.set_meta("drift_speed", rng.randf_range(0.8, 1.7))
		add_child(cloud)
		var cloud_material := StandardMaterial3D.new()
		cloud_material.albedo_color = Color(0.88, 0.92, 0.91, 0.88)
		cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud_material.roughness = 1.0
		var lobes := rng.randi_range(9, 14)
		for lobe_index in range(lobes):
			var lobe := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radial_segments = 24
			sphere.rings = 16
			sphere.radius = rng.randf_range(0.8, 1.8)
			sphere.height = sphere.radius * rng.randf_range(0.65, 1.0)
			lobe.mesh = sphere
			lobe.position = Vector3(rng.randf_range(-2.6, 2.6), rng.randf_range(-0.35, 0.55), rng.randf_range(-0.9, 0.9))
			lobe.scale = Vector3(rng.randf_range(0.85, 1.35), 1.0, rng.randf_range(0.8, 1.2))
			lobe.material_override = cloud_material
			cloud.add_child(lobe)

func _update_clouds(delta: float) -> void:
	for cloud in get_children():
		if cloud.name.begins_with("Cloud_"):
			cloud.position.x += float(cloud.get_meta("drift_speed", 1.0)) * delta
			if cloud.position.x > 72.0:
				cloud.position.x = -72.0

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
	var sign := Label3D.new()
	sign.text = "RECICLAJE\n[E]"
	sign.position.y = 1.6
	sign.font_size = 48
	sign.modulate = Color(0.85, 1.0, 0.88)
	station.add_child(sign)
	_create_upgrade_shop()

func _create_upgrade_shop() -> void:
	var shop := Node3D.new()
	shop.name = "ForestUpgradeShop"
	shop.position = Vector3(4.2, 0.0, 1.2)
	shop.add_to_group("upgrade_shop")
	add_child(shop)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.34, 0.22, 0.12)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.16, 0.38, 0.24)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(3.2, 1.8, 2.0)
	body.mesh = body_mesh
	body.position.y = 0.9
	body.material_override = wood
	shop.add_child(body)
	var counter := MeshInstance3D.new()
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(3.5, 0.22, 0.7)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.0, 1.15, 1.15)
	counter.material_override = green
	shop.add_child(counter)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(3.8, 0.25, 2.5)
	roof.mesh = roof_mesh
	roof.position.y = 2.05
	roof.material_override = green
	shop.add_child(roof)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.09
		post_mesh.bottom_radius = 0.11
		post_mesh.height = 2.0
		post.mesh = post_mesh
		post.position = Vector3(side * 1.65, 1.0, 0.0)
		post.material_override = wood
		shop.add_child(post)
	var sign := Label3D.new()
	sign.text = "TIENDA DE MEJORAS\n[E] INTERACTUAR · [TAB] VISTA RAPIDA"
	sign.position = Vector3(0.0, 2.55, 0.0)
	sign.font_size = 28
	sign.modulate = Color(0.88, 1.0, 0.83)
	shop.add_child(sign)

func _create_hud() -> void:
	hud = HUD_SCRIPT.new() as TRushHUD
	add_child(hud)
	hud.upgrade_requested.connect(_buy_upgrade)
	hud.prestige_requested.connect(_perform_prestige)
	hud.bestiary_toggled.connect(hud.toggle_bestiary)
	hud.set_upgrade_access(not is_day)
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	hud.update_mission("Recolecta residuos y llévalos a reciclar")
	_refresh_bestiary()

func _open_shop() -> void:
	if hud:
		var should_open := not hud.shop_open
		hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
		hud.show_shop(should_open)
		if not should_open:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_shop_preview_changed(visible: bool) -> void:
	if hud:
		hud.show_shop(visible)

func _all_upgrade_costs() -> Dictionary:
	var costs := {}
	for upgrade_id in upgrades:
		costs[upgrade_id] = _upgrade_cost(str(upgrade_id))
	return costs

func _on_inventory_changed(current: int, capacity: int) -> void:
	if hud:
		hud.update_bag(current, capacity)

func _on_trash_collected(_value: int) -> void:
	collected_trash += 1
	_check_restoration()

func _on_deposit_requested() -> void:
	var amount := player.collect_bag_contents()
	var earned := amount * (1 + int(upgrades["value"]))
	money += earned
	hud.update_money(money)
	hud.update_mission("Sigue explorando y recupera el ecosistema")
	if station:
		var pulse := create_tween()
		pulse.tween_property(station, "scale", Vector3.ONE * 1.12, 0.12)
		pulse.tween_property(station, "scale", Vector3.ONE, 0.2)
	hud.show_message("¡Reciclaje completado! +$%d" % earned)
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
	var base_cost := {"speed": 40, "capacity": 55, "value": 70, "range": 45, "day": 60}
	return int(base_cost[upgrade_id]) * (level + 1)

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
	player.walk_speed = 5.0 + float(upgrades["speed"]) * 0.7
	player.sprint_speed = 8.0 + float(upgrades["speed"]) * 0.9
	if int(upgrades["capacity"]) > 0:
		var target_capacity := 5 + 2 * int(upgrades["capacity"])
		var capacity_increase := target_capacity - player.bag_capacity
		if capacity_increase > 0:
			player.increase_capacity(capacity_increase)
	player.interaction_range = 5.0 + float(upgrades["range"]) * 1.0

func _perform_prestige() -> void:
	if _restoration_percent() < 100:
		hud.show_message("Necesitas restaurar el bioma al 100% para prestigiar.")
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

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("economy", "money", money)
	config.set_value("progress", "prestige", prestige_count)
	config.set_value("progress", "collected_trash", collected_trash)
	config.set_value("progress", "species_unlocked", species_unlocked)
	config.set_value("progress", "unlocked_zones", unlocked_zones)
	config.set_value("upgrades", "levels", upgrades)
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
