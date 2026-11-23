extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TRASH_SCENE := preload("res://scenes/garbage/trash.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const WILDLIFE_SCRIPT := preload("res://scripts/environment/wildlife_actor.gd")
const WORLD_REGION_BUILDER := preload("res://scripts/environment/world_region_generator.gd")
const NATURE_ASSET_SCATTER := preload("res://scripts/environment/nature_asset_scatter.gd")
const BOSS_SCENE := preload("res://scenes/boss/garbage_mountain_boss.tscn")
const POND_FROG_SCRIPT := preload("res://scripts/environment/pond_frog.gd")
const FRUIT_BASKET_SCRIPT := preload("res://scripts/environment/fruit_basket.gd")
const SIGN_SCRIPT := preload("res://scripts/environment/player_facing_sign.gd")
const WORLD_MAP_DATA := preload("res://scripts/environment/world_map_data.gd")
const CLEANER_SCENE := preload("res://scenes/environment/portable_cleaner.tscn")
const SAVE_PATH := "user://trush_save.cfg"
const BOSS_CONFIG_PATH := "res://data/bosses/garbage_mountains.json"
const CLEANER_BALANCE_PATH := "res://data/economy/automated_cleaner.json"
const PROGRESSION_BALANCE_PATH := "res://data/economy/progression.json"

@export_group("World")
@export var starting_trash_count: int = 48
@export var day_duration: float = 210.0
@export var night_duration: float = 90.0
@export var value_per_trash: int = 5
@export_range(1, 8, 1) var boss_spawn_limit: int = 3
@export_range(20.0, 240.0, 5.0) var radar_range: float = 90.0

var player: TRushPlayer
var hud: TRushHUD
var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var money: int = 0
var total_trash: int = 0
var collected_trash: int = 0
var world_trash_collected: int = 0
var collected_item_was_boss_drop: bool = false
var day_time: float = 0.0
var is_day: bool = true
var prestige_count: int = 0
var upgrades := {"speed": 0, "capacity": 0, "value": 0, "range": 0, "day": 0, "vacuum": 0, "discount": 0, "daily_quota": 0}
var progression_balance: Dictionary = {}
var daily_target: int = 200
var daily_collected_count: int = 0
var daily_ordinary_money_earned: int = 0
var daily_pending_ordinary_units: int = 0
var daily_bonus_paid: bool = false
var daily_completed_days: int = 0
var prestige_points: int = 0
var prestige_history: Array[Dictionary] = []
var prestige_permanent_upgrades: Dictionary = {}
var prestige_confirmation_pending: bool = false
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
var current_daily_trash: Array[TrashPickup] = []
var shop_node: Node3D
var sleep_hut: Node3D
<<<<<<< Updated upstream
var graphics_quality: int = 1
var autosave_elapsed: float = 0.0
var saved_player_health: float = 100.0
=======
var fruit_basket: Node3D
var roots_lookout: Node3D
var minimap_update_timer: float = 0.0
var autosave_timer: float = 0.0
var radar_unlocked: bool = false
var radar_active: bool = false
var saved_player_state: Dictionary = {}
var boss_encounters: Dictionary = {}
var day_number: int = 1
var daily_fruit_remaining: int = 3
var last_boost_hud_key: String = ""
var tree_foliage_transforms: Array[Transform3D] = []
var tree_foliage_colors: Array[Color] = []
var world_regions: Node3D
var world_trash_budget := 240
var active_bosses: Array[Node3D] = []
var boss_configurations: Array[Dictionary] = []
var defeated_boss_ids: Array[String] = []
var boss_progress: Dictionary = {}
var boss_drop_records: Array[Dictionary] = []
var queued_boss_drops: Array[Dictionary] = []
var boss_drops_generated_total: int = 0
var next_boss_drop_id: int = 1
var boss_save_timer: float = 0.0
var trash_visual_meshes: Dictionary = {}
var cleaner_balance: Dictionary = {}
var cleaner_installations: Array[Dictionary] = []
var cleaner_owned_count: int = 0
var cleaner_pending_installation: bool = false
var cleaner_carried_machine: Node3D
var cleaner_selected_id: String = ""
var cleaner_owned: bool = false
var cleaner_installed: bool = false
var cleaner_operational: bool = true
var cleaner_location_id: String = ""
var cleaner_install_position: Vector3 = Vector3.ZERO
var cleaner_income_level: int = 0
var cleaner_storage_level: int = 0
var cleaner_stored_money: int = 0
var cleaner_elapsed_seconds: float = 0.0
var cleaner_machine: Node3D
var cleaner_preview: Node3D
var cleaner_preview_valid: bool = false
var cleaner_preview_location: String = ""
var cleaner_preview_position: Vector3 = Vector3.ZERO
var cleaner_preview_yaw: float = 0.0
var boss_intro_no_vacuum_shown: bool = false
var boss_intro_vacuum_shown: bool = false
var boss_intro_tracking_initialized: bool = false
var boss_area_player_inside: bool = false
var boss_intro_cooldown: float = 0.0
>>>>>>> Stashed changes

func _ready() -> void:
	session_start_time = Time.get_ticks_msec() / 1000.0
	_load_cleaner_balance()
	_load_progression_balance()
	_build_world()
	_load_game()
	_refresh_radar_prompt()
	_spawn_player()
	_spawn_trash()
	_spawn_station()
	_spawn_daily_fruit_basket()
	_create_hud()
	_restore_cleaner_state()
	_update_cleaner_hud()
	_load_boss_configurations()
	_spawn_garbage_bosses()
	_restore_pending_boss_drops()
	_restore_unlocked_wildlife()
	_apply_upgrades()
<<<<<<< Updated upstream
	_apply_options(1.0, 0.8, 0.9, 80.0, graphics_quality)
=======
	if player:
		player.bag_count = clampi(int(saved_player_state.get("bag_count", 0)), 0, player.bag_capacity)
		player.bag_reward_total = maxi(0, int(saved_player_state.get("bag_reward_total", 0)))
		player.inventory_changed.emit(player.bag_count, player.bag_capacity)
	_apply_saved_settings()
>>>>>>> Stashed changes
	_update_hud()

func _process(delta: float) -> void:
	if is_day:
		day_time += delta
		if day_time >= day_duration + float(upgrades["day"]) * 30.0:
			day_time = 0.0
			is_day = false
			_on_phase_changed()
	notification_cooldown = maxf(0.0, notification_cooldown - delta)
	autosave_elapsed += delta
	if autosave_elapsed >= 20.0:
		autosave_elapsed = 0.0
		_save_game()
	var duration := _current_phase_duration()
	if not is_day and player and hud and hud.shop_open:
		if shop_node == null or player.global_position.distance_to(shop_node.global_position) > 4.2:
			hud.close_shop()
	_update_sun()
	_check_zone_unlocks()
	_update_clouds(delta)
	boss_save_timer += delta
	if boss_save_timer >= 12.0 and not active_bosses.is_empty():
		boss_save_timer = 0.0
		_save_game()
	_drain_boss_drop_queue(2)
	if hud:
		hud.update_phase(is_day, int(ceil(duration - day_time)) if is_day else 0)
		hud.update_stats(money, collected_trash, prestige_count, int(Time.get_ticks_msec() / 1000.0 - session_start_time))
		_update_fruit_boost_hud()
	_update_boss_hud()
	_update_cleaner_income(delta)
	_update_cleaner_context()
	_update_boss_area_introduction(delta)
	if hud and (hud.shop_open or (hud.cleaner_panel and hud.cleaner_panel.visible)):
		_update_cleaner_hud()
	minimap_update_timer -= delta
	if minimap_update_timer <= 0.0:
		minimap_update_timer = 0.18
		_update_minimap()
	autosave_timer += delta
	if autosave_timer >= 30.0:
		autosave_timer = 0.0
		_save_game()

func _load_cleaner_balance() -> void:
	var file := FileAccess.open(CLEANER_BALANCE_PATH, FileAccess.READ)
	if file == null:
		push_warning("TRush: falta %s; se aplican valores de reserva." % CLEANER_BALANCE_PATH)
		cleaner_balance = {
			"purchase_price": 5200,
			"income_rates_per_minute": [1, 2, 3, 4, 6, 8],
			"income_upgrade_costs": [900, 1800, 3600, 7200, 12500],
			"storage_capacities": [180, 360, 600, 900, 1300, 1800],
			"storage_upgrade_costs": [700, 1400, 3000, 6200, 11500],
			"upgrade_discount_multiplier": 0.92
		}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("TRush: el archivo de balance de la limpiadora no contiene un objeto JSON.")
		return
	cleaner_balance = parsed
	if not cleaner_balance.has("income_rates_per_minute") or not cleaner_balance.has("storage_capacities"):
		push_error("TRush: al balance de la limpiadora le faltan sus progresiones de ingreso o capacidad.")

func _load_progression_balance() -> void:
	var file := FileAccess.open(PROGRESSION_BALANCE_PATH, FileAccess.READ)
	if file == null:
		push_warning("TRush: falta el balance de progresión; se aplican valores seguros.")
		progression_balance = {"vacuum_max_level": 10, "vacuum_upgrade_costs": [2400, 3600, 5400, 7800, 11000, 15000, 20000, 26500, 34500, 44000], "daily_quota_base": 200, "daily_quota_per_level": 25, "daily_quota_max_level": 6, "daily_quota_upgrade_costs": [650, 1400, 2600, 4400, 6900, 10200], "daily_completion_bonus_rate": 0.10, "prestige_minimum_restoration": 98, "prestige_points_per_full_restoration": 1, "prestige_points_per_defeated_boss": 1, "prestige_points_max_per_reset": 12}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("TRush: el balance de progresión no contiene un objeto JSON.")
		return
	progression_balance = parsed

func _daily_target_for_level(level: int) -> int:
	var base := maxi(1, int(progression_balance.get("daily_quota_base", 200)))
	var step := maxi(1, int(progression_balance.get("daily_quota_per_level", 25)))
	var maximum_level := maxi(0, int(progression_balance.get("daily_quota_max_level", 6)))
	return base + step * clampi(level, 0, maximum_level)

func _cleaner_income_rate(level: int = -1) -> int:
	var rates: Array = cleaner_balance.get("income_rates_per_minute", [1])
	if rates.is_empty():
		return 1
	var selected_level := cleaner_income_level if level < 0 else level
	return maxi(0, int(rates[clampi(selected_level, 0, rates.size() - 1)]))

func _cleaner_rate_count() -> int:
	var rates: Array = cleaner_balance.get("income_rates_per_minute", [1])
	return rates.size()

func _cleaner_capacity(level: int = -1) -> int:
	var capacities: Array = cleaner_balance.get("storage_capacities", [180])
	if capacities.is_empty():
		return 180
	var selected_level := cleaner_storage_level if level < 0 else level
	return maxi(1, int(capacities[clampi(selected_level, 0, capacities.size() - 1)]))

func _cleaner_capacity_count() -> int:
	var capacities: Array = cleaner_balance.get("storage_capacities", [180])
	return capacities.size()

func _cleaner_upgrade_cost(cost_key: String, level: int) -> int:
	var costs: Array = cleaner_balance.get(cost_key, [])
	if level < 0 or level >= costs.size():
		return -1
	var discount_multiplier := clampf(float(cleaner_balance.get("upgrade_discount_multiplier", 0.92)), 0.5, 1.0)
	var discount := pow(discount_multiplier, float(upgrades.get("discount", 0)))
	return maxi(1, int(round(float(costs[level]) * discount)))

func _cleaner_hud_state() -> Dictionary:
	var selected_index := _selected_cleaner_index()
	var selected_record: Dictionary = cleaner_installations[selected_index] if selected_index >= 0 else {}
	return {
		"owned": cleaner_owned_count > 0,
		"owned_count": cleaner_owned_count,
		"pending_installation": cleaner_pending_installation,
		"installed": not cleaner_installations.is_empty(),
		"installed_count": cleaner_installations.size(),
		"operational": bool(selected_record.get("operational", cleaner_operational)),
		"location": str(selected_record.get("location", cleaner_location_id)),
		"machine_id": str(selected_record.get("id", cleaner_selected_id)),
		"income_level": cleaner_income_level,
		"storage_level": cleaner_storage_level,
		"income_per_minute": _cleaner_income_rate(),
		"stored_money": int(selected_record.get("stored_money", cleaner_stored_money)),
		"storage_capacity": _cleaner_capacity()
	}

func _selected_cleaner_index() -> int:
	for index in range(cleaner_installations.size()):
		if str(cleaner_installations[index].get("id", "")) == cleaner_selected_id:
			return index
	return 0 if not cleaner_installations.is_empty() else -1

func _select_cleaner_record(index: int) -> void:
	if index < 0 or index >= cleaner_installations.size():
		return
	var record: Dictionary = cleaner_installations[index]
	cleaner_selected_id = str(record.get("id", ""))
	cleaner_location_id = str(record.get("location", ""))
	var record_position: Variant = record.get("position", Vector3.ZERO)
	cleaner_install_position = record_position if record_position is Vector3 else Vector3.ZERO
	cleaner_operational = bool(record.get("operational", true))
	cleaner_stored_money = clampi(int(record.get("stored_money", 0)), 0, _cleaner_capacity())
	cleaner_elapsed_seconds = clampf(float(record.get("elapsed_seconds", 0.0)), 0.0, 59.99)
	var machine: Variant = record.get("machine", null)
	cleaner_machine = machine as Node3D if machine is Node3D else null

func _update_cleaner_hud() -> void:
	if hud == null:
		return
	hud.update_cleaner_shop(
		_cleaner_hud_state(),
		money,
		int(cleaner_balance.get("purchase_price", 5200)),
		_cleaner_upgrade_cost("income_upgrade_costs", cleaner_income_level),
		_cleaner_upgrade_cost("storage_upgrade_costs", cleaner_storage_level),
		_cleaner_income_rate(cleaner_income_level + 1),
		_cleaner_capacity(cleaner_storage_level + 1)
	)
	if hud.cleaner_panel and hud.cleaner_panel.visible:
		hud.update_cleaner_management(_cleaner_hud_state())

func _update_cleaner_income(delta: float) -> void:
	var changed := false
	for index in range(cleaner_installations.size()):
		var record: Dictionary = cleaner_installations[index]
		var stored := clampi(int(record.get("stored_money", 0)), 0, _cleaner_capacity())
		if not bool(record.get("operational", true)) or stored >= _cleaner_capacity():
			continue
		var elapsed := maxf(0.0, float(record.get("elapsed_seconds", 0.0))) + maxf(0.0, delta)
		var complete_minutes := int(floor(elapsed / 60.0))
		if complete_minutes <= 0:
			record["elapsed_seconds"] = elapsed
			cleaner_installations[index] = record
			continue
		elapsed = fposmod(elapsed, 60.0)
		stored = mini(_cleaner_capacity(), stored + complete_minutes * _cleaner_income_rate())
		record["stored_money"] = stored
		record["elapsed_seconds"] = 0.0 if stored >= _cleaner_capacity() else elapsed
		cleaner_installations[index] = record
		changed = true
	if changed:
		_update_cleaner_hud()
		_save_game()

func _update_minimap() -> void:
	if hud == null or player == null:
		return
	var garbage_positions: Array[Vector3] = []
	if radar_active:
		for item in get_tree().get_nodes_in_group("garbage"):
			if item is TrashPickup and not item.is_queued_for_deletion():
				garbage_positions.append(item.global_position)
	var boss_positions: Array[Vector3] = []
	for boss in get_tree().get_nodes_in_group("garbage_boss"):
		if boss is Node3D and not boss.is_queued_for_deletion() and not bool(boss.get("is_defeated")):
			boss_positions.append(boss.global_position)
	hud.update_minimap(player.global_position, player.rotation.y, garbage_positions, boss_positions, radar_active, radar_range)

func _apply_saved_settings() -> void:
	if player:
		player.mouse_sensitivity = float(TRushProfiles.get_setting("mouse_sensitivity", 0.0025))
		if player.game_camera:
			player.game_camera.fov = float(TRushProfiles.get_setting("fov", 80.0))
	TRushProfiles.apply_runtime_settings(get_viewport())
	var brightness := float(TRushProfiles.get_setting("brightness", 1.0))
	if world_environment and world_environment.environment:
		world_environment.environment.ambient_light_energy = (0.65 if is_day else 0.18) * brightness
		world_environment.environment.tonemap_exposure = brightness

func _refresh_radar_prompt() -> void:
	if roots_lookout == null:
		return
	var prompt := roots_lookout.find_child("RadarPrompt", true, false) as Label3D
	if prompt:
		prompt.text = _radar_prompt_text()

func _update_fruit_boost_hud() -> void:
	if hud == null or player == null:
		return
	var seconds_left := int(ceil(player.fruit_boost_time))
	var key := "%s:%d" % [player.active_fruit_boost, seconds_left]
	if key == last_boost_hud_key:
		return
	last_boost_hud_key = key
	hud.update_fruit_boost(player.active_fruit_boost, seconds_left)

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
		world_environment.environment.fog_light_color = Color(0.63, 0.73, 0.66) if is_day else Color(0.08, 0.14, 0.22)

func _build_world() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.position.y = -0.5
	add_child(ground)
<<<<<<< Updated upstream
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.20, 0.32, 0.19)
	# Claro central y cuatro brazos: el terreno deja de ser un cuadrado.
	var sections := [
		[Vector3(0, 0, 0), Vector3(24, 1, 24), 0.0],
		[Vector3(19, 0, -19), Vector3(34, 1, 16), -PI / 4.0],
		[Vector3(19, 0, 19), Vector3(34, 1, 16), PI / 4.0],
		[Vector3(-19, 0, 19), Vector3(34, 1, 16), 3.0 * PI / 4.0],
		[Vector3(-19, 0, -19), Vector3(34, 1, 16), -3.0 * PI / 4.0]
	]
	for section in sections:
		var section_mesh := MeshInstance3D.new()
		var section_box := BoxMesh.new()
		section_box.size = section[1]
		section_mesh.mesh = section_box
		section_mesh.position = section[0]
		section_mesh.rotation.y = float(section[2])
		section_mesh.material_override = ground_material
		ground.add_child(section_mesh)
		var section_collision := CollisionShape3D.new()
		var collision_box := BoxShape3D.new()
		collision_box.size = section[1]
		section_collision.shape = collision_box
		section_collision.position = section[0]
		section_collision.rotation.y = float(section[2])
		ground.add_child(section_collision)
