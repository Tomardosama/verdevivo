extends Node

const GAME_SCENE := preload("res://scenes/main/main.tscn")
const TEST_PROFILE_DIRECTORY := "res://.godot/trush_test_profiles"

var failures: Array[String] = []
var main_game: Node3D

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var profiles := get_tree().root.get_node_or_null("TRushProfiles") as TRushProfileManager
	if profiles == null:
		_fail("Profile manager autoload is available")
		_finish()
		return
	profiles.profile_storage_prefix = TEST_PROFILE_DIRECTORY
	var test_path := ProjectSettings.globalize_path(TEST_PROFILE_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(test_path)
	for slot_id in range(1, 4):
		var old_test_file := ProjectSettings.globalize_path(profiles.slot_path(slot_id))
		if FileAccess.file_exists(profiles.slot_path(slot_id)):
			DirAccess.remove_absolute(old_test_file)
	_expect(profiles.create_profile(1, "Roble", false), "create isolated profile 1")
	_expect(profiles.create_profile(2, "Arroyo", false), "create isolated profile 2")
	_write_slot_money(profiles.slot_path(1), 111)
	_write_slot_money(profiles.slot_path(2), 222)
	var summaries := profiles.get_slot_summaries()
	_expect(int(summaries[0]["money"]) == 111 and int(summaries[1]["money"]) == 222, "save slots keep separate progress")
	_expect(not profiles.create_profile(1, "Reemplazo", false), "occupied slot requires confirmation")
	_expect(not profiles.delete_profile(2, false) and FileAccess.file_exists(profiles.slot_path(2)), "profile deletion is blocked without confirmation")
	_expect(profiles.delete_profile(2, true) and not FileAccess.file_exists(profiles.slot_path(2)), "confirmed profile deletion affects only its slot")
	_expect(profiles.create_profile(2, "Arroyo", false), "deleted slot can be initialized again")
	_expect(profiles.activate_slot(1) and profiles.active_profile_name == "Roble", "profile name and load selection persist")

	main_game = GAME_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main_game)
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect(main_game.player != null and main_game.hud != null and main_game.hud.minimap != null, "gameplay HUD and minimap load")
	_expect(main_game.money == 111, "game loads only the selected profile")
	var world_pickups_before: int = main_game.world_trash_collected
	var simulated_boss_drop := TrashPickup.new()
	simulated_boss_drop.set_meta("boss_drop", true)
	simulated_boss_drop.set_meta("boss_drop_id", "smoke-test-drop")
	main_game.call("_on_trash_item_collected", simulated_boss_drop)
	main_game.call("_on_trash_collected", 1)
	_expect(main_game.world_trash_collected == world_pickups_before, "collected boss drops do not consume saved world pickup positions")
	var simulated_world_pickup := TrashPickup.new()
	main_game.call("_on_trash_item_collected", simulated_world_pickup)
	main_game.call("_on_trash_collected", 1)
	_expect(main_game.world_trash_collected == world_pickups_before + 1, "ordinary pickups advance the saved world collection cursor")
	for actor in get_tree().get_nodes_in_group("garbage_boss"):
		actor.set_physics_process(false)
		actor.set_process(false)

	main_game.money = 1000
	main_game.player.global_position = main_game.roots_lookout.global_position + Vector3(0.0, 1.0, 0.0)
	main_game.call("_try_roots_radar_interaction")
	_expect(main_game.radar_unlocked and main_game.money == 0, "radar costs $1000 exactly once")
	main_game.call("_try_roots_radar_interaction")
	_expect(main_game.radar_active and main_game.money == 0, "unlocked radar toggles without charging again")
	main_game.call("_update_minimap")
	var ordinary_count := 0
	for item in get_tree().get_nodes_in_group("garbage"):
		if item is TrashPickup and not item.is_queued_for_deletion():
			ordinary_count += 1
	_expect(main_game.hud.minimap.radar_active and main_game.hud.minimap.garbage_positions.size() == ordinary_count, "radar markers come from actual collectible waste")
	_expect(main_game.hud.minimap.boss_positions.size() >= 3, "bosses have separate map markers")
	var first_pickup := get_tree().get_first_node_in_group("garbage")
	if first_pickup:
		first_pickup.queue_free()
		main_game.call("_update_minimap")
		_expect(main_game.hud.minimap.garbage_positions.size() == ordinary_count - 1, "collected waste disappears from radar markers")

	var hill_collisions := 0
	for node in get_tree().get_nodes_in_group("decorative_mountain"):
		if node is StaticBody3D:
			hill_collisions += 1
	_expect(hill_collisions == 0, "decorative mountain meshes have no blocking collision")
	var stream := main_game.find_child("StreamToShallows", true, false) as MeshInstance3D
	_expect(stream != null and stream.mesh != null and stream.mesh.get_aabb().size.x < 70.0 and stream.mesh.get_aabb().size.z < 60.0, "river water uses a bounded continuous ribbon mesh")
	_expect(load("res://shaders/bag_fill.gdshader") is Shader and load("res://assets/ui/bag_silhouette.svg") is Texture2D, "bag fill shader and original silhouette load")
	main_game.upgrades["capacity"] = 2
	main_game.call("_apply_upgrades")
	var bag_capacity: int = int(main_game.player.bag_capacity)
	var bag_half := int(floor(float(bag_capacity) * 0.5))
	main_game.hud.update_bag(bag_half, bag_capacity)
	_expect(main_game.hud.bag_count_label.text == "%d / %d" % [bag_half, bag_capacity], "bag HUD displays the actual upgraded capacity")
	await get_tree().create_timer(0.28).timeout
	_expect(is_equal_approx(float(main_game.hud.bag_fill_material.get_shader_parameter("fill_ratio")), float(bag_half) / float(bag_capacity)), "bag silhouette fill reaches the inventory percentage")
	var sign_direction_tests := [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3(1.0, 0.0, 1.0).normalized()]
	var readable_signs := true
	for direction in sign_direction_tests:
		var sign_yaw: float = TRushPlayerFacingSign.readable_front_yaw(direction)
		var front_vector := Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, sign_yaw)
		if front_vector.dot(direction) < 0.999:
			readable_signs = false
	_expect(readable_signs, "area signs point their readable front toward the player from four angles")
	var shop_sign := main_game.shop_node.find_child("ShopSign", true, false) as Label3D
	_expect(shop_sign != null and shop_sign.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "shop sign keeps its readable camera-facing billboard")

	main_game.is_day = false
	main_game.hud.set_upgrade_access(true)
	main_game.money = int(main_game.cleaner_balance.get("purchase_price", 5200))
	var cleaner_price: int = main_game.money
	main_game.call("_buy_upgrade", "cleaner_purchase")
	var carried_machine: Node3D = main_game.get("cleaner_machine") as Node3D
	_expect(main_game.cleaner_owned and main_game.money == 0 and carried_machine != null and carried_machine.get_parent() == main_game.player.cleaner_carry_mount, "cleaner purchase deducts its balance price and attaches the model to the player")
	main_game.money = cleaner_price
	main_game.call("_buy_upgrade", "cleaner_purchase")
	_expect(main_game.money == cleaner_price and main_game.cleaner_machine == carried_machine, "owned cleaner cannot be purchased or spawned twice")
	main_game.money = 0
	var invalid_cleaner_zone: Dictionary = main_game.call("_cleaner_placement_for_player", Vector3(0.0, 1.0, 0.0))
	var pond_cleaner_zone: Dictionary = main_game.call("_cleaner_placement_for_player", Vector3(70.0, 1.0, 76.5))
	var frog_cleaner_zone: Dictionary = main_game.call("_cleaner_placement_for_player", Vector3(91.0, 1.0, 91.0))
	_expect(not bool(invalid_cleaner_zone.get("valid", false)), "cleaner placement is rejected outside designated water zones")
	_expect(bool(pond_cleaner_zone.get("valid", false)) and str(pond_cleaner_zone.get("location", "")) == "circular_stream", "cleaner placement is accepted at the circular pond")
	_expect(bool(frog_cleaner_zone.get("valid", false)) and str(frog_cleaner_zone.get("location", "")) == "frog_stream", "cleaner placement is accepted along Frog Stream")
	main_game.player.global_position = Vector3(0.0, 1.0, 0.0)
	main_game.call("_update_cleaner_context")
	main_game.call("_on_cleaner_interaction_requested")
	_expect(not main_game.cleaner_installed and carried_machine.get_parent() == main_game.player.cleaner_carry_mount, "pressing E in an invalid zone keeps the cleaner carried")
	main_game.player.global_position = Vector3(70.0, 1.0, 76.5)
	main_game.call("_update_cleaner_context")
	main_game.call("_on_cleaner_interaction_requested")
	_expect(main_game.cleaner_installed and main_game.cleaner_location_id == "circular_stream" and carried_machine.get_parent() == main_game, "pressing E installs the same physical cleaner at a valid pond position")
	_expect(carried_machine.get("install_tween") != null, "installation plays the cleaner placement animation")
	main_game.call("_on_cleaner_interaction_requested")
	_expect(main_game.hud.cleaner_panel.visible, "E opens the installed cleaner management panel nearby")
	main_game.call("_on_cleaner_interaction_requested")
	_expect(not main_game.hud.cleaner_panel.visible, "E closes the cleaner panel without overlapping other gameplay")
	main_game.call("_toggle_cleaner_operation")
	_expect(not main_game.cleaner_operational and not bool(carried_machine.get("operational")), "installed machine can be switched off from its management controls")
	main_game.call("_toggle_cleaner_operation")
	_expect(main_game.cleaner_operational and bool(carried_machine.get("operational")), "installed machine can be restarted")
	main_game.cleaner_stored_money = 50
	var storage_cost: int = int(main_game.call("_cleaner_upgrade_cost", "storage_upgrade_costs", main_game.cleaner_storage_level))
	main_game.money = storage_cost
	main_game.call("_update_cleaner_storage_upgrade")
	_expect(main_game.money == 0 and main_game.cleaner_storage_level == 1 and main_game.cleaner_stored_money == 50 and main_game._cleaner_capacity() == 360, "storage upgrade charges correctly and preserves stored earnings")
	_expect(main_game.hud.cleaner_income_button.disabled and main_game.hud.cleaner_storage_button.disabled, "cleaner upgrade buttons disable when the wallet is insufficient")
	var income_cost: int = int(main_game.call("_cleaner_upgrade_cost", "income_upgrade_costs", main_game.cleaner_income_level))
	main_game.money = income_cost
	main_game.call("_update_cleaner_income_upgrade")
	_expect(main_game.money == 0 and main_game.cleaner_income_level == 1 and main_game._cleaner_income_rate() == 2, "income upgrade charges correctly and increases the configured rate")
	var cleaner_capacity: int = int(main_game.call("_cleaner_capacity"))
	main_game.cleaner_stored_money = cleaner_capacity - 1
	main_game.cleaner_elapsed_seconds = 59.0
	main_game.call("_update_cleaner_income", 1.0)
	_expect(main_game.cleaner_stored_money == cleaner_capacity, "passive earnings accumulate internally and clamp at storage capacity")
	main_game.call("_update_cleaner_income", 60.0)
	_expect(main_game.cleaner_stored_money == cleaner_capacity and main_game.cleaner_elapsed_seconds == 0.0, "full cleaner storage stops passive income")
	var wallet_before_collection: int = main_game.money
	main_game.call("_collect_cleaner_earnings")
	var wallet_after_collection: int = main_game.money
	main_game.call("_collect_cleaner_earnings")
	_expect(wallet_after_collection == wallet_before_collection + cleaner_capacity and main_game.money == wallet_after_collection and main_game.cleaner_stored_money == 0, "machine earnings transfer once to the wallet and then clear")
	main_game.cleaner_stored_money = 42
	main_game.cleaner_elapsed_seconds = 17.0
	main_game.money = 5000
	main_game._update_cleaner_hud()
	_expect(main_game.hud.cleaner_income_button.disabled == false and main_game.hud.cleaner_storage_button.disabled == false, "installed cleaner unlocks independently affordable shop upgrades")
	main_game.call("_save_game")

	var plastic_boss: TRushGarbageMountainBoss
	var mixed_boss: TRushGarbageMountainBoss
	for actor in get_tree().get_nodes_in_group("garbage_boss"):
		if actor is TRushGarbageMountainBoss:
			if actor.boss_id == "plastic_mountain":
				plastic_boss = actor
			elif actor.boss_id == "mixed_mountain":
				mixed_boss = actor
	if plastic_boss:
		main_game.upgrades["vacuum"] = 0
		main_game.player.vacuum_unlocked = false
		main_game.boss_intro_vacuum_shown = false
		main_game.boss_intro_no_vacuum_shown = false
		main_game.boss_intro_tracking_initialized = true
		main_game.boss_area_player_inside = false
		main_game.player.global_position = Vector3(-100.0, 1.0, -100.0)
		main_game.call("_update_boss_area_introduction", 0.0)
		main_game.player.global_position = plastic_boss.global_position + Vector3(0.0, 1.0, 29.0)
		main_game.call("_update_boss_area_introduction", 0.0)
		_expect(main_game.hud.boss_acquisition_label.text == "¡Para lidiar con tal basura, necesito una aspiradora!" and main_game.boss_intro_no_vacuum_shown and not main_game.boss_intro_vacuum_shown, "boss area explains vacuum requirement without completing the acquisition intro")
		main_game.upgrades["vacuum"] = 1
		main_game.player.unlock_vacuum()
		main_game.call("_update_boss_area_introduction", 0.0)
		_expect(not main_game.boss_intro_vacuum_shown, "acquiring the vacuum while inside waits for a genuine area re-entry")
		main_game.player.global_position = Vector3(-100.0, 1.0, -100.0)
		main_game.call("_update_boss_area_introduction", 0.0)
		main_game.player.global_position = plastic_boss.global_position + Vector3(0.0, 1.0, 29.0)
		main_game.call("_update_boss_area_introduction", 0.0)
		main_game.call("_update_boss_area_introduction", 0.0)
		_expect(main_game.boss_intro_vacuum_shown and main_game.hud.boss_acquisition_label.text == "¡Aspiradora, yo te elijo!", "vacuum purchase and boss area re-entry display the one-time acquisition message")
	if plastic_boss:
		var health_before_dodge: float = main_game.player.current_health
		main_game.player.global_position = plastic_boss.global_position + Vector3(20.0, 1.0, 0.0)
		plastic_boss.call("_begin_seismic_attack", Vector3(0.0, 0.0, -1.0))
		_expect(plastic_boss.telegraph_visual.visible and plastic_boss.telegraph_visual.mesh != null, "boss displays its telegraphed cone")
		plastic_boss.call("_advance_seismic_attack", plastic_boss.telegraph_duration + 0.02)
		for _step in range(100):
			plastic_boss.call("_advance_seismic_attack", 0.04)
		_expect(is_equal_approx(main_game.player.current_health, health_before_dodge), "player outside the cone takes no seismic damage")
		main_game.player.global_position = plastic_boss.global_position + Vector3(0.0, 1.0, -8.0)
		var health_before_hit: float = main_game.player.current_health
		plastic_boss.call("_begin_seismic_attack", Vector3(0.0, 0.0, -1.0))
		plastic_boss.call("_advance_seismic_attack", plastic_boss.telegraph_duration + 0.02)
		for _step in range(100):
			if main_game.player.current_health < health_before_hit:
				break
			plastic_boss.call("_advance_seismic_attack", 0.04)
		_expect(main_game.player.current_health < health_before_hit, "shockwave damages once when it crosses the warned cone")

	if mixed_boss:
		var money_before_split: int = main_game.money
		mixed_boss.apply_vacuum_damage(mixed_boss.maximum_health + 1.0)
		var encounter: Dictionary = main_game.boss_encounters.get("mixed_mountain", {})
		var children: Array[TRushGarbageMountainBoss] = []
		for actor in get_tree().get_nodes_in_group("garbage_boss"):
			if actor is TRushGarbageMountainBoss and actor.split_parent_id == "mixed_mountain":
				children.append(actor)
		_expect(str(encounter.get("phase", "")) == "minis" and children.size() == 2, "Colossus defeat creates two independent mini-bosses")
		_expect(main_game.money == money_before_split, "parent completion reward waits for both mini-bosses")
		if children.size() == 2:
			_expect(children[0].boss_id != children[1].boss_id and children[0].global_position.distance_to(children[1].global_position) > 8.0, "mini-bosses have separate IDs and safe spacing")
			for child in children:
				child.set_physics_process(false)
				child.set_process(false)
			main_game.call("_save_game")
			main_game.free()
			main_game = GAME_SCENE.instantiate() as Node3D
			get_tree().root.add_child(main_game)
			await get_tree().process_frame
			_expect(main_game.world_trash_collected == world_pickups_before + 1, "world collection cursor survives profile reload")
			_expect(main_game.money == 5000, "reloading the machine bank does not deposit its stored money twice")
			_expect(main_game.cleaner_owned and main_game.cleaner_installed and main_game.cleaner_location_id == "circular_stream" and main_game.cleaner_install_position.distance_to(Vector3(70.0, 0.11, 74.4)) < 0.2, "installed cleaner position and location restore from the active save slot")
			_expect(main_game.cleaner_stored_money == 42 and absf(main_game.cleaner_elapsed_seconds - 17.0) < 0.1 and main_game.cleaner_income_level == 1 and main_game.cleaner_storage_level == 1 and main_game.cleaner_operational, "machine bank, sub-minute timer, levels and operational state persist")
			_expect(get_tree().get_nodes_in_group("portable_cleaner").size() == 1, "loading a save restores one cleaner without duplicating the machine")
			_expect(main_game.boss_intro_no_vacuum_shown and main_game.boss_intro_vacuum_shown and int(main_game.upgrades.get("vacuum", 0)) == 1, "vacuum ownership and both boss introduction states persist")
			var restored_minis := 0
			for actor in get_tree().get_nodes_in_group("garbage_boss"):
				if actor is TRushGarbageMountainBoss and actor.split_parent_id == "mixed_mountain":
					restored_minis += 1
					actor.set_physics_process(false)
					actor.set_process(false)
			_expect(restored_minis == 2, "loading a split encounter restores two minis without duplicates")
		children.clear()
		for actor in get_tree().get_nodes_in_group("garbage_boss"):
			if actor is TRushGarbageMountainBoss and actor.split_parent_id == "mixed_mountain":
				children.append(actor)
		if children.size() == 2:
			var one_reward := children[0].defeat_reward
			children[0].apply_vacuum_damage(children[0].maximum_health + 1.0)
			var money_after_one: int = main_game.money
			main_game.call("_on_boss_defeated", children[0].boss_id, one_reward)
			_expect(main_game.money == money_after_one, "mini-boss rewards cannot be triggered twice")
			var progress_after_one: Dictionary = main_game.boss_encounters["mixed_mountain"]
			var remaining_after_one: Array = progress_after_one.get("remaining_ids", [])
			_expect(remaining_after_one.size() == 1, "split encounter records unfinished mini-boss progress")

	main_game.player.bag_count = 2
	main_game.player.take_damage(main_game.player.current_health)
	_expect(main_game.player.knocked_out, "zero health starts the knockout flow")
	await get_tree().create_timer(5.15).timeout
	_expect(not main_game.player.knocked_out and main_game.player.current_health == main_game.player.maximum_health, "player revives after five seconds with full health")
	_expect(main_game.player.bag_count == 2, "respawn preserves bag contents")
	_expect(main_game.hud.player_health_bar.value == main_game.player.maximum_health, "always-visible health bar updates on respawn")
	
	main_game.queue_free()
	await get_tree().process_frame
	profiles.profile_storage_prefix = "user://"
	profiles.active_slot = 0
	profiles.active_profile_name = ""
	for slot_id in range(1, 4):
		var test_file := ProjectSettings.globalize_path(TEST_PROFILE_DIRECTORY.path_join("trush_profile_%d.cfg" % slot_id))
		if FileAccess.file_exists(TEST_PROFILE_DIRECTORY.path_join("trush_profile_%d.cfg" % slot_id)):
			DirAccess.remove_absolute(test_file)
	DirAccess.remove_absolute(test_path)
	_finish()

func _write_slot_money(path: String, amount: int) -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		config.set_value("economy", "money", amount)
		config.save(path)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS · " + label)
	else:
		_fail(label)

func _fail(label: String) -> void:
	failures.append(label)
	push_error("FAIL · " + label)

func _finish() -> void:
	if failures.is_empty():
		print("RESULT · all major-update smoke checks passed")
		get_tree().quit(0)
	else:
		push_error("RESULT · %d smoke checks failed: %s" % [failures.size(), ", ".join(failures)])
		get_tree().quit(1)
