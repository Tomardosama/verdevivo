extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TRASH_SCENE := preload("res://scenes/garbage/trash.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const SAVE_PATH := "user://trush_save.cfg"

@export_group("World")
@export var starting_trash_count: int = 24
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

func _ready() -> void:
	_build_world()
	_load_game()
	_spawn_player()
	_spawn_trash()
	_spawn_station()
	_create_hud()
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
	if hud:
		hud.update_phase(is_day, int(ceil(duration - day_time)))

func _current_phase_duration() -> float:
	return day_duration + float(upgrades["day"]) * 30.0 if is_day else night_duration

func _on_phase_changed() -> void:
	if player:
		player.collection_enabled = is_day
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
	plane.size = Vector3(60, 1, 60)
	ground_mesh.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.20, 0.32, 0.19)
	ground_mesh.material_override = ground_material
	ground.add_child(ground_mesh)
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
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
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		var radius := 13.0 + float(i % 4) * 2.0
		_create_tree(trees, Vector3(cos(angle) * radius, 0, sin(angle) * radius))

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
	leaves.albedo_color = Color(0.12, 0.34, 0.16)
	crown.material_override = leaves
	tree.add_child(crown)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as TRushPlayer
	add_child(player)
	player.global_position = Vector3(0, 1, 7)
	player.inventory_changed.connect(_on_inventory_changed)
	player.deposit_requested.connect(_on_deposit_requested)
	player.trash_collected.connect(_on_trash_collected)

func _spawn_trash() -> void:
	var positions := [
		Vector3(-3, 0, 1), Vector3(2, 0, 0), Vector3(4, 0, 3), Vector3(-5, 0, 4),
		Vector3(1, 0, -4), Vector3(-2, 0, -5), Vector3(6, 0, -3), Vector3(-7, 0, -2),
		Vector3(8, 0, 5), Vector3(0, 0, -8), Vector3(-9, 0, 7), Vector3(10, 0, -7),
		Vector3(3, 0, 8), Vector3(-4, 0, -9), Vector3(7, 0, 9), Vector3(-10, 0, -6),
		Vector3(11, 0, 1), Vector3(-1, 0, 10), Vector3(5, 0, -11), Vector3(-6, 0, 11),
		Vector3(12, 0, -3), Vector3(-12, 0, 2), Vector3(9, 0, -10), Vector3(-9, 0, -11)
	]
	for i in range(mini(starting_trash_count, positions.size())):
		var trash := TRASH_SCENE.instantiate() as TrashPickup
		trash.position = positions[i]
		var material := StandardMaterial3D.new()
		var colors := [Color(0.75, 0.78, 0.72), Color(0.75, 0.48, 0.18), Color(0.22, 0.48, 0.72)]
		material.albedo_color = colors[i % colors.size()]
		var visual := trash.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if visual:
			visual.material_override = material
		add_child(trash)
	total_trash = mini(starting_trash_count, positions.size())

func _spawn_station() -> void:
	var station := Node3D.new()
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
	var sign := Label3D.new()
	sign.text = "RECICLAJE\n[E]"
	sign.position.y = 1.6
	sign.font_size = 48
	sign.modulate = Color(0.85, 1.0, 0.88)
	station.add_child(sign)

func _create_hud() -> void:
	hud = HUD_SCRIPT.new() as TRushHUD
	add_child(hud)
	hud.upgrade_requested.connect(_buy_upgrade)
	hud.prestige_requested.connect(_perform_prestige)
	hud.set_upgrade_access(not is_day)

func _on_inventory_changed(current: int, capacity: int) -> void:
	if hud:
		hud.update_bag(current, capacity)

func _on_trash_collected(_value: int) -> void:
	collected_trash += 1
	_check_restoration()

func _on_deposit_requested() -> void:
	var amount := player.collect_bag_contents()
	var earned := amount * value_per_trash * (1 + int(upgrades["value"]))
	money += earned
	hud.update_money(money)
	hud.show_message("Reciclaste %d residuos · +$%d" % [amount, earned])
	_save_game()

func _restoration_percent() -> int:
	if total_trash <= 0:
		return 100
	return mini(100, int(round(float(collected_trash) / float(total_trash) * 100.0)))

func _check_restoration() -> void:
	var percent := _restoration_percent()
	hud.update_progress(percent)
	var milestones := [
		{"percent": 25, "name": "Aves del bosque", "message": "¡La limpieza permite el regreso de las aves!"},
		{"percent": 60, "name": "Pequeños mamíferos", "message": "¡Vuelven los pequeños mamíferos al bioma!"},
		{"percent": 100, "name": "Bosque restaurado", "message": "¡Bioma restaurado al 100%! Has desbloqueado el prestigio."}
	]
	for milestone in milestones:
		var species_name: String = milestone["name"]
		if percent >= int(milestone["percent"]) and not species_unlocked.has(species_name):
			species_unlocked.append(species_name)
			hud.show_message(milestone["message"])
			_spawn_species_marker(species_name)
			_save_game()

func _spawn_species_marker(species_name: String) -> void:
	var marker := Label3D.new()
	marker.text = "✦ " + species_name
	marker.position = Vector3(randf_range(-7.0, 7.0), 2.4, randf_range(-7.0, 7.0))
	marker.font_size = 36
	marker.modulate = Color(0.85, 1.0, 0.75)
	add_child(marker)

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
	config.set_value("upgrades", "levels", upgrades)
	config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	money = int(config.get_value("economy", "money", 0))
	prestige_count = int(config.get_value("progress", "prestige", 0))
	collected_trash = int(config.get_value("progress", "collected_trash", 0))
	species_unlocked = config.get_value("progress", "species_unlocked", [])
	var saved_upgrades: Dictionary = config.get_value("upgrades", "levels", upgrades)
	for key in upgrades:
		upgrades[key] = int(saved_upgrades.get(key, 0))