=======
	var ground_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(240, 1, 240)
	ground_mesh.mesh = plane
	var ground_material := StandardMaterial3D.new()
	var terrain_noise := FastNoiseLite.new()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.frequency = 0.045
	terrain_noise.fractal_octaves = 4
	var terrain_texture := NoiseTexture2D.new()
	terrain_texture.width = 256
	terrain_texture.height = 256
	terrain_texture.seamless = true
	terrain_texture.noise = terrain_noise
	var terrain_ramp := Gradient.new()
	terrain_ramp.offsets = PackedFloat32Array([0.0, 0.36, 0.68, 1.0])
	terrain_ramp.colors = PackedColorArray([Color(0.16, 0.23, 0.14), Color(0.27, 0.34, 0.20), Color(0.37, 0.40, 0.24), Color(0.49, 0.45, 0.30)])
	terrain_texture.color_ramp = terrain_ramp
	ground_material.albedo_texture = terrain_texture
	ground_material.albedo_color = Color(0.93, 0.96, 0.89)
	ground_material.uv1_scale = Vector3(22.0, 1.0, 22.0)
	ground_material.roughness = 0.98
	ground_mesh.material_override = ground_material
	ground.add_child(ground_mesh)
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240, 1, 240)
	ground_shape.shape = box
	ground.add_child(ground_shape)
>>>>>>> Stashed changes

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.shadow_blur = 1.1
	sun.directional_shadow_max_distance = 150.0
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
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.63, 0.73, 0.66)
	environment.fog_density = 0.0025
	environment.fog_sun_scatter = 0.12
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	world_regions = Node3D.new()
	world_regions.name = "WorldRegions"
	add_child(world_regions)

	var trees := Node3D.new()
	trees.name = "Trees"
	add_child(trees)
	tree_foliage_transforms.clear()
	tree_foliage_colors.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 74129
<<<<<<< Updated upstream
	for i in range(26):
		var tree_position := _random_map_position(rng, 20.0, 37.0, 6.0)
=======
	for i in range(82):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(19.0, 67.0)
		var tree_position := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
>>>>>>> Stashed changes
		if _is_clear_location(tree_position, 4.2):
			_create_tree(trees, tree_position)
			reserved_positions.append(tree_position)
	# Thickens the northern deep-forest region while the open central hub remains clear.
	for forest_index in range(46):
		var forest_angle := rng.randf_range(0.0, TAU)
		var forest_radius := sqrt(rng.randf()) * 25.0
		var forest_position := Vector3(-67.0 + cos(forest_angle) * forest_radius, 0.0, -68.0 + sin(forest_angle) * forest_radius)
		if _is_clear_location(forest_position, 4.0):
			_create_tree(trees, forest_position)
			reserved_positions.append(forest_position)
	_add_tree_foliage_batch(trees)
	_populate_ground_detail(rng, trees)
	_build_world_regions(rng, trees)
	var imported_nature := NATURE_ASSET_SCATTER.new() as TRushNatureAssetScatter
	imported_nature.name = "ImportedNatureAssetInstances"
	add_child(imported_nature)
	imported_nature.populate(reserved_positions)
	_create_zone_markers()
	_create_pond()
	_create_clouds()

<<<<<<< Updated upstream
func _random_map_position(rng: RandomNumberGenerator, min_distance: float = 9.0, max_distance: float = 38.0, half_width: float = 6.0) -> Vector3:
	var arm := rng.randi_range(0, 3)
	var distance := rng.randf_range(min_distance, max_distance)
	var lateral := rng.randf_range(-half_width, half_width)
	var angles := [-PI / 4.0, PI / 4.0, 3.0 * PI / 4.0, -3.0 * PI / 4.0]
	var direction := Vector3(cos(angles[arm]), 0.0, sin(angles[arm]))
	var perpendicular := Vector3(-direction.z, 0.0, direction.x)
	return direction * distance + perpendicular * lateral

func _create_tree(parent: Node3D, location: Vector3):
=======
func _build_world_regions(rng: RandomNumberGenerator, trees: Node3D) -> void:
	var path_material := StandardMaterial3D.new()
	path_material.albedo_color = Color(0.30, 0.27, 0.20)
	path_material.roughness = 1.0
	WORLD_REGION_BUILDER.add_path(world_regions, [Vector3(0, 0, 0), Vector3(-18, 0, -25), Vector3(-42, 0, -47), Vector3(-67, 0, -68)], 4.4, path_material, "DeepForestTrail")
	WORLD_REGION_BUILDER.add_path(world_regions, [Vector3(0, 0, 0), Vector3(24, 0, -24), Vector3(47, 0, -48), Vector3(69, 0, -67)], 4.8, path_material, "WasteValleyTrail")
	WORLD_REGION_BUILDER.add_path(world_regions, [Vector3(0, 0, 0), Vector3(-20, 0, 25), Vector3(-44, 0, 48), Vector3(-69, 0, 68)], 3.8, path_material, "RockyTrail")
	WORLD_REGION_BUILDER.add_path(world_regions, [Vector3(0, 0, 0), Vector3(25, 0, 23), Vector3(48, 0, 48), Vector3(70, 0, 68)], 4.0, path_material, "WaterTrail")
	var hill_material := StandardMaterial3D.new()
	hill_material.albedo_color = Color(0.31, 0.34, 0.28)
	hill_material.roughness = 1.0
	WORLD_REGION_BUILDER.add_hill(world_regions, Vector3(-70, 0, 66), 20.0, 6.0, 23, hill_material)
	WORLD_REGION_BUILDER.add_hill(world_regions, Vector3(-96, 0, 82), 16.0, 4.4, 41, hill_material)
	WORLD_REGION_BUILDER.add_hill(world_regions, Vector3(-47, 0, 88), 13.0, 3.6, 57, hill_material)
	WORLD_REGION_BUILDER.add_region_sign(world_regions, "BOSQUE PROFUNDO", Vector3(-67, 0, -50), Color(0.49, 0.76, 0.48))
	WORLD_REGION_BUILDER.add_region_sign(world_regions, "VALLE DE RESIDUOS", Vector3(68, 0, -45), Color(0.88, 0.65, 0.37))
	WORLD_REGION_BUILDER.add_region_sign(world_regions, "SIERRAS DE PIEDRA", Vector3(-70, 0, 44), Color(0.72, 0.73, 0.66))
	WORLD_REGION_BUILDER.add_region_sign(world_regions, "ARROYO DEL ESTE", Vector3(70, 0, 42), Color(0.45, 0.78, 0.84))
	roots_lookout = WORLD_REGION_BUILDER.add_landmark(world_regions, "MIRADOR DE LAS RAÍCES", Vector3(0, 0, 99), Color(0.59, 0.55, 0.40))
	_create_radar_console(roots_lookout)
	_add_waste_valley_details(rng)
	_add_deep_forest_details(rng, trees)
	_add_water_region(rng)

func _add_waste_valley_details(rng: RandomNumberGenerator) -> void:
	var scrap_root := Node3D.new()
	scrap_root.name = "WasteValleyScrap"
	scrap_root.position = Vector3(66, 0, -65)
	world_regions.add_child(scrap_root)
	var metal_material := StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.32, 0.39, 0.38)
	metal_material.metallic = 0.68
	metal_material.roughness = 0.48
	var rubber_material := StandardMaterial3D.new()
	rubber_material.albedo_color = Color(0.075, 0.085, 0.08)
	rubber_material.roughness = 0.96
	for debris_index in range(42):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(7.0, 27.0)
		var location := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if radius < 13.0 and absf(angle_difference(angle, PI * 0.5)) < 0.3:
			continue
		var scrap := MeshInstance3D.new()
		var scrap_mesh: Mesh
		if debris_index % 4 == 0:
			var tire := TorusMesh.new()
			tire.inner_radius = 0.30
			tire.outer_radius = 0.50
			scrap_mesh = tire
			scrap.position.y = 0.43
			scrap.rotation.x = PI * 0.5 + rng.randf_range(-0.15, 0.15)
			scrap.material_override = rubber_material
		else:
			var panel := BoxMesh.new()
			panel.size = Vector3(rng.randf_range(0.4, 1.4), rng.randf_range(0.08, 0.24), rng.randf_range(0.5, 1.5))
			scrap_mesh = panel
			scrap.position.y = panel.size.y * 0.5
			scrap.material_override = metal_material
		scrap.mesh = scrap_mesh
		scrap.position.x = location.x
		scrap.position.z = location.z
		scrap.rotation.y = rng.randf_range(0.0, TAU)
		scrap_root.add_child(scrap)

func _add_deep_forest_details(rng: RandomNumberGenerator, parent: Node3D) -> void:
	var bark_material := _detail_material(Color(0.29, 0.19, 0.12))
	var tree_bark_texture := load("res://assets/environment/tree_demo_textures/bark.jpg") as Texture2D
	var tree_bark_normal := load("res://assets/environment/tree_demo_textures/bark_normal.png") as Texture2D
	if tree_bark_texture:
		bark_material.albedo_texture = tree_bark_texture
		bark_material.uv1_scale = Vector3(1.2, 1.2, 1.2)
	if tree_bark_normal:
		bark_material.normal_enabled = true
		bark_material.normal_texture = tree_bark_normal
		bark_material.normal_scale = 0.38
	for log_index in range(12):
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = rng.randf_range(0.12, 0.22)
		log_mesh.bottom_radius = log_mesh.top_radius * 1.35
		log_mesh.height = rng.randf_range(2.4, 4.2)
		log.mesh = log_mesh
		var angle := rng.randf_range(0.0, TAU)
		log.position = Vector3(-67.0 + rng.randf_range(-20.0, 20.0), log_mesh.bottom_radius * 0.65, -68.0 + rng.randf_range(-20.0, 20.0))
		log.rotation = Vector3(PI * 0.5 + rng.randf_range(-0.05, 0.05), angle, rng.randf_range(-0.08, 0.08))
		log.material_override = bark_material
		parent.add_child(log)
		if log_index % 3 == 0:
			_add_box_collision(parent, log.position, Vector3(0.5, 0.48, log_mesh.height))

func _add_water_region(rng: RandomNumberGenerator) -> void:
	var water_material := ShaderMaterial.new()
	water_material.shader = load("res://shaders/water_surface.gdshader") as Shader
	var water_root := Node3D.new()
	water_root.name = "EastWaterRegion"
	water_root.position = Vector3(70, 0, 68)
	world_regions.add_child(water_root)
	var pond := MeshInstance3D.new()
	pond.name = "ShallowPool"
	var pond_mesh := CylinderMesh.new()
	pond_mesh.top_radius = 10.0
	pond_mesh.bottom_radius = 10.0
	pond_mesh.height = 0.12
	pond.mesh = pond_mesh
	pond.position.y = 0.04
	pond.material_override = water_material
	water_root.add_child(pond)
	var local_stream_points: Array[Vector3] = []
	for world_point in WORLD_MAP_DATA.stream_world_points():
		local_stream_points.append(world_point - water_root.position)
	var stream_material := water_material.duplicate() as ShaderMaterial
	stream_material.set_shader_parameter("circular_mask", false)
	WORLD_REGION_BUILDER.add_water_ribbon(water_root, local_stream_points, 3.8, stream_material, "StreamToShallows")
	var bank_material := _detail_material(Color(0.39, 0.34, 0.25))
	var bank := MeshInstance3D.new()
	var bank_mesh := TorusMesh.new()
	bank_mesh.inner_radius = 9.8
	bank_mesh.outer_radius = 10.7
	bank.mesh = bank_mesh
	bank.position.y = 0.03
	bank.material_override = bank_material
	water_root.add_child(bank)
	for reed_index in range(42):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(10.3, 13.5)
		var reed := MeshInstance3D.new()
		var reed_mesh := CylinderMesh.new()
		reed_mesh.top_radius = 0.018
		reed_mesh.bottom_radius = 0.07
		reed_mesh.height = rng.randf_range(0.7, 1.4)
		reed.mesh = reed_mesh
		reed.position = Vector3(cos(angle) * radius, reed_mesh.height * 0.5, sin(angle) * radius)
		reed.rotation.z = rng.randf_range(-0.12, 0.12)
		reed.material_override = _detail_material(Color(0.32, 0.47, 0.23))
		water_root.add_child(reed)

func _create_tree(parent: Node3D, location: Vector3) -> void:
>>>>>>> Stashed changes
	var tree := Node3D.new()
	tree.position = location
	var tree_scale := randf_range(0.88, 1.22)
	var silhouette := randi_range(0, 2)
	var width_profile: float = [1.2, 0.88, 1.0][silhouette]
	var height_profile: float = [0.94, 1.32, 1.08][silhouette]
	tree.scale = Vector3(tree_scale * width_profile, tree_scale * height_profile, tree_scale * width_profile)
	tree.rotation.y = randf_range(0.0, TAU)
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
<<<<<<< Updated upstream
	var foliage_materials: Array[StandardMaterial3D] = []
	for foliage_color in foliage_palette:
		var foliage_material := StandardMaterial3D.new()
		foliage_material.albedo_color = foliage_color
		foliage_material.roughness = 1.0
		foliage_material.cull_mode = BaseMaterial3D.CULL_BACK
		foliage_materials.append(foliage_material)

	for cluster_index in range(7):
		var cluster := MeshInstance3D.new()
		var cluster_mesh := SphereMesh.new()
		cluster_mesh.radial_segments = 16
		cluster_mesh.rings = 10
		cluster_mesh.radius = randf_range(0.72, 1.12)
		cluster_mesh.height = cluster_mesh.radius * randf_range(1.25, 1.75)
		cluster.mesh = cluster_mesh
=======
	var cluster_count: int = [9, 12, 11][silhouette]
	for cluster_index in range(cluster_count):
		var cluster_radius := randf_range(0.72, 1.12)
		var cluster_height := cluster_radius * randf_range(1.25, 1.75)
		var cluster_scale := Vector3(randf_range(0.88, 1.18), randf_range(0.82, 1.16), randf_range(0.88, 1.2))
		var cluster_position := Vector3.ZERO
>>>>>>> Stashed changes
		if cluster_index == 0:
			cluster_position = Vector3(0.0, 3.35, 0.0)
		else:
			var angle := TAU * float(cluster_index - 1) / float(cluster_count - 1) + randf_range(-0.22, 0.22)
			var ring_radius := randf_range(0.55, 1.05)
			cluster_position = Vector3(cos(angle) * ring_radius, randf_range(2.75, 3.75), sin(angle) * ring_radius)
		var cluster_basis := Basis().scaled(Vector3(cluster_radius * cluster_scale.x, cluster_height * 0.5 * cluster_scale.y, cluster_radius * cluster_scale.z))
		tree_foliage_transforms.append(tree.transform * Transform3D(cluster_basis, cluster_position))
		tree_foliage_colors.append(foliage_palette[randi_range(0, foliage_palette.size() - 1)])

