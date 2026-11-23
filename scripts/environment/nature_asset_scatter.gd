extends Node3D
class_name TRushNatureAssetScatter

const ASSET_ROOT := "res://assets/environment/quaternius_nature/"
const ASSETS := {
	"birch_2": "BirchTree_2.gltf",
	"birch_4": "BirchTree_4.gltf",
	"maple_1": "MapleTree_1.gltf",
	"maple_3": "MapleTree_3.gltf",
	"dead_2": "DeadTree_2.gltf",
	"bush": "Bush.gltf",
	"flower_bush": "Bush_Flowers.gltf",
	"grass": "Grass_Small.gltf"
}
const REGION_CENTERS := {
	"forest": Vector3(-67.0, 0.0, -68.0),
	"waste": Vector3(66.0, 0.0, -65.0),
	"rocky": Vector3(-70.0, 0.0, 66.0),
	"water": Vector3(70.0, 0.0, 68.0)
}

var asset_cache: Dictionary = {}
var instance_batches: Dictionary = {}
var accepted_tree_positions: Array[Vector3] = []
var tree_collision_body: StaticBody3D

func populate(blocked_positions: Array[Vector3] = []) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 602781
	tree_collision_body = StaticBody3D.new()
	tree_collision_body.name = "InstancedTreeTrunkCollisions"
	tree_collision_body.collision_layer = 1
	tree_collision_body.collision_mask = 0
	add_child(tree_collision_body)
	_scatter_tree_region("forest", 26, ["birch_2", "birch_4", "maple_1", "maple_3"], 18.0, 30.0, blocked_positions, rng)
	_scatter_tree_region("waste", 10, ["dead_2"], 23.0, 35.0, blocked_positions, rng)
	_scatter_tree_region("rocky", 12, ["birch_2", "dead_2"], 22.0, 34.0, blocked_positions, rng)
	_scatter_tree_region("water", 10, ["maple_1", "birch_4"], 13.0, 20.0, blocked_positions, rng)
	_scatter_ground_region("forest", "bush", 18, 13.0, 27.0, rng)
	_scatter_ground_region("forest", "flower_bush", 7, 18.0, 29.0, rng)
	_scatter_ground_region("waste", "bush", 9, 23.0, 31.0, rng)
	_scatter_ground_region("rocky", "bush", 11, 15.0, 28.0, rng)
	_scatter_ground_region("water", "flower_bush", 10, 11.0, 16.0, rng)
	_scatter_ground_region("forest", "grass", 56, 9.0, 29.0, rng)
	_scatter_ground_region("rocky", "grass", 28, 10.0, 25.0, rng)
	_flush_batches()

func _scatter_tree_region(region_id: String, count: int, variants: Array[String], minimum_radius: float, maximum_radius: float, blocked_positions: Array[Vector3], rng: RandomNumberGenerator) -> void:
	var center: Vector3 = REGION_CENTERS[region_id]
	for index in range(count):
		var placed := false
		for attempt in range(180):
			var angle := rng.randf_range(0.0, TAU)
			var radius := sqrt(rng.randf_range(minimum_radius * minimum_radius, maximum_radius * maximum_radius))
			var location := center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			if absf(location.x) > 112.0 or absf(location.z) > 112.0 or Vector2(location.x, location.z).length() < 13.0:
				continue
			if _near_any(location, blocked_positions, 4.0) or _near_any(location, accepted_tree_positions, 4.6):
				continue
			if _near_trail(location, region_id):
				continue
			var variant := variants[rng.randi_range(0, variants.size() - 1)]
			var scale_value := rng.randf_range(0.78, 1.32)
			var yaw := rng.randf_range(0.0, TAU)
			var tint := Color(rng.randf_range(0.84, 1.0), rng.randf_range(0.86, 1.0), rng.randf_range(0.80, 0.98), 1.0)
			_add_instance(variant, region_id, location, scale_value, yaw, tint, 145.0)
			accepted_tree_positions.append(location)
			if accepted_tree_positions.size() <= 48:
				_add_tree_collision(location, scale_value)
			placed = true
			break
		if not placed:
			push_warning("TRush: no se encontró un espacio libre para un árbol de %s." % region_id)

func _scatter_ground_region(region_id: String, asset_id: String, count: int, minimum_radius: float, maximum_radius: float, rng: RandomNumberGenerator) -> void:
	var center: Vector3 = REGION_CENTERS[region_id]
	for index in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf_range(minimum_radius * minimum_radius, maximum_radius * maximum_radius))
		var location := center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if absf(location.x) > 112.0 or absf(location.z) > 112.0:
			continue
		var local_clearance := 1.25 if asset_id == "grass" else 2.1
		if _near_any(location, accepted_tree_positions, local_clearance):
			continue
		if asset_id != "grass" and _near_trail(location, region_id):
			continue
		var scale_value := rng.randf_range(0.72, 1.28) if asset_id != "grass" else rng.randf_range(0.68, 1.4)
		var tint := Color(rng.randf_range(0.84, 1.0), rng.randf_range(0.88, 1.0), rng.randf_range(0.80, 0.97), 1.0)
		_add_instance(asset_id, region_id, location, scale_value, rng.randf_range(0.0, TAU), tint, 54.0 if asset_id == "grass" else 82.0)

