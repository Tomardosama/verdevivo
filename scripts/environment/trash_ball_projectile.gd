extends Node3D
class_name TRushTrashBall

@export var lifetime: float = 6.0
var flight_direction: Vector3 = Vector3.FORWARD
var flight_speed: float = 8.0
var hit_damage: float = 14.0
var projectile_color: Color = Color(0.39, 0.31, 0.20)
var projectile_clock: float = 0.0

func setup(start_position: Vector3, target_position: Vector3, speed: float, damage: float, color: Color) -> void:
	global_position = start_position
	flight_direction = (target_position - start_position).normalized()
	flight_speed = speed
	hit_damage = damage
	projectile_color = color

func _ready() -> void:
	_build_projectile()
	if flight_direction.length_squared() > 0.0:
		look_at(global_position + flight_direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	projectile_clock += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	rotate_z(delta * 5.5)
	var travel := flight_direction * flight_speed * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + travel)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var exclusions: Array[RID] = []
	for boss in get_tree().get_nodes_in_group("garbage_boss"):
		if boss is CollisionObject3D:
			exclusions.append(boss.get_rid())
	query.exclude = exclusions
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider := hit.get("collider") as Node
		if collider and collider.has_method("take_damage"):
			collider.call("take_damage", hit_damage)
		queue_free()
		return
	global_position += travel

func _build_projectile() -> void:
	var body := MeshInstance3D.new()
	body.name = "CompactedTrashBall"
	var ball_mesh := SphereMesh.new()
	ball_mesh.radial_segments = 24
	ball_mesh.rings = 16
	ball_mesh.radius = 0.28
	ball_mesh.height = 0.52
	body.mesh = ball_mesh
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = projectile_color
	ball_material.roughness = 0.86
	body.material_override = ball_material
	add_child(body)
	for shard_index in range(4):
		var shard := MeshInstance3D.new()
		var scrap := PrismMesh.new()
		scrap.size = Vector3(0.18, 0.10, 0.16)
		shard.mesh = scrap
		var angle := TAU * float(shard_index) / 4.0
		shard.position = Vector3(cos(angle) * 0.22, sin(angle * 1.7) * 0.15, sin(angle) * 0.22)
		shard.rotation = Vector3(angle * 0.7, angle, angle * 0.35)
		var shard_material := StandardMaterial3D.new()
		shard_material.albedo_color = projectile_color.lightened(0.16 if shard_index % 2 == 0 else 0.04)
		shard_material.roughness = 0.9
		shard.material_override = shard_material
		add_child(shard)