func _add_tree_foliage_batch(parent: Node3D) -> void:
	if tree_foliage_transforms.is_empty():
		return
	var transforms_by_quadrant: Array = [[], [], [], []]
	var colors_by_quadrant: Array = [[], [], [], []]
	var quadrant_origins := [Vector3(-60, 0, -60), Vector3(60, 0, -60), Vector3(-60, 0, 60), Vector3(60, 0, 60)]
	for index in range(tree_foliage_transforms.size()):
		var instance_transform: Transform3D = tree_foliage_transforms[index]
		var quadrant := (1 if instance_transform.origin.x >= 0.0 else 0) + (2 if instance_transform.origin.z >= 0.0 else 0)
		instance_transform.origin -= quadrant_origins[quadrant]
		transforms_by_quadrant[quadrant].append(instance_transform)
		colors_by_quadrant[quadrant].append(tree_foliage_colors[index])
	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radial_segments = 24
	foliage_mesh.rings = 16
	foliage_mesh.radius = 1.0
	foliage_mesh.height = 2.0
	var foliage_material := StandardMaterial3D.new()
	foliage_material.albedo_color = Color.WHITE
	foliage_material.vertex_color_use_as_albedo = true
	foliage_material.roughness = 1.0
	foliage_material.cull_mode = BaseMaterial3D.CULL_BACK
	for quadrant in range(transforms_by_quadrant.size()):
		if transforms_by_quadrant[quadrant].is_empty():
			continue
		var foliage_multimesh := MultiMesh.new()
		foliage_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		foliage_multimesh.use_colors = true
		foliage_multimesh.mesh = foliage_mesh
		foliage_multimesh.instance_count = transforms_by_quadrant[quadrant].size()
		for index in range(transforms_by_quadrant[quadrant].size()):
			foliage_multimesh.set_instance_transform(index, transforms_by_quadrant[quadrant][index])
			foliage_multimesh.set_instance_color(index, colors_by_quadrant[quadrant][index])
		var foliage_batch := MultiMeshInstance3D.new()
		foliage_batch.name = "TreeCanopyBatch_%d" % quadrant
		foliage_batch.position = quadrant_origins[quadrant]
		foliage_batch.multimesh = foliage_multimesh
		foliage_batch.material_override = foliage_material
		parent.add_child(foliage_batch)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as TRushPlayer
	player.current_health = clampf(saved_player_health, 1.0, player.max_health)
	add_child(player)
	player.add_to_group("player")
	player.global_position = Vector3(0, 1, 7)
	if saved_player_state.has("position") and saved_player_state["position"] is Vector3:
		var saved_position: Vector3 = saved_player_state["position"]
		if absf(saved_position.x) < 116.0 and absf(saved_position.z) < 116.0 and saved_position.y >= 0.0 and saved_position.y < 30.0:
			player.global_position = saved_position
	player.current_health = clampf(float(saved_player_state.get("health", player.maximum_health)), 1.0, player.maximum_health)
	player.rotation.y = float(saved_player_state.get("yaw", 0.0))
	player.inventory_changed.connect(_on_inventory_changed)
	player.health_changed.connect(_on_player_health_changed)
	player.deposit_requested.connect(_on_deposit_requested)
	player.trash_collected.connect(_on_trash_collected)
	player.trash_item_collected.connect(_on_trash_item_collected)
	player.shop_requested.connect(_open_shop)
	player.cleaner_interaction_requested.connect(_on_cleaner_interaction_requested)
	player.sleep_requested.connect(_start_new_day)
	player.pause_requested.connect(_on_pause_requested)

func _spawn_daily_fruit_basket() -> void:
	if station == null:
		return
	fruit_basket = FRUIT_BASKET_SCRIPT.new() as Node3D
	fruit_basket.name = "DailyFruitBasket"
	fruit_basket.position = Vector3(1.85, 0.0, 1.0)
	fruit_basket.call("set_fruits_remaining", daily_fruit_remaining)
	station.add_child(fruit_basket)

func _on_fruit_requested() -> void:
	if player == null:
		return
	if fruit_basket == null or player.global_position.distance_to(fruit_basket.global_position) > 3.25:
		_try_roots_radar_interaction()
		return
	if not bool(fruit_basket.call("consume_fruit")):
		if hud:
			hud.show_message("La canasta está vacía. Volverá a llenarse mañana.")
		return
	daily_fruit_remaining = int(fruit_basket.get("fruits_remaining"))
	var boosts := [
		{"id": "speed", "name": "Patas ligeras", "description": "velocidad aumentada durante 60 s"},
		{"id": "vacuum", "name": "Vórtice frutal", "description": "aspiradora 50% más potente durante 60 s"},
		{"id": "range", "name": "Imán de semillas", "description": "alcance de aspiradora aumentado durante 60 s"},
		{"id": "shield", "name": "Escudo de cáscara", "description": "recibes 45% menos daño durante 60 s"},
		{"id": "health", "name": "Pulpa revitalizante", "description": "recuperas 35 puntos de salud"}
	]
	var boost: Dictionary = boosts[randi_range(0, boosts.size() - 1)]
	if str(boost["id"]) == "health":
		player.heal(35.0)
	else:
		player.activate_fruit_boost(str(boost["id"]), 60.0)
	if hud:
		hud.show_message("¡%s! %s." % [boost["name"], boost["description"]])
	_save_game()

func _create_radar_console(landmark: Node3D) -> void:
	if landmark == null:
		return
	var sign_root := Node3D.new()
	sign_root.name = "RootsRadarSign"
	sign_root.position = Vector3(0.0, 0.1, -4.2)
	sign_root.set_script(SIGN_SCRIPT)
	landmark.add_child(sign_root)
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(2.9, 0.88, 0.14)
	board.mesh = board_mesh
	board.position.y = 1.5
	board.material_override = _detail_material(Color(0.16, 0.26, 0.18))
	sign_root.add_child(board)
	var label := Label3D.new()
	label.name = "RadarPrompt"
	label.position = Vector3(0.0, 1.5, -0.09)
	label.font_size = 21
	label.modulate = Color(0.78, 0.95, 0.70)
	label.text = _radar_prompt_text()
	sign_root.add_child(label)

func _radar_prompt_text() -> String:
	if not radar_unlocked:
		return "RADAR DE RAÍCES\n[R] DESBLOQUEAR · $1000"
	return "RADAR DE RAÍCES\n[R] %s" % ("DESACTIVAR" if radar_active else "ACTIVAR")

func _try_roots_radar_interaction() -> void:
	if roots_lookout == null or player.global_position.distance_to(roots_lookout.global_position) > 7.0:
		return
	if not radar_unlocked:
		if money < 1000:
			if hud:
				hud.show_message("El radar cuesta $1000. Todavía no tienes suficiente dinero.")
			return
		money -= 1000
		radar_unlocked = true
		hud.show_message("Radar desbloqueado por $1000. Pulsa R otra vez para activarlo.")
	else:
		radar_active = not radar_active
		hud.show_message("Radar %s." % ("activado · residuos marcados en rojo" if radar_active else "desactivado"))
	var prompt := roots_lookout.find_child("RadarPrompt", true, false) as Label3D
	if prompt:
		prompt.text = _radar_prompt_text()
	_update_hud()
	_save_game()

func _on_player_health_depleted() -> void:
	if hud:
		hud.show_message("Te quedaste sin salud. Revives junto a la estación en 5 segundos.")
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(player) or station == null:
		return
	player.respawn_at(station.global_position + Vector3(0.0, 1.0, 6.5))
	if hud:
		hud.show_message("¡De vuelta! Conservaste la bolsa.")
	_save_game()

func _spawn_trash() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90317 + prestige_count * 1009 + day_number * 97
	if daily_target <= 0:
		daily_target = _daily_target_for_level(int(upgrades.get("daily_quota", 0)))
	daily_collected_count = clampi(daily_collected_count, 0, daily_target)
	var remaining_count := maxi(0, daily_target - daily_collected_count)
	var type_names := ["Botella plastica", "Lata de aluminio", "Papel y carton", "Envase de vidrio"]
	var rewards := [5, 8, 6, 12]
	for old_item in current_daily_trash:
		if is_instance_valid(old_item):
			reserved_positions.erase(old_item.position)
			old_item.queue_free()
	current_daily_trash.clear()
	for i in range(remaining_count):
		var trash := TRASH_SCENE.instantiate() as TrashPickup
		var location := Vector3.ZERO
<<<<<<< Updated upstream
		for attempt in range(60):
			if i >= base_target_count:
				var arm_index := int((i - base_target_count) / 13) % 4
				var arm_centers: Array[Vector3] = [Vector3(22, 0, -22), Vector3(22, 0, 22), Vector3(-22, 0, 22), Vector3(-22, 0, -22)]
				var arm_center: Vector3 = arm_centers[arm_index]
				location = arm_center + Vector3(rng.randf_range(-5.0, 5.0), 0.0, rng.randf_range(-5.0, 5.0))
			else:
				var angle := rng.randf_range(0.0, TAU)
				var radius := sqrt(rng.randf()) * 15.0 + 3.5
				location = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			if location.length() > 3.0 and (i >= base_target_count or _is_clear_location(location, 1.15)):
=======
		for attempt in range(80):
			location = Vector3(rng.randf_range(-104.0, 104.0), 0.0, rng.randf_range(-104.0, 104.0))
			if _is_clear_location(location, 1.05):
>>>>>>> Stashed changes
				break
		reserved_positions.append(location)
		trash.position = location
		var kind := i % type_names.size()
		trash.trash_type = type_names[kind]
		trash.reward_value = rewards[kind]
		trash.trash_value = 1
		trash.set_meta("cleanup_day", day_number)
		_configure_trash_visual(trash, trash.trash_type, rng)
		add_child(trash)
		current_daily_trash.append(trash)
	if total_trash <= 0:
		total_trash = daily_target

func _load_boss_configurations() -> void:
	boss_configurations.clear()
	var config_file := FileAccess.open(BOSS_CONFIG_PATH, FileAccess.READ)
	if config_file == null:
		push_error("TRush: no se pudo abrir la configuración de montañas de residuos.")
		return
	var parsed: Variant = JSON.parse_string(config_file.get_as_text())
	if not parsed is Dictionary or not parsed.get("bosses", []) is Array:
		push_error("TRush: formato de configuración de bosses inválido.")
		return
	for configuration in parsed["bosses"]:
		if configuration is Dictionary:
			boss_configurations.append(configuration)

func _spawn_garbage_bosses() -> void:
	var fallback_locations := [Vector3(-67.0, 0.0, -68.0), Vector3(96.0, 0.0, 91.0), Vector3(66.0, 0.0, -65.0)]
	var spawn_count := mini(mini(boss_spawn_limit, boss_configurations.size()), fallback_locations.size())
	for index in range(spawn_count):
		var configuration: Dictionary = boss_configurations[index]
		var boss_id := str(configuration.get("id", "boss_%d" % index))
		if defeated_boss_ids.has(boss_id):
			continue
		var location: Vector3 = fallback_locations[index]
		var configured_position: Variant = configuration.get("position", null)
		if configured_position is Array and configured_position.size() >= 3:
			location = Vector3(float(configured_position[0]), float(configured_position[1]), float(configured_position[2]))
		var saved_state: Variant = boss_progress.get(boss_id, {})
		_spawn_boss_instance(configuration, location, saved_state if saved_state is Dictionary else {})
	_spawn_saved_minibosses()

func _spawn_boss_instance(configuration: Dictionary, spawn_position: Vector3, saved_state: Dictionary = {}) -> TRushGarbageMountainBoss:
	var boss := BOSS_SCENE.instantiate() as TRushGarbageMountainBoss
	boss.configure(configuration)
	boss.position = spawn_position
	if not saved_state.is_empty():
		boss.restore_progress(saved_state)
	boss.health_changed.connect(_on_boss_health_changed.bind(boss))
	boss.garbage_release_requested.connect(_on_boss_garbage_release.bind(boss))
	boss.final_drop_batch_requested.connect(_on_boss_final_drop_batch.bind(boss))
	boss.defeated.connect(_on_boss_defeated)
	boss.split_requested.connect(_on_boss_split_requested.bind(boss))
	active_bosses.append(boss)
	add_child(boss)
	boss.set_combat_target(player)
	if player:
		boss.look_at(Vector3(player.global_position.x, boss.global_position.y, player.global_position.z), Vector3.UP)
	return boss

func _on_boss_split_requested(parent_id: String, world_position: Vector3, children: Array[Dictionary], reward: int, parent: TRushGarbageMountainBoss) -> void:
	if not parent.split_parent_id.is_empty():
		var root_id := parent.split_parent_id
		if not boss_encounters.has(root_id) or defeated_boss_ids.has(parent_id):
			return
		var root_encounter: Dictionary = boss_encounters[root_id]
		if str(root_encounter.get("phase", "")) != "minis":
			return
		defeated_boss_ids.append(parent_id)
		boss_progress[parent_id] = parent.progress_snapshot()
		var descendants: Array = root_encounter.get("children", []).duplicate(true)
		var descendant_ids: Array = root_encounter.get("remaining_ids", []).duplicate()
		descendant_ids.erase(parent_id)
		for child in children:
			if not child is Dictionary:
				continue
			var child_config: Dictionary = child.duplicate(true)
			var child_id := str(child_config.get("id", ""))
			if child_id.is_empty() or descendants.has(child_id) or defeated_boss_ids.has(child_id):
				continue
			child_config["split_parent_id"] = root_id
			descendants.append(child_config)
			descendant_ids.append(child_id)
		root_encounter["children"] = descendants
		root_encounter["remaining_ids"] = descendant_ids
		root_encounter["position"] = world_position
		root_encounter["generation"] = int(root_encounter.get("generation", 1)) + 1
		boss_encounters[root_id] = root_encounter
		_spawn_encounter_minibosses(root_id)
		if hud:
			hud.show_message("¡%s se dividió en dos criaturas más pequeñas!" % parent.boss_name)
		if descendant_ids.is_empty():
			_complete_split_encounter(root_id)
		_save_game()
		return
	if boss_encounters.has(parent_id) or defeated_boss_ids.has(parent_id):
		return
	var child_ids: Array[String] = []
	for child in children:
		var child_id := str(child.get("id", ""))
		if not child_id.is_empty():
			child_ids.append(child_id)
	defeated_boss_ids.append(parent_id)
	boss_progress[parent_id] = parent.progress_snapshot()
	boss_encounters[parent_id] = {
		"phase": "minis",
		"position": world_position,
		"children": children.duplicate(true),
		"remaining_ids": child_ids,
		"child_positions": {},
		"reward": reward,
		"generation": 1,
		"drop_types": parent.get_drop_types(),
		"final_drop_count": parent.final_drop_count
	}
	_spawn_encounter_minibosses(parent_id)
	if hud:
		hud.show_message("¡El Coloso se partió! Derrota a Eco de Plástico y Tizón de Chatarra.")
	_save_game()

func _spawn_saved_minibosses() -> void:
	for parent_id in boss_encounters:
		var encounter: Variant = boss_encounters[parent_id]
		if encounter is Dictionary and str(encounter.get("phase", "")) == "minis":
			_spawn_encounter_minibosses(str(parent_id))

func _spawn_encounter_minibosses(parent_id: String) -> void:
	var encounter: Dictionary = boss_encounters.get(parent_id, {})
	var child_configs: Variant = encounter.get("children", [])
	var remaining: Variant = encounter.get("remaining_ids", [])
	if not child_configs is Array or not remaining is Array:
		return
	var parent_position: Vector3 = encounter.get("position", Vector3(96.0, 0.0, -91.0))
	var position_records: Dictionary = encounter.get("child_positions", {}).duplicate(true)
	var radial := parent_position - (player.global_position if player else Vector3.ZERO)
	radial.y = 0.0
	if radial.length_squared() < 0.01:
		radial = Vector3.RIGHT
	else:
		radial = radial.normalized()
	var lateral := Vector3(-radial.z, 0.0, radial.x).normalized()
	var child_index := 0
	for child_value in child_configs:
		if not child_value is Dictionary:
			continue
		var child_config: Dictionary = child_value
		var child_id := str(child_config.get("id", ""))
		if child_id.is_empty() or not remaining.has(child_id) or defeated_boss_ids.has(child_id):
			continue
		var already_spawned := false
		for active in active_bosses:
			if is_instance_valid(active) and active is TRushGarbageMountainBoss and active.boss_id == child_id and not active.is_defeated:
				already_spawned = true
				break
		if already_spawned:
			continue
		var offset := lateral * (6.5 if child_index == 0 else -6.5)
		var child_position: Vector3 = position_records.get(child_id, parent_position + offset)
		if player and child_position.distance_to(player.global_position) < 4.3:
			child_position += radial * 5.0
		child_position.y = 0.0
		position_records[child_id] = child_position
		var child_progress: Variant = boss_progress.get(child_id, {})
		_spawn_boss_instance(child_config, child_position, child_progress if child_progress is Dictionary else {})
		child_index += 1
	encounter["child_positions"] = position_records
	boss_encounters[parent_id] = encounter