func _add_instance(asset_id: String, region_id: String, world_position: Vector3, scale_value: float, yaw: float, tint: Color, view_distance: float) -> void:
	var batch_key := asset_id + "|" + region_id
	if not instance_batches.has(batch_key):
		instance_batches[batch_key] = {"transforms": [], "colors": [], "distance": view_distance}
	var center: Vector3 = REGION_CENTERS[region_id]
	var record: Dictionary = instance_batches[batch_key]
	var mesh_info: Dictionary = _asset_info(asset_id)
	var source_transform: Transform3D = mesh_info.get("transform", Transform3D.IDENTITY)
	var local_position := world_position - center + source_transform.origin * scale_value
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value) * source_transform.basis
	var transforms: Array = record["transforms"]
	var colors: Array = record["colors"]
	transforms.append(Transform3D(basis, local_position))
	colors.append(tint)

func _asset_info(asset_id: String) -> Dictionary:
	if asset_cache.has(asset_id):
		return asset_cache[asset_id]
	var scene_path := ASSET_ROOT + str(ASSETS.get(asset_id, ""))
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("TRush: no se pudo cargar el modelo ambiental %s." % scene_path)
		asset_cache[asset_id] = {}
		return {}
	var instance := packed_scene.instantiate()
	var mesh_node := _find_mesh_instance(instance)
	if mesh_node == null or mesh_node.mesh == null:
		push_warning("TRush: el modelo %s no contiene una malla compatible." % scene_path)
		instance.free()
		asset_cache[asset_id] = {}
		return {}
	var surface_material: Material = mesh_node.get_surface_override_material(0)
	if surface_material == null:
		surface_material = mesh_node.mesh.surface_get_material(0)
	var material_copy: StandardMaterial3D
	if surface_material is StandardMaterial3D:
		material_copy = (surface_material as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		material_copy = StandardMaterial3D.new()
		material_copy.albedo_color = Color(0.35, 0.45, 0.30)
	material_copy.vertex_color_use_as_albedo = true
	var result := {"mesh": mesh_node.mesh, "material": material_copy, "transform": mesh_node.transform}
	instance.free()
	asset_cache[asset_id] = result
	return result

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found
	return null

func _flush_batches() -> void:
	for batch_key in instance_batches:
		var split_key := str(batch_key).split("|")
		var asset_id := str(split_key[0])
		var region_id := str(split_key[1])
		var info: Dictionary = _asset_info(asset_id)
		if info.is_empty():
			continue
		var records: Dictionary = instance_batches[batch_key]
		var transforms: Array = records["transforms"]
		if transforms.is_empty():
			continue
		var multi_mesh := MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.use_colors = true
		multi_mesh.mesh = info["mesh"]
		multi_mesh.instance_count = transforms.size()
		var colors: Array = records["colors"]
		for index in range(transforms.size()):
			multi_mesh.set_instance_transform(index, transforms[index])
			multi_mesh.set_instance_color(index, colors[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "%s_%s_Instances" % [asset_id.capitalize(), region_id.capitalize()]
		instance.multimesh = multi_mesh
		instance.position = REGION_CENTERS[region_id]
		instance.visibility_range_end = float(records["distance"])
		var base_material: StandardMaterial3D = info["material"]
		instance.material_override = base_material
		var radius := 38.0 if asset_id in ["birch_2", "birch_4", "maple_1", "maple_3", "dead_2"] else 32.0
		multi_mesh.custom_aabb = AABB(Vector3(-radius, -2.0, -radius), Vector3(radius * 2.0, 32.0, radius * 2.0))
		add_child(instance)

func _add_tree_collision(location: Vector3, tree_scale: float) -> void:
	var collision := CollisionShape3D.new()
	var trunk := CapsuleShape3D.new()
	trunk.radius = 0.36
	trunk.height = 4.4
	collision.shape = trunk
	collision.position = location + Vector3.UP * (2.2 * tree_scale)
	collision.scale = Vector3.ONE * tree_scale
	tree_collision_body.add_child(collision)

func _near_any(point: Vector3, positions: Array[Vector3], clearance: float) -> bool:
	for existing in positions:
		if Vector2(point.x, point.z).distance_to(Vector2(existing.x, existing.z)) < clearance:
			return true
	return false

func _near_trail(point: Vector3, region_id: String) -> bool:
	var trail_points: Array[Vector3] = [Vector3.ZERO]
	match region_id:
		"forest": trail_points.append_array([Vector3(-18, 0, -25), Vector3(-42, 0, -47), Vector3(-67, 0, -68)])
		"waste": trail_points.append_array([Vector3(24, 0, -24), Vector3(47, 0, -48), Vector3(69, 0, -67)])
		"rocky": trail_points.append_array([Vector3(-20, 0, 25), Vector3(-44, 0, 48), Vector3(-69, 0, 68)])
		"water": trail_points.append_array([Vector3(25, 0, 23), Vector3(48, 0, 48), Vector3(70, 0, 68)])
	for index in range(trail_points.size() - 1):
		if _distance_to_segment(point, trail_points[index], trail_points[index + 1]) < 4.6:
			return true
	return false

func _distance_to_segment(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var segment := finish - start
	if segment.length_squared() < 0.001:
		return point.distance_to(start)
	var amount := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * amount)