func _complete_split_encounter(parent_id: String) -> void:
	var encounter: Dictionary = boss_encounters.get(parent_id, {})
	if str(encounter.get("phase", "")) != "minis":
		return
	encounter["phase"] = "complete"
	boss_encounters[parent_id] = encounter
	var base_reward := maxi(0, int(encounter.get("reward", 0)))
	var earned := int(round(float(base_reward) * (1.0 + float(upgrades.get("value", 0)))))
	money += earned
	var parent_drop_types: Variant = encounter.get("drop_types", [])
	var final_count := clampi(int(encounter.get("final_drop_count", 0)), 0, 30)
	if parent_drop_types is Array and not parent_drop_types.is_empty():
		for index in range(final_count):
			_enqueue_boss_drop(str(parent_drop_types[index % parent_drop_types.size()]), encounter.get("position", Vector3.ZERO))
	if hud:
		hud.update_money(money)
		hud.show_message("¡Encuentro del Coloso superado! +$%d. El valle queda despejado." % earned)
	_add_player_xp(90)
	_save_game()

func _restore_pending_boss_drops() -> void:
	for record in boss_drop_records:
		queued_boss_drops.append(record.duplicate(true))

func _on_boss_health_changed(_current_health: float, _maximum_health: float, stage: int, boss: TRushGarbageMountainBoss) -> void:
	var previous: Dictionary = boss_progress.get(boss.boss_id, {})
	var previous_stage := int(previous.get("stage", -1))
	boss_progress[boss.boss_id] = boss.progress_snapshot()
	if previous_stage != stage:
		_save_game()

func _on_boss_garbage_release(trash_type: String, is_final_drop: bool, boss: TRushGarbageMountainBoss) -> void:
	boss_progress[boss.boss_id] = boss.progress_snapshot()
	if not is_final_drop and not trash_type.is_empty():
		_enqueue_boss_drop(trash_type, boss.global_position)

func _on_boss_final_drop_batch(trash_types: Array[String], boss: TRushGarbageMountainBoss) -> void:
	boss_progress[boss.boss_id] = boss.progress_snapshot()
	for trash_type in trash_types:
		_enqueue_boss_drop(trash_type, boss.global_position)

func _enqueue_boss_drop(trash_type: String, boss_position: Vector3) -> void:
	if boss_drops_generated_total >= world_trash_budget:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(3.8, 5.2)
	var location := boss_position + Vector3(cos(angle) * radius, 0.06, sin(angle) * radius)
	location.y = 0.06
	if player and location.distance_to(player.global_position) < 3.0:
		var away := Vector2(location.x - player.global_position.x, location.z - player.global_position.z).normalized()
		if away.length_squared() < 0.1:
			away = Vector2.RIGHT.rotated(angle)
		location.x = player.global_position.x + away.x * 3.4
		location.z = player.global_position.z + away.y * 3.4
	location.x = clampf(location.x, -112.0, 112.0)
	location.z = clampf(location.z, -112.0, 112.0)
	var record := {
		"id": "boss_drop_%06d" % next_boss_drop_id,
		"type": trash_type,
		"position": location,
		"reward": _trash_reward_for_type(trash_type)
	}
	next_boss_drop_id += 1
	boss_drop_records.append(record)
	queued_boss_drops.append(record)
	boss_drops_generated_total += 1
	total_trash += 1
	_save_game()

func _drain_boss_drop_queue(maximum_per_frame: int) -> void:
	var spawn_count := mini(maximum_per_frame, queued_boss_drops.size())
	for index in range(spawn_count):
		var record: Dictionary = queued_boss_drops.pop_front()
		_spawn_trash_from_boss_record(record)

func _spawn_trash_from_boss_record(record: Dictionary) -> void:
	var trash := TRASH_SCENE.instantiate() as TrashPickup
	trash.trash_type = str(record.get("type", "Residuo"))
	trash.reward_value = int(record.get("reward", 5))
	trash.trash_value = 1
	trash.position = record.get("position", Vector3.ZERO)
	trash.set_meta("boss_drop", true)
	trash.set_meta("boss_drop_id", str(record.get("id", "")))
	_configure_boss_drop_visual(trash, trash.trash_type)
	add_child(trash)

func _on_trash_item_collected(item: TrashPickup) -> void:
	collected_item_was_boss_drop = item != null and item.has_meta("boss_drop")
	if item == null:
		return
	if not collected_item_was_boss_drop:
		reserved_positions.erase(item.position)
		current_daily_trash.erase(item)
		var item_value := maxi(1, int(item.get("trash_value")))
		var estimated_ordinary_earnings := maxi(0, int(item.get("reward_value"))) * (1 + int(upgrades.get("value", 0)))
		daily_ordinary_money_earned += estimated_ordinary_earnings * item_value
		_check_daily_completion()
		return
	var drop_id := str(item.get_meta("boss_drop_id", ""))
	for index in range(boss_drop_records.size()):
		if str(boss_drop_records[index].get("id", "")) == drop_id:
			boss_drop_records.remove_at(index)
			return

func _trash_reward_for_type(trash_type: String) -> int:
	match trash_type:
		"Botella plastica": return 5
		"Bolsa plastica": return 4
		"Envase plastico": return 6
		"Lata de aluminio": return 8
		"Chatarra metálica": return 11
		"Neumático": return 9
		"Papel y carton": return 6
		"Envase de vidrio": return 12
	return 5

func _configure_boss_drop_visual(trash: TrashPickup, trash_type: String) -> void:
	_configure_trash_visual(trash, trash_type)

func _configure_trash_visual(trash: TrashPickup, trash_type: String, visual_rng: RandomNumberGenerator = null) -> void:
	var visual := trash.get_node("MeshInstance3D") as MeshInstance3D
	if visual == null:
		return
	if not trash_visual_meshes.has(trash_type):
		trash_visual_meshes[trash_type] = _build_trash_visual_mesh(trash_type)
	visual.mesh = trash_visual_meshes[trash_type]
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	visual.material_override = null
	var collision := trash.get_node("CollisionShape3D") as CollisionShape3D
	if trash_type == "Neumático" and collision and collision.shape is SphereShape3D:
		(collision.shape as SphereShape3D).radius = 0.48
	var visual_rotation := randf_range(0.0, TAU)
	if visual_rng != null:
		visual_rotation = visual_rng.randf_range(0.0, TAU)
	trash.rotation.y = visual_rotation

func _build_trash_visual_mesh(trash_type: String) -> ArrayMesh:
	var body_parts: Array[Dictionary] = []
	var detail_parts: Array[Dictionary] = []
	var body_color := Color(0.42, 0.44, 0.38)
	var detail_color := Color(0.8, 0.75, 0.58)
	var roughness := 0.74
	var metallic := 0.04
	var body_transparent := false
	match trash_type:
		"Botella plastica":
			body_color = Color(0.16, 0.46, 0.59)
			detail_color = Color(0.91, 0.29, 0.11)
			roughness = 0.3
			_add_trash_piece(body_parts, _trash_cylinder(0.09, 0.15, 0.58, 28), Vector3(0.0, 0.29, 0.0))
			_add_trash_piece(body_parts, _trash_cylinder(0.062, 0.084, 0.12, 24), Vector3(0.0, 0.625, 0.0))
			_add_trash_piece(detail_parts, _trash_cylinder(0.055, 0.055, 0.055, 20), Vector3(0.0, 0.715, 0.0))
			_add_trash_piece(detail_parts, _trash_box(Vector3(0.105, 0.15, 0.014)), Vector3(0.0, 0.29, -0.144))
			_add_trash_piece(detail_parts, _trash_torus(0.105, 0.122), Vector3(0.0, 0.18, 0.0), Vector3.ZERO, Vector3(0.92, 0.9, 0.92))
		"Bolsa plastica":
			body_color = Color(0.46, 0.61, 0.48, 0.78)
			detail_color = Color(0.66, 0.75, 0.60)
			roughness = 0.43
			body_transparent = true
			_add_trash_piece(body_parts, _trash_sphere(24, 16, 0.5, 0.88), Vector3(0.0, 0.23, 0.0), Vector3.ZERO, Vector3(0.52, 0.48, 0.33))
			for side in [-1.0, 1.0]:
				_add_trash_piece(detail_parts, _trash_torus(0.045, 0.067), Vector3(side * 0.09, 0.43, 0.0), Vector3.ZERO, Vector3(0.78, 0.82, 0.42))
			_add_trash_piece(detail_parts, _trash_box(Vector3(0.018, 0.19, 0.012)), Vector3(-0.075, 0.22, -0.15), Vector3(0.0, 0.0, -0.18))
		"Envase plastico":
			body_color = Color(0.68, 0.64, 0.40)
			detail_color = Color(0.85, 0.31, 0.14)
			roughness = 0.38
			_add_trash_piece(body_parts, _trash_sphere(28, 18, 0.5, 0.92), Vector3(0.0, 0.24, 0.0), Vector3.ZERO, Vector3(0.34, 0.43, 0.29))
			_add_trash_piece(body_parts, _trash_torus(0.07, 0.09), Vector3(0.23, 0.32, -0.015), Vector3(0.0, 0.0, PI * 0.5), Vector3(0.72, 1.0, 0.7))
			_add_trash_piece(detail_parts, _trash_cylinder(0.075, 0.11, 0.12, 20), Vector3(0.0, 0.51, 0.0))
			_add_trash_piece(detail_parts, _trash_cylinder(0.07, 0.07, 0.055, 20), Vector3(0.0, 0.595, 0.0))
		"Lata de aluminio":
			body_color = Color(0.65, 0.71, 0.72)
			detail_color = Color(0.82, 0.26, 0.12)
			roughness = 0.34
			metallic = 0.62
			_add_trash_piece(body_parts, _trash_cylinder(0.14, 0.14, 0.36, 32), Vector3(0.0, 0.19, 0.0))
			_add_trash_piece(detail_parts, _trash_torus(0.125, 0.145), Vector3(0.0, 0.375, 0.0))
			_add_trash_piece(detail_parts, _trash_torus(0.125, 0.145), Vector3(0.0, 0.005, 0.0))
			_add_trash_piece(detail_parts, _trash_torus(0.025, 0.043), Vector3(0.0, 0.385, -0.015), Vector3.ZERO, Vector3(0.75, 0.58, 0.7))
			_add_trash_piece(detail_parts, _trash_box(Vector3(0.12, 0.19, 0.012)), Vector3(0.0, 0.19, -0.136))
		"Chatarra metálica":
			body_color = Color(0.40, 0.44, 0.39)
			detail_color = Color(0.75, 0.62, 0.34)
			roughness = 0.58
			metallic = 0.72
			_add_trash_piece(body_parts, _trash_prism(Vector3(0.38, 0.13, 0.28)), Vector3(0.0, 0.10, 0.0))
			_add_trash_piece(detail_parts, _trash_box(Vector3(0.34, 0.035, 0.07)), Vector3(0.02, 0.17, -0.07), Vector3(0.14, 0.0, 0.12))
			_add_trash_piece(detail_parts, _trash_sphere(16, 10, 0.035, 0.04), Vector3(-0.12, 0.19, -0.10))
		"Neumático":
			body_color = Color(0.065, 0.072, 0.067)
			detail_color = Color(0.20, 0.22, 0.19)
			roughness = 0.88
			_add_trash_piece(body_parts, _trash_torus(0.18, 0.36, 32, 12), Vector3(0.0, 0.19, 0.0))
			_add_trash_piece(detail_parts, _trash_torus(0.145, 0.18), Vector3(0.0, 0.20, 0.0))
		"Papel y carton":
			body_color = Color(0.62, 0.48, 0.31)
			detail_color = Color(0.84, 0.72, 0.49)
			_add_trash_piece(body_parts, _trash_box(Vector3(0.37, 0.055, 0.29)), Vector3(0.0, 0.035, 0.0), Vector3(0.035, 0.0, 0.08))
			_add_trash_piece(body_parts, _trash_box(Vector3(0.16, 0.025, 0.27)), Vector3(0.12, 0.075, 0.0), Vector3(0.0, 0.0, -0.14))
			_add_trash_piece(detail_parts, _trash_box(Vector3(0.052, 0.012, 0.23)), Vector3(-0.035, 0.067, 0.0))
		"Envase de vidrio":
			body_color = Color(0.13, 0.43, 0.33, 0.72)
			detail_color = Color(0.44, 0.69, 0.56, 0.88)
			roughness = 0.18
			body_transparent = true
			_add_trash_piece(body_parts, _trash_cylinder(0.105, 0.17, 0.48, 28), Vector3(0.0, 0.24, 0.0))
			_add_trash_piece(body_parts, _trash_cylinder(0.065, 0.09, 0.13, 20), Vector3(0.0, 0.535, 0.0))
			_add_trash_piece(detail_parts, _trash_torus(0.06, 0.082), Vector3(0.0, 0.605, 0.0))
		_:
			body_color = Color(0.42, 0.44, 0.38)
			_add_trash_piece(body_parts, _trash_sphere(24, 16, 0.22, 0.3), Vector3(0.0, 0.18, 0.0))
	var body_material := _trash_material(body_color, roughness, metallic, body_transparent)
	var detail_material := _trash_material(detail_color, maxf(0.28, roughness - 0.08), metallic * 0.45, false)
	var combined := ArrayMesh.new()
	_append_trash_surface(combined, body_parts, body_material)
	_append_trash_surface(combined, detail_parts, detail_material)
	return combined

func _append_trash_surface(target: ArrayMesh, parts: Array[Dictionary], material: StandardMaterial3D) -> void:
	if parts.is_empty():
		return
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		var source_mesh: Mesh = part["mesh"]
		var transform: Transform3D = part["transform"]
		if source_mesh.get_surface_count() > 0:
			tool.append_from(source_mesh, 0, transform)
	var combined := tool.commit()
	if combined == null or combined.get_surface_count() == 0:
		return
	var surface_index := target.get_surface_count()
	target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, combined.surface_get_arrays(0))
	target.surface_set_material(surface_index, material)

func _add_trash_piece(parts: Array[Dictionary], mesh: Mesh, location: Vector3, rotation_value: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE) -> void:
	var part_transform := Transform3D(Basis.from_euler(rotation_value).scaled(scale_value), location)
	parts.append({"mesh": mesh, "transform": part_transform})

func _trash_material(color: Color, roughness: float, metallic: float, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _trash_cylinder(top_radius: float, bottom_radius: float, height_value: float, segments: int = 24) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height_value
	mesh.radial_segments = segments
	return mesh

func _trash_sphere(segments: int, rings: int, radius_value: float, height_value: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radial_segments = segments
	mesh.rings = rings
	mesh.radius = radius_value
	mesh.height = height_value
	return mesh

func _trash_torus(inner_radius: float, outer_radius: float, rings: int = 24, ring_segments: int = 8) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = rings
	mesh.ring_segments = ring_segments
	return mesh

func _trash_box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _trash_prism(size: Vector3) -> PrismMesh:
	var mesh := PrismMesh.new()
	mesh.size = size
	return mesh

func _on_boss_defeated(boss_id: String, reward: int) -> void:
	if defeated_boss_ids.has(boss_id):
		return
	defeated_boss_ids.append(boss_id)
	var defeated_boss: TRushGarbageMountainBoss
	for index in range(active_bosses.size() - 1, -1, -1):
		var boss := active_bosses[index]
		if not is_instance_valid(boss):
			active_bosses.remove_at(index)
			continue
		if boss is TRushGarbageMountainBoss and boss.boss_id == boss_id:
			defeated_boss = boss
			boss_progress[boss_id] = boss.progress_snapshot()
	var earned := int(round(float(reward) * (1.0 + float(upgrades.get("value", 0)))))
	money += earned
	if hud:
		hud.update_money(money)
		hud.show_message("¡Mini-jefe derrotado! +$%d." % earned if defeated_boss and not defeated_boss.split_parent_id.is_empty() else "¡Montaña derrotada! +$%d. Recoge los residuos liberados." % earned)
	_add_player_xp(45 if defeated_boss and not defeated_boss.split_parent_id.is_empty() else 90)
	if defeated_boss and not defeated_boss.split_parent_id.is_empty():
		var parent_id := defeated_boss.split_parent_id
		var encounter: Dictionary = boss_encounters.get(parent_id, {})
		var remaining: Variant = encounter.get("remaining_ids", [])
		if remaining is Array:
			remaining.erase(boss_id)
			encounter["remaining_ids"] = remaining
			boss_encounters[parent_id] = encounter
			if remaining.is_empty():
				_complete_split_encounter(parent_id)
	_save_game()

func _update_boss_hud() -> void:
	if hud == null or player == null:
		return
	if hud.is_modal_open():
		hud.hide_boss()
		return
	var selected: TRushGarbageMountainBoss
	var selected_distance := INF
	if player.targeted_boss and is_instance_valid(player.targeted_boss) and not player.targeted_boss.is_defeated:
		selected = player.targeted_boss
		selected_distance = player.global_position.distance_to(selected.global_position)
	else:
		for actor in active_bosses:
			if not is_instance_valid(actor) or not actor is TRushGarbageMountainBoss or actor.is_defeated:
				continue
			var distance := player.global_position.distance_to(actor.global_position)
			if distance <= 22.0 and distance < selected_distance:
				selected = actor
				selected_distance = distance
	if selected:
		hud.update_boss(selected.boss_name, selected.current_health, selected.maximum_health, selected.damage_stage, selected_distance)
	else:
		hud.hide_boss()

func _populate_ground_detail(rng: RandomNumberGenerator, parent: Node3D) -> void:
<<<<<<< Updated upstream
	# Decoración ligera con recursos compartidos y sin colisiones innecesarias.
	var grass_materials: Array[StandardMaterial3D] = []
	for color in [Color(0.24, 0.39, 0.18), Color(0.34, 0.43, 0.20), Color(0.43, 0.42, 0.22)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		grass_materials.append(material)
	var blade_mesh := PrismMesh.new()
	blade_mesh.size = Vector3(0.065, 0.36, 0.045)
	var patch_centers: Array[Vector3] = []
	for i in range(12):
		patch_centers.append(_random_map_position(rng, 7.0, 36.0, 5.4))
	for i in range(72):
		var tuft := Node3D.new()
		var center := patch_centers[i % patch_centers.size()]
		tuft.position = center + Vector3(rng.randf_range(-2.0, 2.0), 0.0, rng.randf_range(-2.0, 2.0))
		tuft.add_to_group("quality_detail")
		for blade in range(3):
			var blade_node := MeshInstance3D.new()
			blade_node.mesh = blade_mesh
			blade_node.position = Vector3(rng.randf_range(-0.12, 0.12), 0.18, rng.randf_range(-0.12, 0.12))
			blade_node.rotation = Vector3(0.0, rng.randf_range(0.0, TAU), rng.randf_range(-0.38, 0.38))
			blade_node.material_override = grass_materials[rng.randi_range(0, grass_materials.size() - 1)]
			tuft.add_child(blade_node)
		parent.add_child(tuft)
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radial_segments = 10
	leaf_mesh.rings = 6
	leaf_mesh.radius = 0.17
	leaf_mesh.height = 0.29
	var leaf_materials: Array[StandardMaterial3D] = []
	for color in [Color(0.15, 0.34, 0.13), Color(0.25, 0.43, 0.17), Color(0.36, 0.48, 0.21)]:
		var leaf_material := StandardMaterial3D.new()
		leaf_material.albedo_color = color
		leaf_material.roughness = 1.0
		leaf_materials.append(leaf_material)
	for i in range(34):
		var plant := Node3D.new()
		plant.position = _random_map_position(rng, 8.0, 37.0, 5.2)
		plant.add_to_group("quality_detail")
		for j in range(3):
			var leaf := MeshInstance3D.new()
			leaf.mesh = leaf_mesh
			leaf.position = Vector3(rng.randf_range(-0.18, 0.18), rng.randf_range(0.12, 0.34), rng.randf_range(-0.18, 0.18))
			leaf.scale = Vector3(0.7, 1.0, 1.35)
			leaf.material_override = leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)]
			plant.add_child(leaf)
		parent.add_child(plant)
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.34, 0.36, 0.32)
	rock_material.roughness = 1.0
	for i in range(8):
=======
	# Render the individual blades as one instanced batch. Their transforms and
	# colors retain the clustered variation without thousands of scene nodes.
	var grass_material := ShaderMaterial.new()
	grass_material.shader = load("res://shaders/grass_wind.gdshader") as Shader
	var blade_mesh := PrismMesh.new()
	blade_mesh.size = Vector3(0.065, 0.38, 0.045)
	var grass_multimesh := MultiMesh.new()
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass_multimesh.use_colors = true
	grass_multimesh.use_custom_data = true
	grass_multimesh.mesh = blade_mesh
	var grass_transforms: Array[Transform3D] = []
	var grass_colors: Array[Color] = []
	var grass_phases: Array[float] = []
	var grass_palette := [Color(0.24, 0.39, 0.18), Color(0.34, 0.43, 0.20), Color(0.43, 0.42, 0.22)]
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.34, 0.36, 0.32)
	rock_material.roughness = 1.0
	# Distribuir el pasto en parches reconocibles, no como puntos aislados uniformes.
	var grass_patch_centers: Array[Vector3] = []
	for patch_index in range(27):
		grass_patch_centers.append(Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52)))
	for i in range(324):
		var patch_center := grass_patch_centers[i % grass_patch_centers.size()]
		var tuft_position := patch_center + Vector3(rng.randf_range(-3.2, 3.2), 0.0, rng.randf_range(-3.2, 3.2))
		var blade_count := rng.randi_range(4, 7)
		for blade in range(blade_count):
			var blade_height := rng.randf_range(0.22, 0.48)
			var blade_transform := Transform3D(
				Basis.from_euler(Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(0.0, TAU), rng.randf_range(-0.42, 0.42))).scaled(Vector3(1.0, blade_height / 0.38, 1.0)),
				tuft_position + Vector3(rng.randf_range(-0.15, 0.15), blade_height * 0.5, rng.randf_range(-0.15, 0.15))
			)
			grass_transforms.append(blade_transform)
			grass_colors.append(grass_palette[rng.randi_range(0, grass_palette.size() - 1)])
			grass_phases.append(rng.randf_range(0.0, TAU))
	grass_multimesh.instance_count = grass_transforms.size()
	for index in range(grass_transforms.size()):
		grass_multimesh.set_instance_transform(index, grass_transforms[index])
		grass_multimesh.set_instance_color(index, grass_colors[index])
		grass_multimesh.set_instance_custom_data(index, Color(grass_phases[index], 0.0, 0.0, 1.0))
	var grass_batch := MultiMeshInstance3D.new()
	grass_batch.name = "GrassBladeBatch"
	grass_batch.multimesh = grass_multimesh
	grass_batch.material_override = grass_material
	parent.add_child(grass_batch)
	var shrub_transforms: Array[Transform3D] = []
	var shrub_colors: Array[Color] = []
	var berry_transforms: Array[Transform3D] = []
	var leaf_palette := [Color(0.15, 0.34, 0.13), Color(0.25, 0.43, 0.17), Color(0.36, 0.48, 0.21)]
	for plant_index in range(135):
		var plant_position := Vector3(rng.randf_range(-56, 56), 0.0, rng.randf_range(-56, 56))
		for leaf_index in range(5):
			var leaf_radius := rng.randf_range(0.12, 0.22)
			var leaf_position := plant_position + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.12, 0.38), rng.randf_range(-0.2, 0.2))
			var leaf_transform := Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.3, 0.3))).scaled(Vector3(leaf_radius * 0.7, leaf_radius * 0.85, leaf_radius * 1.35)), leaf_position)
			shrub_transforms.append(leaf_transform)
			shrub_colors.append(leaf_palette[rng.randi_range(0, leaf_palette.size() - 1)])
		if rng.randf() < 0.22:
			for berry_index in range(rng.randi_range(3, 6)):
				var berry_position := plant_position + Vector3(rng.randf_range(-0.22, 0.22), rng.randf_range(0.18, 0.42), rng.randf_range(-0.22, 0.22))
				berry_transforms.append(Transform3D(Basis().scaled(Vector3.ONE * 0.055), berry_position))
	if not shrub_transforms.is_empty():
		var shrub_mesh := SphereMesh.new()
		shrub_mesh.radial_segments = 16
		shrub_mesh.rings = 10
		var shrub_material := StandardMaterial3D.new()
		shrub_material.albedo_color = Color.WHITE
		shrub_material.vertex_color_use_as_albedo = true
		shrub_material.roughness = 0.98
		var shrubs := MultiMesh.new()
		shrubs.transform_format = MultiMesh.TRANSFORM_3D
		shrubs.use_colors = true
		shrubs.mesh = shrub_mesh
		shrubs.instance_count = shrub_transforms.size()
		for index in range(shrub_transforms.size()):
			shrubs.set_instance_transform(index, shrub_transforms[index])
			shrubs.set_instance_color(index, shrub_colors[index])
		var shrub_batch := MultiMeshInstance3D.new()
		shrub_batch.name = "ForestShrubBatch"
		shrub_batch.multimesh = shrubs
		shrub_batch.material_override = shrub_material
		parent.add_child(shrub_batch)
	if not berry_transforms.is_empty():
		var berry_mesh := SphereMesh.new()
		berry_mesh.radial_segments = 10
		berry_mesh.rings = 6
		var berries := MultiMesh.new()
		berries.transform_format = MultiMesh.TRANSFORM_3D
		berries.mesh = berry_mesh
		berries.instance_count = berry_transforms.size()
		for index in range(berry_transforms.size()):
			berries.set_instance_transform(index, berry_transforms[index])
		var berry_batch := MultiMeshInstance3D.new()
		berry_batch.name = "ForestBerryBatch"
		berry_batch.multimesh = berries
		berry_batch.material_override = _detail_material(Color(0.72, 0.12, 0.16))
		parent.add_child(berry_batch)
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
>>>>>>> Stashed changes
		var rock_mesh := SphereMesh.new()
		rock_mesh.radial_segments = 12
		rock_mesh.rings = 8
		rock_mesh.radius = rng.randf_range(0.8, 1.7)
		rock_mesh.height = rock_mesh.radius * rng.randf_range(0.65, 1.1)
		var boulder := MeshInstance3D.new()
		boulder.mesh = rock_mesh
		var pos := _random_map_position(rng, 20.0, 37.0, 5.0)
		if not _is_clear_location(pos, rock_mesh.radius * 1.7):
			continue
		boulder.position = Vector3(pos.x, rock_mesh.radius * 0.32, pos.z)
		boulder.scale = Vector3(1.2, 0.8, 1.1)
		boulder.material_override = rock_material
		boulder.add_to_group("quality_detail")
		parent.add_child(boulder)
	for i in range(22):
		var small_mesh := SphereMesh.new()
		small_mesh.radial_segments = 8
		small_mesh.rings = 5
		small_mesh.radius = rng.randf_range(0.22, 0.55)
		small_mesh.height = small_mesh.radius
		var rock := MeshInstance3D.new()
		rock.mesh = small_mesh
		var pos := _random_map_position(rng, 6.0, 38.0, 5.5)
		rock.position = Vector3(pos.x, small_mesh.radius * 0.34, pos.z)
		rock.material_override = rock_material
		rock.add_to_group("quality_detail")
		parent.add_child(rock)

func _create_zone_markers() -> void:
	var zones := [
		{"name": "BOSQUE PROFUNDO", "position": Vector3(-33, 0, -33), "color": Color(0.45, 0.75, 0.48)},
		{"name": "ARROYO", "position": Vector3(33, 0, -33), "color": Color(0.35, 0.68, 0.82)},
		{"name": "VERTEDERO", "position": Vector3(33, 0, 33), "color": Color(0.78, 0.68, 0.36)},
		{"name": "ZONA ROCOSA", "position": Vector3(-33, 0, 33), "color": Color(0.72, 0.72, 0.66)}
	]
	for zone in zones:
		var sign_root := Node3D.new()
		sign_root.position = zone["position"]
		sign_root.set_script(SIGN_SCRIPT)
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
	material.roughness = 0.72
	material.metallic = 0.12
	base.material_override = material
	station.add_child(base)
	var bin_colors := [Color(0.15, 0.55, 0.78), Color(0.78, 0.68, 0.18), Color(0.18, 0.62, 0.38)]
	var bin_labels := ["PLÁSTICO", "METALES", "VIDRIO"]
	for i in range(3):
		var bin := MeshInstance3D.new()
		var bin_mesh := BoxMesh.new()
		bin_mesh.size = Vector3(0.48, 0.78, 0.48)
		bin.mesh = bin_mesh
		bin.position = Vector3(-0.68 + float(i) * 0.68, 0.82, 0.0)
		var bin_material := StandardMaterial3D.new()
		bin_material.albedo_color = bin_colors[i]
		bin_material.roughness = 0.68
		bin_material.metallic = 0.16
		bin.material_override = bin_material
		station.add_child(bin)
		var lid := MeshInstance3D.new()
		var lid_mesh := BoxMesh.new()
		lid_mesh.size = Vector3(0.54, 0.09, 0.54)
		lid.mesh = lid_mesh
		lid.position = bin.position + Vector3(0.0, 0.42, 0.0)
		lid.material_override = _detail_material(bin_colors[i].darkened(0.32))
		station.add_child(lid)
		var bin_label := Label3D.new()
		bin_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bin_label.text = bin_labels[i]
		bin_label.position = bin.position + Vector3(0.0, 0.0, -0.27)
		bin_label.font_size = 14
		bin_label.modulate = Color(0.97, 0.98, 0.91)
		bin_label.outline_size = 3
		bin_label.outline_modulate = Color(0.06, 0.08, 0.07, 0.95)
		station.add_child(bin_label)
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
	station_sign.text = TRushProfiles.get_ui_text("recycle")
	station_sign.position.y = 1.6
	station_sign.font_size = roundi(48.0 * float(TRushProfiles.get_setting("ui_font_scale", 1.0)))
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
	wood.roughness = 0.9
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.16, 0.42, 0.27)
	green.roughness = 0.82
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
	label.name = "ShopSign"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = TRushProfiles.get_ui_text("shop")
	label.position.y = 2.35
	label.font_size = roundi(34.0 * float(TRushProfiles.get_setting("ui_font_scale", 1.0)))
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
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(3.8, 0.08, 3.0)
	floor.mesh = floor_mesh
	floor.position.y = 0.04
	floor.material_override = _detail_material(Color(0.25, 0.20, 0.14))
	sleep_hut.add_child(floor)
	_add_box_collision(sleep_hut, floor.position, floor_mesh.size)
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
	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.95, 1.95, 0.08)
	door.mesh = door_mesh
	door.position = Vector3(0.0, 1.0, 1.29)
	door.material_override = _detail_material(Color(0.19, 0.12, 0.075))
	sleep_hut.add_child(door)
	var window := MeshInstance3D.new()
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(0.62, 0.52, 0.07)
	window.mesh = window_mesh
	window.position = Vector3(1.18, 1.72, 1.29)
	var window_material := StandardMaterial3D.new()
	window_material.albedo_color = Color(0.28, 0.50, 0.53, 0.8)
	window_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	window_material.roughness = 0.22
	window.material_override = window_material
	sleep_hut.add_child(window)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(4.2, 0.28, 3.6)
	roof.mesh = roof_mesh
	roof.position.y = 2.65
	roof.material_override = _detail_material(Color(0.18, 0.32, 0.20))
	sleep_hut.add_child(roof)
	for side in [-1.0, 1.0]:
		var rafter := MeshInstance3D.new()
		var rafter_mesh := BoxMesh.new()
		rafter_mesh.size = Vector3(0.16, 0.34, 3.72)
		rafter.mesh = rafter_mesh
		rafter.position = Vector3(side * 1.97, 2.52, 0.0)
		rafter.rotation.z = side * -0.08
		rafter.material_override = wood
		sleep_hut.add_child(rafter)
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
	sign.text = TRushProfiles.get_ui_text("rest")
	sign.position = Vector3(0, 2.0, -1.55)
	sign.font_size = roundi(32.0 * float(TRushProfiles.get_setting("ui_font_scale", 1.0)))
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
<<<<<<< Updated upstream
	if player:
		player.heal(35.0)
=======
	day_number += 1
	for item in current_daily_trash:
		if is_instance_valid(item):
			reserved_positions.erase(item.position)
			item.queue_free()
	current_daily_trash.clear()
	daily_target = _daily_target_for_level(int(upgrades.get("daily_quota", 0)))
	daily_collected_count = 0
	daily_ordinary_money_earned = 0
	daily_bonus_paid = false
	total_trash += daily_target
	_spawn_trash()
	daily_fruit_remaining = 3
	if fruit_basket and is_instance_valid(fruit_basket):
		fruit_basket.call("refill_for_new_day")
>>>>>>> Stashed changes
	_on_phase_changed()
	if hud:
		hud.update_daily_cleanup(daily_target, daily_collected_count, daily_bonus_paid)
		hud.show_message("¡Día %d! Hay %d residuos disponibles y la canasta volvió a llenarse." % [day_number, daily_target])
	_save_game()

func _is_clear_location(location: Vector3, clearance: float) -> bool:
	if location.length() < 8.0:
		return false
	if Vector2(location.x - 27.0, location.z + 27.0).length() < 7.0:
		return false
	for reserved in reserved_positions:
		if Vector2(location.x, location.z).distance_to(Vector2(reserved.x, reserved.z)) < clearance:
			return false
	return true

func _create_hud() -> void:
	hud = HUD_SCRIPT.new() as TRushHUD
	add_child(hud)
	hud.update_health(player.current_health, player.max_health)
	hud.update_graphics_quality(graphics_quality)
	hud.upgrade_requested.connect(_buy_upgrade)
	hud.cleaner_collect_requested.connect(_collect_cleaner_earnings)
	hud.cleaner_toggle_requested.connect(_toggle_cleaner_operation)
	hud.options_changed.connect(_apply_options)
	hud.prestige_requested.connect(_request_prestige_confirmation)
	hud.prestige_confirmed.connect(_perform_prestige)
	hud.skill_requested.connect(_spend_skill_point)
	player.skill_requested.connect(hud.toggle_skills)
	player.health_changed.connect(hud.update_player_health)
	player.took_damage.connect(func(_amount: float): hud.show_damage_feedback())
	player.health_depleted.connect(_on_player_health_depleted)
	player.fruit_requested.connect(_on_fruit_requested)
	hud.bestiary_toggled.connect(hud.toggle_bestiary)
	hud.set_upgrade_access(not is_day)
	hud.update_player_health(player.current_health, player.maximum_health)
	hud.update_mission("Recolecta residuos y llévalos a reciclar")
	hud.update_skill_status(player_level, skill_points, skill_levels)
	hud.update_daily_cleanup(daily_target, daily_collected_count, daily_bonus_paid)
	hud.update_prestige_state(prestige_points, prestige_count, prestige_history)
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	_refresh_bestiary()

func _restore_cleaner_state() -> void:
	if player == null:
		return
	cleaner_installations.resize(mini(cleaner_installations.size(), 8))
	cleaner_income_level = clampi(cleaner_income_level, 0, maxi(0, _cleaner_rate_count() - 1))
	cleaner_storage_level = clampi(cleaner_storage_level, 0, maxi(0, _cleaner_capacity_count() - 1))
	var valid_records: Array[Dictionary] = []
	for saved_record in cleaner_installations:
		var location_id := str(saved_record.get("location", ""))
		var saved_position: Variant = saved_record.get("position", Vector3.ZERO)
		if not saved_position is Vector3 or not _is_valid_saved_cleaner_position(location_id, saved_position):
			continue
		var overlaps := false
		for existing in valid_records:
			var existing_position: Vector3 = existing.get("position", Vector3.ZERO)
			if Vector2(existing_position.x, existing_position.z).distance_to(Vector2(saved_position.x, saved_position.z)) < 2.1:
				overlaps = true
				break
		if overlaps:
			continue
		var record: Dictionary = saved_record.duplicate(true)
		record["stored_money"] = clampi(int(record.get("stored_money", 0)), 0, _cleaner_capacity())
		record["elapsed_seconds"] = clampf(float(record.get("elapsed_seconds", 0.0)), 0.0, 59.99)
		var machine := CLEANER_SCENE.instantiate() as Node3D
		machine.name = "InstalledPortableCleaner_%s" % str(record.get("id", valid_records.size() + 1))
		add_child(machine)
		machine.position = saved_position
		machine.rotation.y = cleaner_install_yaw(location_id)
		machine.call("set_operational_state", true, bool(record.get("operational", true)))
		record["machine"] = machine
		valid_records.append(record)
	cleaner_installations = valid_records
	cleaner_installed = not cleaner_installations.is_empty()
	cleaner_owned_count = clampi(maxi(cleaner_owned_count, cleaner_installations.size() + (1 if cleaner_pending_installation else 0)), 0, 8)
	cleaner_owned = cleaner_owned_count > 0
	cleaner_pending_installation = cleaner_pending_installation and cleaner_owned_count > cleaner_installations.size()
	if cleaner_owned_count > cleaner_installations.size() and not cleaner_pending_installation:
		cleaner_pending_installation = true
	if not cleaner_installations.is_empty():
		_select_cleaner_record(0)
	if cleaner_pending_installation:
		_spawn_cleaner_in_hand()

func _spawn_cleaner_in_hand() -> void:
	if not cleaner_pending_installation or player == null or player.cleaner_carry_mount == null:
		return
	if cleaner_carried_machine and is_instance_valid(cleaner_carried_machine):
		return
	cleaner_carried_machine = CLEANER_SCENE.instantiate() as Node3D
	cleaner_carried_machine.name = "CarriedPortableCleaner"
	player.cleaner_carry_mount.add_child(cleaner_carried_machine)
	cleaner_carried_machine.scale = Vector3.ONE * 0.43
	cleaner_carried_machine.position = Vector3.ZERO
	cleaner_carried_machine.call("set_operational_state", false, false)
	if cleaner_installations.is_empty():
		cleaner_machine = cleaner_carried_machine

func _update_cleaner_context() -> void:
	if player == null or hud == null:
		return
	if cleaner_pending_installation:
		_spawn_cleaner_in_hand()
		var placement := _cleaner_placement_for_player(player.global_position)
		cleaner_preview_valid = bool(placement.get("valid", false))
		cleaner_preview_location = str(placement.get("location", ""))
		cleaner_preview_position = placement.get("position", player.global_position + Vector3.UP * 0.11)
		cleaner_preview_yaw = float(placement.get("yaw", 0.0))
		if cleaner_preview == null or not is_instance_valid(cleaner_preview):
			cleaner_preview = CLEANER_SCENE.instantiate() as Node3D
			cleaner_preview.name = "CleanerPlacementPreview"
			add_child(cleaner_preview)
			cleaner_preview.call("set_preview_mode", cleaner_preview_valid)
		cleaner_preview.scale = Vector3.ONE * 0.88
		cleaner_preview.call("set_preview_mode", cleaner_preview_valid)
		cleaner_preview.global_position = cleaner_preview_position
		cleaner_preview.rotation = Vector3(0.0, cleaner_preview_yaw, 0.0)
		player.cleaner_interaction_priority = true
		var location_name := "Estanque circular" if cleaner_preview_location == "circular_stream" else "Arroyo de la Rana"
		var prompt := "LIMPIADORA · [E] instalar en %s" % location_name if cleaner_preview_valid else "LIMPIADORA · elige agua válida · [E] para comprobar"
		hud.set_cleaner_context(prompt, not hud.is_modal_open())
		return
	if cleaner_preview and is_instance_valid(cleaner_preview):
		cleaner_preview.queue_free()
	cleaner_preview = null
	var nearest_index := -1
	var nearest_distance := INF
	for index in range(cleaner_installations.size()):
		var record: Dictionary = cleaner_installations[index]
		var machine: Variant = record.get("machine", null)
		if not machine is Node3D or not is_instance_valid(machine):
			continue
		var distance := player.global_position.distance_to((machine as Node3D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	if nearest_index >= 0:
		_select_cleaner_record(nearest_index)
		var near_machine := nearest_distance <= 4.2
		player.cleaner_interaction_priority = near_machine
		var show_machine_prompt := near_machine and not hud.is_modal_open()
		hud.set_cleaner_context("LIMPIADORA %d/8 · [E] administrar" % [nearest_index + 1] if show_machine_prompt else "", show_machine_prompt)
	else:
		player.cleaner_interaction_priority = false
		hud.set_cleaner_context("", false)

func _cleaner_placement_for_player(player_position: Vector3) -> Dictionary:
	var placement: Dictionary = cleaner_balance.get("placement", {})
	var facing := player.global_basis.z if player != null else Vector3.FORWARD
	var fallback_position := player_position - facing * 2.5
	fallback_position.y = 0.11
	var fallback_yaw := player.rotation.y if player != null else 0.0
	var fallback := {"valid": false, "location": "", "position": fallback_position, "yaw": fallback_yaw}
	if not cleaner_pending_installation or cleaner_installations.size() >= 8 or player == null:
		return fallback
	var player_xz := Vector2(player_position.x, player_position.z)
	var pond_values: Array = placement.get("pond_center", [70.0, 68.0])
	var pond_center := Vector2(float(pond_values[0]), float(pond_values[1]))
	var pond_radius := float(placement.get("pond_radius", 9.0))
	var pond_player_reach := float(placement.get("pond_player_reach", 4.6))
	var nearest_candidate: Dictionary = {}
	var nearest_candidate_distance := INF
	if player_xz.distance_to(pond_center) <= pond_radius + pond_player_reach:
		for candidate in _cleaner_slot_positions("circular_stream"):
			if not _cleaner_position_available(candidate):
				continue
			var candidate_xz := Vector2(candidate.x, candidate.z)
			var candidate_distance := player_xz.distance_to(candidate_xz)
			if candidate_distance < 1.2 or candidate_distance > pond_player_reach or candidate_distance >= nearest_candidate_distance:
				continue
			var inward := pond_center - candidate_xz
			nearest_candidate_distance = candidate_distance
			nearest_candidate = {"valid": true, "location": "circular_stream", "position": candidate, "yaw": atan2(-inward.x, -inward.y)}
	if not nearest_candidate.is_empty():
		return nearest_candidate
	var frog_start_values: Array = placement.get("frog_stream_segment_start", [81.0, 80.0])
	var frog_end_values: Array = placement.get("frog_stream_segment_end", [101.0, 102.0])
	var frog_start := Vector2(float(frog_start_values[0]), float(frog_start_values[1]))
	var frog_end := Vector2(float(frog_end_values[0]), float(frog_end_values[1]))
	var frog_projection := _closest_point_on_segment(player_xz, frog_start, frog_end)
	var frog_tangent := (frog_end - frog_start).normalized()
	var frog_distance := player_xz.distance_to(frog_projection)
	var frog_player_reach := float(placement.get("frog_stream_player_reach", 4.4))
	if frog_distance <= frog_player_reach:
		for candidate in _cleaner_slot_positions("frog_stream"):
			if not _cleaner_position_available(candidate):
				continue
			var candidate_distance := player_xz.distance_to(Vector2(candidate.x, candidate.z))
			if candidate_distance < 1.2 or candidate_distance > frog_player_reach or candidate_distance >= nearest_candidate_distance:
				continue
			var tangent3 := Vector3(frog_tangent.x, 0.0, frog_tangent.y)
			nearest_candidate_distance = candidate_distance
			nearest_candidate = {"valid": true, "location": "frog_stream", "position": candidate, "yaw": atan2(-tangent3.x, -tangent3.z)}
	if not nearest_candidate.is_empty():
		return nearest_candidate
	return fallback

func _cleaner_slot_positions(location_id: String) -> Array[Vector3]:
	var placement: Dictionary = cleaner_balance.get("placement", {})
	var slots: Array[Vector3] = []
	if location_id == "circular_stream":
		var center_values: Array = placement.get("pond_center", [70.0, 68.0])
		var center := Vector2(float(center_values[0]), float(center_values[1]))
		var radius := float(placement.get("pond_machine_radius", 6.4))
		for index in range(4):
			var angle := TAU * float(index) / 4.0 + PI * 0.25
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			slots.append(Vector3(point.x, 0.11, point.y))
	else:
		var start_values: Array = placement.get("frog_stream_segment_start", [81.0, 80.0])
		var end_values: Array = placement.get("frog_stream_segment_end", [101.0, 102.0])
		var start := Vector2(float(start_values[0]), float(start_values[1]))
		var finish := Vector2(float(end_values[0]), float(end_values[1]))
		var tangent := (finish - start).normalized()
		var side := Vector2(-tangent.y, tangent.x)
		var offsets := [-0.9, 0.9, -0.9, 0.9]
		for index in range(4):
			var point := start.lerp(finish, 0.12 + 0.25 * float(index)) + side * float(offsets[index])
			slots.append(Vector3(point.x, 0.11, point.y))
	return slots

func _cleaner_position_available(candidate: Vector3) -> bool:
	for record in cleaner_installations:
		var installed: Vector3 = record.get("position", Vector3.ZERO)
		if Vector2(candidate.x, candidate.z).distance_to(Vector2(installed.x, installed.z)) < 2.1:
			return false
	return true

func _closest_point_on_segment(point: Vector2, start: Vector2, finish: Vector2) -> Vector2:
	var segment := finish - start
	if segment.length_squared() < 0.0001:
		return start
	var amount := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return start + segment * amount

func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	return point.distance_to(_closest_point_on_segment(point, start, finish))

func cleaner_install_yaw(location_id: String) -> float:
	if location_id == "frog_stream":
		var placement: Dictionary = cleaner_balance.get("placement", {})
		var start_values: Array = placement.get("frog_stream_segment_start", [81.0, 80.0])
		var end_values: Array = placement.get("frog_stream_segment_end", [101.0, 102.0])
		var direction := Vector2(float(end_values[0]) - float(start_values[0]), float(end_values[1]) - float(start_values[1])).normalized()
		return atan2(-direction.x, -direction.y)
	return 0.0

func _is_valid_saved_cleaner_position(location_id: String, saved_position: Vector3) -> bool:
	if saved_position.y < -0.2 or saved_position.y > 0.5:
		return false
	var placement: Dictionary = cleaner_balance.get("placement", {})
	var point := Vector2(saved_position.x, saved_position.z)
	if location_id == "circular_stream":
		var center_values: Array = placement.get("pond_center", [70.0, 68.0])
		var center := Vector2(float(center_values[0]), float(center_values[1]))
		return point.distance_to(center) <= float(placement.get("pond_radius", 9.0))
	if location_id == "frog_stream":
		var start_values: Array = placement.get("frog_stream_segment_start", [81.0, 80.0])
		var end_values: Array = placement.get("frog_stream_segment_end", [101.0, 102.0])
		var start := Vector2(float(start_values[0]), float(start_values[1]))
		var finish := Vector2(float(end_values[0]), float(end_values[1]))
		return _distance_to_segment(point, start, finish) <= float(placement.get("frog_stream_half_width", 1.8))
	return false

func _on_cleaner_interaction_requested() -> void:
	if cleaner_owned and not cleaner_installed:
		if not cleaner_preview_valid:
			if hud:
				hud.show_message("La limpiadora solo se instala en el estanque circular o el Arroyo de la Rana.")
			return
		_install_cleaner_at_preview()
		return
	if cleaner_installed and cleaner_machine and player.global_position.distance_to(cleaner_machine.global_position) <= 4.2:
		hud.show_cleaner_management(not hud.cleaner_panel.visible)

func _install_cleaner_at_preview() -> void:
	if not cleaner_machine or not is_instance_valid(cleaner_machine) or not cleaner_preview_valid or not _is_valid_saved_cleaner_position(cleaner_preview_location, cleaner_preview_position):
		if hud:
			hud.show_message("La ubicación ya no es válida; la limpiadora sigue en tu mano.")
		return
	var previous_parent: Node = cleaner_machine.get_parent()
	if previous_parent:
		previous_parent.remove_child(cleaner_machine)
	add_child(cleaner_machine)
	cleaner_machine.name = "InstalledPortableCleaner"
	cleaner_machine.scale = Vector3.ONE
	cleaner_machine.position = cleaner_preview_position
	cleaner_machine.rotation = Vector3(0.0, cleaner_preview_yaw, 0.0)
	cleaner_location_id = cleaner_preview_location
	cleaner_install_position = cleaner_preview_position
	cleaner_installed = true
	cleaner_operational = true
	cleaner_elapsed_seconds = 0.0
	cleaner_machine.call("set_operational_state", true, true)
	cleaner_machine.call("play_installation_feedback")
	if cleaner_preview and is_instance_valid(cleaner_preview):
		cleaner_preview.queue_free()
	cleaner_preview = null
	cleaner_preview_valid = false
	player.cleaner_interaction_priority = player.global_position.distance_to(cleaner_machine.global_position) <= 4.2
	hud.show_message("Limpiadora instalada en %s. ¡Comienza a filtrar!" % ("el estanque circular" if cleaner_location_id == "circular_stream" else "el Arroyo de la Rana"))
	_update_cleaner_hud()
	_save_game()

func _collect_cleaner_earnings() -> void:
	if not cleaner_installed or cleaner_stored_money <= 0:
		return
	var collected := cleaner_stored_money
	cleaner_stored_money = 0
	cleaner_elapsed_seconds = 0.0
	money += collected
	if hud:
		hud.update_money(money)
		hud.show_message("Ingresos de la limpiadora: +$%d" % collected)
	_update_cleaner_hud()
	_save_game()

func _toggle_cleaner_operation() -> void:
	if not cleaner_installed:
		return
	cleaner_operational = not cleaner_operational
	cleaner_machine.call("set_operational_state", true, cleaner_operational)
	if hud:
		hud.show_message("Limpiadora %s." % ("encendida" if cleaner_operational else "apagada"))
	_update_cleaner_hud()
	_save_game()

func _update_cleaner_income_upgrade() -> void:
	var cost := _cleaner_upgrade_cost("income_upgrade_costs", cleaner_income_level)
	if not cleaner_installed or cost < 0:
		return
	if money < cost:
		if hud:
			hud.show_message("Fondos insuficientes para la mejora de ingresos: necesitas $%d." % cost)
		return
	money -= cost
	cleaner_income_level += 1
	if hud:
		hud.update_money(money)
		hud.show_message("Ingreso mejorado: ahora genera $%d por minuto." % _cleaner_income_rate())
	_update_cleaner_hud()
	_save_game()

func _update_cleaner_storage_upgrade() -> void:
	var cost := _cleaner_upgrade_cost("storage_upgrade_costs", cleaner_storage_level)
	if not cleaner_installed or cost < 0:
		return
	if money < cost:
		if hud:
			hud.show_message("Fondos insuficientes para ampliar el depósito: necesitas $%d." % cost)
		return
	money -= cost
	cleaner_storage_level += 1
	cleaner_stored_money = mini(cleaner_stored_money, _cleaner_capacity())
	if hud:
		hud.update_money(money)
		hud.show_message("Depósito ampliado a $%d sin perder los ingresos guardados." % _cleaner_capacity())
	_update_cleaner_hud()
	_save_game()

func _update_boss_area_introduction(delta: float) -> void:
	boss_intro_cooldown = maxf(0.0, boss_intro_cooldown - delta)
	if player == null:
		return
	var near_boss_area := false
	for boss in get_tree().get_nodes_in_group("garbage_boss"):
		if boss is TRushGarbageMountainBoss and not boss.is_defeated and player.global_position.distance_to(boss.global_position) <= 30.0:
			near_boss_area = true
			break
	if not boss_intro_tracking_initialized:
		boss_intro_tracking_initialized = true
		boss_area_player_inside = near_boss_area
		return
	if not near_boss_area:
		boss_area_player_inside = false
		return
	if boss_area_player_inside:
		return
	boss_area_player_inside = true
	if player.vacuum_unlocked or int(upgrades.get("vacuum", 0)) > 0:
		if boss_intro_vacuum_shown:
			return
		boss_intro_vacuum_shown = true
		hud.show_boss_acquisition_intro("¡Aspiradora, yo te elijo!")
		_save_game()
	elif boss_intro_cooldown <= 0.0:
		boss_intro_cooldown = 8.0
		boss_intro_no_vacuum_shown = true
		hud.show_boss_acquisition_intro("¡Para lidiar con tal basura, necesito una aspiradora!")
		_save_game()

func _on_pause_requested() -> void:
	if hud:
		hud.toggle_pause()

<<<<<<< Updated upstream
func _apply_options(brightness: float, music_volume: float, effects_volume: float, fov: float, quality_level: int = 1) -> void:
	graphics_quality = clampi(quality_level, 0, 2)
=======
func _apply_options(brightness: float, music_volume: float, effects_volume: float, fov: float) -> void:
	TRushProfiles.set_setting("brightness", brightness)
	TRushProfiles.set_setting("music_volume", music_volume)
	TRushProfiles.set_setting("effects_volume", effects_volume)
	TRushProfiles.set_setting("fov", fov)
	TRushProfiles.apply_runtime_settings(get_viewport())
>>>>>>> Stashed changes
	if world_environment and world_environment.environment:
		world_environment.environment.ambient_light_energy = 0.65 * brightness
		world_environment.environment.tonemap_exposure = brightness
	if sun:
		sun.shadow_enabled = graphics_quality >= 1
		sun.directional_shadow_max_distance = 42.0 if graphics_quality == 1 else 70.0
	for detail in get_tree().get_nodes_in_group("quality_detail"):
		if detail is Node3D:
			detail.visible = graphics_quality >= 1
	if player and player.game_camera:
		player.game_camera.fov = fov
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_linear(music_bus, music_volume)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_linear(sfx_bus, effects_volume)
	_save_game()

func _on_inventory_changed(current: int, capacity: int) -> void:
	if hud:
		hud.update_bag(current, capacity)

func _on_player_health_changed(current: float, maximum: float) -> void:
	if hud:
		hud.update_health(current, maximum)

func _on_trash_collected(_value: int) -> void:
	var collected_units := maxi(0, _value)
	collected_trash += collected_units
	if collected_item_was_boss_drop:
		collected_item_was_boss_drop = false
		_save_game()
	else:
		world_trash_collected += collected_units
		daily_collected_count = mini(daily_target, daily_collected_count + collected_units)
	_add_player_xp(2)
	if hud:
		hud.update_daily_cleanup(daily_target, daily_collected_count, daily_bonus_paid)
	_check_daily_completion()
	_check_restoration()
	_save_game()

func _check_daily_completion() -> void:
	if daily_bonus_paid or daily_collected_count < daily_target:
		return
	daily_bonus_paid = true
	daily_completed_days += 1
	var bonus_rate := clampf(float(progression_balance.get("daily_completion_bonus_rate", 0.10)), 0.0, 0.5)
	var bonus := maxi(0, int(floor(float(daily_ordinary_money_earned) * bonus_rate)))
	money += bonus
	if hud:
		hud.update_money(money)
		hud.update_daily_cleanup(daily_target, daily_collected_count, daily_bonus_paid)
		hud.show_message("¡Cuota diaria completa! Bono de limpieza +$%d (10%%)." % bonus)
	_save_game()

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
		return 0
	return mini(100, int(round(float(world_trash_collected) / float(total_trash) * 100.0)))

func _check_restoration() -> void:
	var percent := _restoration_percent()
	hud.update_progress(percent)
	var milestones := [
		{"percent": 25, "name": "Hornero", "id": "bird", "description": "Ave nativa que construye nidos de barro y ayuda a mantener el equilibrio del ecosistema.", "message": "¡Regresó el hornero al bosque!"},
		{"percent": 60, "name": "Zorro gris", "id": "fox", "description": "Mamífero omnívoro que dispersa semillas y contribuye al control de pequeños animales.", "message": "¡Se observó un zorro gris en el bioma!"},
		{"percent": 80, "name": "Venado de campo", "id": "deer", "description": "Herbívoro nativo de pastizales y ambientes abiertos; su presencia indica un hábitat más saludable.", "message": "¡El venado de campo volvió al ecosistema! Bioma restaurado."}
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
	if str(species["id"]) == "deer":
		actor.position = Vector3(-22.0 + randf_range(-3.0, 3.0), 0.0, -22.0 + randf_range(-3.0, 3.0))
		actor.scale = Vector3.ONE * 0.76
	else:
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
	if upgrade_id == "vacuum":
		var vacuum_costs: Array = progression_balance.get("vacuum_upgrade_costs", [])
		if level >= int(progression_balance.get("vacuum_max_level", 10)) or level >= vacuum_costs.size():
			return -1
		return maxi(1, int(round(float(vacuum_costs[level]) * pow(0.92, float(upgrades.get("discount", 0))))))
	if upgrade_id == "daily_quota":
		var quota_costs: Array = progression_balance.get("daily_quota_upgrade_costs", [])
		var max_level := mini(int(progression_balance.get("daily_quota_max_level", 6)), quota_costs.size())
		if level >= max_level:
			return -1
		return maxi(1, int(round(float(quota_costs[level]) * pow(0.92, float(upgrades.get("discount", 0))))))
	var base_cost := {"speed": 40, "capacity": 55, "value": 70, "range": 45, "day": 60, "vacuum": 240, "discount": 180}
	var discount_factor := pow(0.92, float(upgrades.get("discount", 0)))
	return maxi(1, int(round(float(base_cost.get(upgrade_id, 50)) * float(level + 1) * discount_factor)))

func _buy_upgrade(upgrade_id: String) -> void:
	if is_day:
		hud.show_message("Las mejoras solo se compran de noche.")
		return
	match upgrade_id:
		"cleaner_purchase":
			_buy_portable_cleaner()
			return
		"cleaner_income":
			_update_cleaner_income_upgrade()
			return
		"cleaner_storage":
			_update_cleaner_storage_upgrade()
			return
	if not upgrades.has(upgrade_id):
		return
	var cost := _upgrade_cost(upgrade_id)
	if cost < 0:
		hud.show_message("La aspiradora alcanzó el nivel máximo de 10." if upgrade_id == "vacuum" else "La cuota diaria alcanzó su máximo configurado.")
		return
	if money < cost:
		hud.show_message("Fondos insuficientes. Necesitas $%d." % cost)
		return
	money -= cost
	upgrades[upgrade_id] = int(upgrades[upgrade_id]) + 1
	if upgrade_id == "daily_quota":
		hud.show_message("Mejora adquirida: el siguiente día ofrecerá %d residuos." % _daily_target_for_level(int(upgrades["daily_quota"])))
	else:
		hud.show_message("Mejora adquirida: %s · -$%d" % [upgrade_id, cost])
	_apply_upgrades()
	hud.update_money(money)
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	_save_game()
	_update_cleaner_hud()

func _buy_portable_cleaner() -> void:
	if cleaner_owned:
		if hud:
			hud.show_message("Ya compraste la limpiadora; solo puedes instalar esa unidad.")
		return
	var price := maxi(1, int(cleaner_balance.get("purchase_price", 5200)))
	if money < price:
		if hud:
			hud.show_message("La limpiadora cuesta $%d. Te faltan $%d." % [price, price - money])
		return
	money -= price
	cleaner_owned = true
	cleaner_installed = false
	cleaner_operational = true
	cleaner_location_id = ""
	cleaner_install_position = Vector3.ZERO
	cleaner_income_level = 0
	cleaner_storage_level = 0
	cleaner_stored_money = 0
	cleaner_elapsed_seconds = 0.0
	_spawn_cleaner_in_hand()
	if hud:
		hud.update_money(money)
		hud.show_message("Limpiadora comprada · llévala al estanque o al Arroyo de la Rana.")
	_update_cleaner_hud()
	_save_game()

func _apply_upgrades() -> void:
	if player == null:
		return
	if int(upgrades.get("vacuum", 0)) > 0:
		player.unlock_vacuum()
	var vacuum_level := clampi(int(upgrades.get("vacuum", 0)), 0, int(progression_balance.get("vacuum_max_level", 10)))
	player.set_vacuum_level(vacuum_level)
	player.vacuum_radius = (3.2 + float(maxi(0, vacuum_level - 1)) * 0.85) + float(skill_levels.get("magnet", 0)) * 0.35
	player.vacuum_damage_multiplier = 1.0 + float(maxi(0, vacuum_level - 1)) * 0.35 + float(skill_levels.get("magnet", 0)) * 0.08
	player.vacuum_pull_time = maxf(0.08, 0.24 - float(maxi(0, vacuum_level - 1)) * 0.025)
	player.walk_speed = 5.0 + float(upgrades["speed"]) * 0.7
	player.sprint_speed = 8.0 + float(upgrades["speed"]) * 0.9
	if int(upgrades["capacity"]) > 0:
		var target_capacity := 5 + 2 * int(upgrades["capacity"])
		var capacity_increase := target_capacity - player.bag_capacity
		if capacity_increase > 0:
			player.increase_capacity(capacity_increase)
	player.interaction_range = 5.0 + float(upgrades["range"]) * 1.0

func _prestige_completed_boss_count() -> int:
	var completed := 0
	for configuration in boss_configurations:
		var boss_id := str(configuration.get("id", ""))
		if not defeated_boss_ids.has(boss_id):
			continue
		var encounter: Dictionary = boss_encounters.get(boss_id, {})
		if encounter.is_empty() or str(encounter.get("phase", "")) == "complete":
			completed += 1
	return completed

func _prestige_points_for_run() -> int:
	if _restoration_percent() < int(progression_balance.get("prestige_minimum_restoration", 98)):
		return 0
	var restoration_quartiles := int(floor(float(_restoration_percent()) / 25.0))
	var restoration_points := restoration_quartiles * maxi(0, int(progression_balance.get("prestige_points_per_restoration_quartile", 1)))
	var boss_points := _prestige_completed_boss_count() * maxi(0, int(progression_balance.get("prestige_points_per_boss_encounter", 1)))
	return clampi(restoration_points + boss_points, 1, maxi(1, int(progression_balance.get("prestige_points_max_per_reset", 12))))

func _request_prestige_confirmation() -> void:
	var required := int(progression_balance.get("prestige_minimum_restoration", 98))
	if _restoration_percent() < required:
		hud.show_message("Necesitas restaurar al menos el %d%% del bioma para prestigiar." % required)
		return
	prestige_confirmation_pending = true
	var preview_points := _prestige_points_for_run()
	hud.show_prestige_confirmation(preview_points, _restoration_percent(), _prestige_completed_boss_count())

func _perform_prestige() -> void:
	if not prestige_confirmation_pending:
		return
	prestige_confirmation_pending = false
	var required := int(progression_balance.get("prestige_minimum_restoration", 98))
	var restoration := _restoration_percent()
	var awarded_points := _prestige_points_for_run()
	if restoration < required or awarded_points <= 0:
		hud.show_message("El progreso ya no cumple el requisito para prestigiar.")
		return
	var defeated_major_bosses := _prestige_completed_boss_count()
	prestige_points += awarded_points
	prestige_count += 1
	prestige_history.append({"prestige": prestige_count, "points": awarded_points, "day": day_number, "restoration": restoration, "bosses": defeated_major_bosses})
	# Reset all run-scoped progression while keeping profile, settings, and permanent prestige data.
	money = 0
	for upgrade_id in upgrades:
		upgrades[upgrade_id] = 0
	collected_trash = 0
	world_trash_collected = 0
	daily_target = _daily_target_for_level(0)
	daily_collected_count = 0
	daily_ordinary_money_earned = 0
	daily_bonus_paid = false
	daily_completed_days = 0
	total_trash = daily_target
	skill_points = 0
	player_xp = 0
	player_level = 1
	for skill_id in skill_levels:
		skill_levels[skill_id] = 0
	combo_multiplier = 1.0
	last_deposit_time = -100.0
	species_unlocked.clear()
	unlocked_zones.clear()
	radar_unlocked = false
	radar_active = false
	day_number = 1
	day_time = 0.0
	is_day = true
	daily_fruit_remaining = 3
	boss_drops_generated_total = 0
	boss_drop_records.clear()
	queued_boss_drops.clear()
	boss_progress.clear()
	boss_encounters.clear()
	defeated_boss_ids.clear()
	current_daily_trash.clear()
	for boss in active_bosses:
		if is_instance_valid(boss):
			boss.queue_free()
	active_bosses.clear()
	for trash in get_tree().get_nodes_in_group("garbage"):
		trash.queue_free()
	for actor in get_tree().get_nodes_in_group("wildlife_actor"):
		if is_instance_valid(actor):
			actor.queue_free()
	if cleaner_preview and is_instance_valid(cleaner_preview):
		cleaner_preview.queue_free()
	if cleaner_machine and is_instance_valid(cleaner_machine):
		cleaner_machine.queue_free()
	cleaner_owned = false
	cleaner_installed = false
	cleaner_operational = true
	cleaner_location_id = ""
	cleaner_install_position = Vector3.ZERO
	cleaner_income_level = 0
	cleaner_storage_level = 0
	cleaner_stored_money = 0
	cleaner_elapsed_seconds = 0.0
	cleaner_machine = null
	cleaner_preview = null
	reserved_positions.clear()
	player.bag_count = 0
	player.bag_reward_total = 0
	player.current_health = player.maximum_health
	player.knocked_out = false
	player.vacuum_unlocked = false
	player.inventory_changed.emit(player.bag_count, player.bag_capacity)
	player.health_changed.emit(player.current_health, player.maximum_health)
	player.global_position = station.global_position + Vector3(0.0, 1.0, 6.5)
	player.rotation = Vector3.ZERO
	_apply_upgrades()
	await get_tree().create_timer(0.25).timeout
	_spawn_trash()
<<<<<<< Updated upstream
	money += 100 * prestige_count
	if player:
		player.heal(player.max_health)
	hud.update_progress(0)
	hud.update_money(money)
	hud.show_message("¡Prestigio %d! Mejoras conservadas y +$%d." % [prestige_count, 100 * prestige_count])
	_save_game()
=======
	_load_boss_configurations()
	_spawn_garbage_bosses()
	_refresh_bestiary()
	_update_hud()
	hud.update_upgrade_prices(_all_upgrade_costs(), upgrades)
	hud.update_daily_cleanup(daily_target, daily_collected_count, daily_bonus_paid)
	hud.update_skill_status(player_level, skill_points, skill_levels)
	hud.update_prestige_state(prestige_points, prestige_count, prestige_history)
	hud.set_upgrade_access(not is_day)
	hud.show_prestige_menu()
	hud.show_message("Prestigio %d: +%d puntos permanentes. La partida volvió a empezar." % [prestige_count, awarded_points])
	_save_game(true)
>>>>>>> Stashed changes

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
		player.vacuum_damage_multiplier += 0.08
	elif skill_id == "combo":
		combo_multiplier = minf(2.5, combo_multiplier + 0.1)
	hud.update_skill_status(player_level, skill_points, skill_levels)
	hud.show_message("Habilidad mejorada: %s" % skill_id)
	_save_game()

func _create_pond() -> void:
	var pond := Node3D.new()
	pond.name = "LilyPond"
	pond.position = Vector3(27.0, 0.0, -27.0)
	add_child(pond)
	var water := MeshInstance3D.new()
	water.name = "CircularWaterSurface"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(11.6, 11.6)
	water_mesh.subdivide_width = 48
	water_mesh.subdivide_depth = 48
	water.mesh = water_mesh
	water.position.y = 0.025
	var water_material := ShaderMaterial.new()
	water_material.shader = load("res://shaders/water_surface.gdshader") as Shader
	water_material.set_shader_parameter("water_radius_uv", 0.985)
	water.material_override = water_material
	pond.add_child(water)
	var shoreline := MeshInstance3D.new()
	shoreline.name = "SoftShorelineRim"
	var shoreline_mesh := TorusMesh.new()
	shoreline_mesh.inner_radius = 5.55
	shoreline_mesh.outer_radius = 6.08
	shoreline_mesh.rings = 64
	shoreline_mesh.ring_segments = 12
	shoreline.mesh = shoreline_mesh
	shoreline.position.y = 0.0
	var shore_material := StandardMaterial3D.new()
	shore_material.albedo_color = Color(0.32, 0.37, 0.22)
	shore_material.roughness = 0.98
	shoreline.material_override = shore_material
	pond.add_child(shoreline)
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
		lily.name = "WaterLily_%d" % lily_index
		var lily_mesh := SphereMesh.new()
		lily_mesh.radial_segments = 36
		lily_mesh.rings = 18
		lily_mesh.radius = 0.5
		lily_mesh.height = 0.11
		lily.mesh = lily_mesh
		lily.position = lily_positions[lily_index]
		lily.scale = Vector3(1.2, 0.65, 0.96)
		lily.rotation.y = rng.randf_range(0.0, TAU)
		var lily_material := StandardMaterial3D.new()
		lily_material.albedo_color = Color(0.20 + rng.randf_range(-0.025, 0.025), 0.43 + rng.randf_range(-0.035, 0.035), 0.22 + rng.randf_range(-0.025, 0.025))
		lily_material.roughness = 0.88
		lily.material_override = lily_material
		pond.add_child(lily)
		for vein_index in range(3):
			var vein := MeshInstance3D.new()
			var vein_mesh := CylinderMesh.new()
			vein_mesh.top_radius = 0.008
			vein_mesh.bottom_radius = 0.012
			vein_mesh.height = 0.34 + float(vein_index % 2) * 0.08
			vein_mesh.radial_segments = 8
			vein.mesh = vein_mesh
			vein.position = lily.position + Vector3(0.0, 0.055, 0.0)
			vein.rotation = Vector3(PI * 0.5, lily.rotation.y + float(vein_index) * TAU / 3.0, 0.0)
			vein.material_override = _detail_material(Color(0.35, 0.56, 0.27))
			pond.add_child(vein)
	var frog := Node3D.new()
	frog.name = "PondFrog"
	frog.set_script(POND_FROG_SCRIPT)
	frog.call("configure_lilies", lily_positions)
	pond.add_child(frog)

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

func _save_game(keep_previous: bool = false) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", TRushProfiles.SAVE_VERSION)
	config.set_value("meta", "profile_name", TRushProfiles.active_profile_name)
	config.set_value("meta", "active_slot", TRushProfiles.active_slot)
	config.set_value("meta", "saved_unix", int(Time.get_unix_time_from_system()))
	config.set_value("economy", "money", money)
	config.set_value("progress", "prestige", prestige_count)
	config.set_value("progress", "collected_trash", collected_trash)
	config.set_value("progress", "world_trash_collected", world_trash_collected)
	config.set_value("progress", "cleanup_percent", _restoration_percent())
	config.set_value("progress", "total_trash", total_trash)
	config.set_value("progress", "daily_target", daily_target)
	config.set_value("progress", "daily_collected_count", daily_collected_count)
	config.set_value("progress", "daily_ordinary_money_earned", daily_ordinary_money_earned)
	config.set_value("progress", "daily_bonus_paid", daily_bonus_paid)
	config.set_value("progress", "daily_completed_days", daily_completed_days)
	config.set_value("progress", "species_unlocked", species_unlocked)
	config.set_value("progress", "unlocked_zones", unlocked_zones)
	config.set_value("progress", "radar_unlocked", radar_unlocked)
	config.set_value("progress", "radar_active", radar_active)
	config.set_value("progress", "day_number", day_number)
	config.set_value("progress", "is_day", is_day)
	config.set_value("progress", "day_time", day_time)
	config.set_value("progress", "daily_fruit_remaining", daily_fruit_remaining)
	config.set_value("progress", "boss_drops_generated_total", boss_drops_generated_total)
	config.set_value("progress", "boss_drop_records", boss_drop_records)
	config.set_value("progress", "boss_progress", boss_progress)
	config.set_value("progress", "boss_encounters", boss_encounters)
	config.set_value("progress", "defeated_boss_ids", defeated_boss_ids)
	config.set_value("progress", "vacuum_owned", int(upgrades.get("vacuum", 0)) > 0 or (player != null and player.vacuum_unlocked))
	config.set_value("progress", "boss_intro_no_vacuum_shown", boss_intro_no_vacuum_shown)
	config.set_value("progress", "boss_intro_vacuum_shown", boss_intro_vacuum_shown)
	config.set_value("prestige", "points", prestige_points)
	config.set_value("prestige", "history", prestige_history)
	config.set_value("prestige", "permanent_upgrades", prestige_permanent_upgrades)
	config.set_value("cleaner", "owned", cleaner_owned)
	config.set_value("cleaner", "installed", cleaner_installed)
	config.set_value("cleaner", "location_id", cleaner_location_id)
	config.set_value("cleaner", "position", cleaner_install_position)
	config.set_value("cleaner", "operational", cleaner_operational)
	config.set_value("cleaner", "stored_money", cleaner_stored_money)
	config.set_value("cleaner", "income_level", cleaner_income_level)
	config.set_value("cleaner", "storage_level", cleaner_storage_level)
	config.set_value("cleaner", "elapsed_seconds", cleaner_elapsed_seconds)
	config.set_value("upgrades", "levels", upgrades)
	config.set_value("skills", "levels", skill_levels)
	config.set_value("skills", "points", skill_points)
	config.set_value("skills", "xp", player_xp)
	config.set_value("skills", "level", player_level)
<<<<<<< Updated upstream
	config.set_value("settings", "graphics_quality", graphics_quality)
	if player:
		config.set_value("player", "health", player.current_health)
	config.save(SAVE_PATH)
=======
	if player:
		config.set_value("player", "position", player.global_position)
		config.set_value("player", "yaw", player.rotation.y)
		config.set_value("player", "health", player.current_health)
		config.set_value("player", "bag_count", player.bag_count)
		config.set_value("player", "bag_reward_total", player.bag_reward_total)
	var error := _write_save_atomically(config, TRushProfiles.get_active_save_path(), keep_previous)
	if error != OK:
		push_warning("TRush: no se pudo guardar el perfil activo. Error %d." % error)
		return false
	return true

func _write_save_atomically(config: ConfigFile, save_path: String, keep_previous: bool) -> Error:
	var temporary_path := save_path + ".pending"
	var save_error := config.save(temporary_path)
	if save_error != OK:
		return save_error
	var target_absolute := ProjectSettings.globalize_path(save_path)
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var rollback_absolute := target_absolute + ".rollback"
	var has_old_save := FileAccess.file_exists(target_absolute)
	if has_old_save:
		if FileAccess.file_exists(rollback_absolute):
			DirAccess.remove_absolute(rollback_absolute)
		var move_old_error := DirAccess.rename_absolute(target_absolute, rollback_absolute)
		if move_old_error != OK:
			return move_old_error
	var commit_error := DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if commit_error != OK:
		if has_old_save and FileAccess.file_exists(rollback_absolute):
			DirAccess.rename_absolute(rollback_absolute, target_absolute)
		return commit_error
	if has_old_save and FileAccess.file_exists(rollback_absolute):
		if keep_previous:
			var backup_absolute := "%s.pre_prestige_%d_%d.bak" % [target_absolute, prestige_count, int(Time.get_unix_time_from_system())]
			var backup_error := DirAccess.copy_absolute(rollback_absolute, backup_absolute)
			if backup_error != OK:
				push_warning("TRush: el reinicio se guardó, pero no se pudo crear la copia previa al prestigio.")
		DirAccess.remove_absolute(rollback_absolute)
	return OK
>>>>>>> Stashed changes

func _load_game() -> void:
	var config := ConfigFile.new()
	var save_path := TRushProfiles.get_active_save_path()
	if not FileAccess.file_exists(save_path) and FileAccess.file_exists(save_path + ".rollback"):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".rollback"), ProjectSettings.globalize_path(save_path))
	if not FileAccess.file_exists(save_path):
		return
	var load_error := config.load(save_path)
	if load_error != OK:
		push_warning("TRush: el perfil no se pudo leer; se conservará el archivo intacto. Error %d." % load_error)
		return
	var save_version := int(config.get_value("meta", "save_version", 1))
	if save_version > TRushProfiles.SAVE_VERSION:
		push_warning("TRush: el perfil pertenece a una versión más reciente y no se cargará.")
		return
	money = maxi(0, int(config.get_value("economy", "money", 0)))
	prestige_count = maxi(0, int(config.get_value("progress", "prestige", 0)))
	prestige_points = maxi(0, int(config.get_value("prestige", "points", 0)))
	var saved_prestige_history: Variant = config.get_value("prestige", "history", [])
	prestige_history.clear()
	if saved_prestige_history is Array:
		for entry in saved_prestige_history:
			if entry is Dictionary:
				prestige_history.append(entry.duplicate(true))
	var saved_permanent_upgrades: Variant = config.get_value("prestige", "permanent_upgrades", {})
	prestige_permanent_upgrades = saved_permanent_upgrades.duplicate(true) if saved_permanent_upgrades is Dictionary else {}
	collected_trash = maxi(0, int(config.get_value("progress", "collected_trash", 0)))
	radar_unlocked = bool(config.get_value("progress", "radar_unlocked", false))
	radar_active = radar_unlocked and bool(config.get_value("progress", "radar_active", false))
	day_number = maxi(1, int(config.get_value("progress", "day_number", 1)))
	is_day = bool(config.get_value("progress", "is_day", true))
	day_time = maxf(0.0, float(config.get_value("progress", "day_time", 0.0)))
	daily_fruit_remaining = clampi(int(config.get_value("progress", "daily_fruit_remaining", 3)), 0, 3)
	boss_intro_no_vacuum_shown = bool(config.get_value("progress", "boss_intro_no_vacuum_shown", false))
	boss_intro_vacuum_shown = bool(config.get_value("progress", "boss_intro_vacuum_shown", false))
	cleaner_owned = bool(config.get_value("cleaner", "owned", false))
	cleaner_installed = cleaner_owned and bool(config.get_value("cleaner", "installed", false))
	cleaner_location_id = str(config.get_value("cleaner", "location_id", ""))
	var saved_cleaner_position: Variant = config.get_value("cleaner", "position", Vector3.ZERO)
	cleaner_install_position = saved_cleaner_position if saved_cleaner_position is Vector3 else Vector3.ZERO
	cleaner_operational = bool(config.get_value("cleaner", "operational", true))
	cleaner_stored_money = maxi(0, int(config.get_value("cleaner", "stored_money", 0)))
	cleaner_income_level = maxi(0, int(config.get_value("cleaner", "income_level", 0)))
	cleaner_storage_level = maxi(0, int(config.get_value("cleaner", "storage_level", 0)))
	cleaner_elapsed_seconds = clampf(float(config.get_value("cleaner", "elapsed_seconds", 0.0)), 0.0, 59.99)
	boss_drops_generated_total = maxi(0, int(config.get_value("progress", "boss_drops_generated_total", 0)))
	var saved_boss_records: Variant = config.get_value("progress", "boss_drop_records", [])
	boss_drop_records.clear()
	if saved_boss_records is Array:
		for record in saved_boss_records:
			if record is Dictionary:
				boss_drop_records.append(record)
	if config.has_section_key("progress", "world_trash_collected"):
		world_trash_collected = maxi(0, int(config.get_value("progress", "world_trash_collected", 0)))
	else:
		var previously_collected_boss_drops := maxi(0, boss_drops_generated_total - boss_drop_records.size())
		world_trash_collected = maxi(0, collected_trash - previously_collected_boss_drops)
	collected_item_was_boss_drop = false
	var saved_boss_progress: Variant = config.get_value("progress", "boss_progress", {})
	boss_progress = saved_boss_progress if saved_boss_progress is Dictionary else {}
	var saved_boss_encounters: Variant = config.get_value("progress", "boss_encounters", {})
	boss_encounters = saved_boss_encounters if saved_boss_encounters is Dictionary else {}
	saved_player_state = {
		"position": config.get_value("player", "position", Vector3(0.0, 1.0, 7.0)),
		"yaw": float(config.get_value("player", "yaw", 0.0)),
		"health": float(config.get_value("player", "health", 100.0)),
		"bag_count": int(config.get_value("player", "bag_count", 0)),
		"bag_reward_total": int(config.get_value("player", "bag_reward_total", 0))
	}
	var saved_defeated_bosses: Variant = config.get_value("progress", "defeated_boss_ids", [])
	defeated_boss_ids.clear()
	if saved_defeated_bosses is Array:
		for boss_id in saved_defeated_bosses:
			defeated_boss_ids.append(str(boss_id))
	next_boss_drop_id = 1
	for record in boss_drop_records:
		var record_id := str(record.get("id", ""))
		var suffix := record_id.get_slice("_", record_id.get_slice_count("_") - 1)
		next_boss_drop_id = maxi(next_boss_drop_id, suffix.to_int() + 1)
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
	var saved_upgrades: Variant = config.get_value("upgrades", "levels", upgrades)
	for key in upgrades:
		if saved_upgrades is Dictionary:
			upgrades[key] = clampi(int(saved_upgrades.get(key, 0)), 0, 20)
	upgrades["vacuum"] = clampi(int(upgrades.get("vacuum", 0)), 0, int(progression_balance.get("vacuum_max_level", 10)))
	upgrades["daily_quota"] = clampi(int(upgrades.get("daily_quota", 0)), 0, int(progression_balance.get("daily_quota_max_level", 6)))
	if bool(config.get_value("progress", "vacuum_owned", false)):
		upgrades["vacuum"] = maxi(1, int(upgrades.get("vacuum", 0)))
		upgrades["vacuum"] = mini(int(progression_balance.get("vacuum_max_level", 10)), int(upgrades["vacuum"]))
	daily_target = int(config.get_value("progress", "daily_target", _daily_target_for_level(int(upgrades.get("daily_quota", 0)))))
	daily_target = clampi(daily_target, _daily_target_for_level(0), _daily_target_for_level(int(progression_balance.get("daily_quota_max_level", 6))))
	daily_collected_count = clampi(int(config.get_value("progress", "daily_collected_count", world_trash_collected)), 0, daily_target)
	daily_ordinary_money_earned = maxi(0, int(config.get_value("progress", "daily_ordinary_money_earned", 0)))
	daily_bonus_paid = bool(config.get_value("progress", "daily_bonus_paid", false))
	daily_completed_days = maxi(0, int(config.get_value("progress", "daily_completed_days", 0)))
	total_trash = maxi(daily_target, int(config.get_value("progress", "total_trash", daily_target)))
	if save_version < 5:
		daily_target = _daily_target_for_level(int(upgrades.get("daily_quota", 0)))
		daily_collected_count = clampi(world_trash_collected, 0, daily_target)
		daily_ordinary_money_earned = 0
		daily_bonus_paid = false
		daily_completed_days = 0
		total_trash = daily_target
	var saved_skills: Variant = config.get_value("skills", "levels", skill_levels)
	for key in skill_levels:
<<<<<<< Updated upstream
		skill_levels[key] = int(saved_skills.get(key, 0))
	skill_points = int(config.get_value("skills", "points", 0))
	player_xp = int(config.get_value("skills", "xp", 0))
	player_level = int(config.get_value("skills", "level", 1))
	graphics_quality = clampi(int(config.get_value("settings", "graphics_quality", 1)), 0, 2)
	saved_player_health = float(config.get_value("player", "health", 100.0))
=======
		if saved_skills is Dictionary:
			skill_levels[key] = clampi(int(saved_skills.get(key, 0)), 0, 99)
	skill_points = maxi(0, int(config.get_value("skills", "points", 0)))
	player_xp = maxi(0, int(config.get_value("skills", "xp", 0)))
	player_level = maxi(1, int(config.get_value("skills", "level", 1)))
>>>>>>> Stashed changes
