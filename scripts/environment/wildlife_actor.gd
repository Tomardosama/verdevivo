extends Node3D
class_name TRushWildlife

@export_enum("bird", "fox", "deer") var species_id: String = "bird"
@export var wander_radius: float = 3.0
@export_range(0.2, 4.0, 0.05) var move_speed: float = 1.1

var origin: Vector3
var target: Vector3
var wander_timer: float = 0.0
var body: Node3D
var tail_pivot: Node3D
var resting_at_night: bool = false
var home_body_position: Vector3 = Vector3.ZERO
var home_body_rotation: Vector3 = Vector3.ZERO
var animation_clock: float = 0.0
var base_height: float = 0.0
var gait_limbs: Array[MeshInstance3D] = []
var gait_home_rotations: Array[Vector3] = []
var gait_phases: Array[float] = []
var wing_pivots: Array[Node3D] = []
var wing_home_rotations: Array[Vector3] = []

func _ready() -> void:
	add_to_group("wildlife")
	origin = global_position
	base_height = position.y
	move_speed *= _species_speed_scale()
	_build_creature()
	if body:
		home_body_position = body.position
		home_body_rotation = body.rotation
	_choose_target()

func _process(delta: float) -> void:
	animation_clock += delta
	wander_timer -= delta
	if resting_at_night:
		if body:
			body.position = body.position.lerp(home_body_position + Vector3(0.0, -0.16, 0.0), delta * 2.0)
			body.rotation.z = lerpf(body.rotation.z, -0.14, delta * 2.0)
		_animate_legs(delta, false)
		return
	if wander_timer <= 0.0:
		_choose_target()
	var direction := target - global_position
	direction.y = 0.0
	var moving := direction.length_squared() > 0.025
	if moving:
		var distance := direction.length()
		global_position += direction.normalized() * minf(move_speed * delta, distance)
		var facing_target := global_position + direction.normalized()
		look_at(facing_target, Vector3.UP)
	rotation.z = sin(animation_clock * 1.8) * 0.018
	if body:
		var bob := absf(sin(animation_clock * 8.0)) * 0.035 if moving else 0.0
		if species_id == "bird":
			bob = sin(animation_clock * (5.2 if moving else 2.5)) * (0.085 if moving else 0.055)
		body.position.y = lerpf(body.position.y, home_body_position.y + bob, delta * 8.0)
		body.rotation.z = lerpf(body.rotation.z, home_body_rotation.z + (0.035 if moving else 0.0), delta * 7.0)
	_animate_legs(delta, moving)
	_animate_wings(delta)
	if tail_pivot:
		var tail_sway := sin(animation_clock * (7.0 if moving else 2.1)) * (0.19 if moving else 0.07)
		tail_pivot.rotation.x = lerpf(tail_pivot.rotation.x, tail_sway, delta * 5.0)
	if species_id == "bird":
		position.y = base_height + sin(animation_clock * 2.2) * 0.07

func set_night_resting(resting: bool) -> void:
	resting_at_night = resting
	if not resting:
		if body:
			body.position = home_body_position
			body.rotation = home_body_rotation
		_choose_target()
	else:
		wander_timer = 9999.0

func _species_speed_scale() -> float:
	match species_id:
		"bird": return 1.25
		"fox": return 1.12
		"deer": return 0.98
	return 1.0

func _choose_target() -> void:
	wander_timer = randf_range(2.2, 4.2)
	target = origin + Vector3(randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius))

func _build_creature() -> void:
	body = Node3D.new()
	body.name = "OrganicBodyRig"
	add_child(body)
	match species_id:
		"bird":
			_build_bird()
		"fox":
			_build_fox()
		"deer":
			_build_deer()
		_:
			_build_bird()

func _part(parent: Node3D, mesh: Mesh, location: Vector3, color: Color, scale_value: Vector3 = Vector3.ONE, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if mesh is CylinderMesh:
		(mesh as CylinderMesh).radial_segments = 28
	if mesh is SphereMesh:
		var sphere := mesh as SphereMesh
		sphere.radial_segments = 64
		sphere.rings = 40
	if mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radial_segments = 28
		(mesh as CapsuleMesh).rings = 12
	node.mesh = mesh
	node.position = location
	node.scale = scale_value
	node.rotation = rotation_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.91
	material.metallic = 0.0
	node.material_override = material
	parent.add_child(node)
	return node

func _sphere(radius_value: float, height_value: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = height_value
	return mesh

func _capsule(radius_value: float, height_value: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius_value
	mesh.height = height_value
	return mesh

func _cone(radius_value: float, height_value: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	return mesh

func _register_limb(limb: MeshInstance3D, phase: float) -> void:
	gait_limbs.append(limb)
	gait_home_rotations.append(limb.rotation)
	gait_phases.append(phase)

func _animate_legs(delta: float, moving: bool) -> void:
	for index in range(gait_limbs.size()):
		var limb := gait_limbs[index]
		if not is_instance_valid(limb):
			continue
		var home := gait_home_rotations[index]
		var stride := 0.0
		if moving:
			var gait_speed := 8.0 if species_id == "bird" else 9.5
			stride = sin(animation_clock * gait_speed + gait_phases[index]) * 0.27
		limb.rotation.x = lerpf(limb.rotation.x, home.x + stride, delta * 12.0)

func _animate_wings(delta: float) -> void:
	for index in range(wing_pivots.size()):
		var wing := wing_pivots[index]
		if not is_instance_valid(wing):
			continue
		var home := wing_home_rotations[index]
		var side := -1.0 if index == 0 else 1.0
		var flap := sin(animation_clock * 8.0) * 0.2 * side
		wing.rotation.z = lerpf(wing.rotation.z, home.z + flap, delta * 10.0)

func _build_bird() -> void:
	var brown := Color(0.36, 0.23, 0.14)
	var warm_brown := Color(0.51, 0.34, 0.21)
	var cream := Color(0.83, 0.73, 0.55)
	var dark := Color(0.045, 0.035, 0.026)
	_part(body, _sphere(0.48, 0.84), Vector3(0.0, 0.77, 0.0), brown, Vector3(0.82, 0.68, 1.0))
	_part(body, _sphere(0.34, 0.63), Vector3(0.0, 0.72, -0.07), cream, Vector3(0.82, 0.62, 0.92))
	_part(body, _sphere(0.24, 0.37), Vector3(0.0, 1.03, -0.37), warm_brown, Vector3(0.9, 0.88, 0.88))
	_part(body, _sphere(0.20, 0.32), Vector3(0.0, 0.57, 0.48), warm_brown, Vector3(0.68, 0.58, 1.55), Vector3(0.18, 0.0, 0.0))
	var beak := _part(body, _cone(0.15, 0.32), Vector3(0.0, 0.98, -0.66), Color(0.76, 0.49, 0.16), Vector3(0.78, 0.8, 0.86), Vector3(-PI * 0.5, 0.0, 0.0))
	beak.name = "ClayBeak"
	for side in [-1.0, 1.0]:
		var eye_ring := Color(0.72, 0.56, 0.35)
		_part(body, _sphere(0.075, 0.085), Vector3(side * 0.17, 1.08, -0.53), eye_ring, Vector3(1.0, 1.0, 0.65))
		_part(body, _sphere(0.043, 0.05), Vector3(side * 0.17, 1.08, -0.575), dark, Vector3(1.0, 1.0, 0.6))
		var wing_pivot := Node3D.new()
		wing_pivot.position = Vector3(side * 0.28, 0.82, 0.03)
		wing_pivot.rotation.z = side * -0.12
		body.add_child(wing_pivot)
		wing_pivots.append(wing_pivot)
		wing_home_rotations.append(wing_pivot.rotation)
		_part(wing_pivot, _sphere(0.25, 0.56), Vector3(side * 0.12, 0.0, 0.05), warm_brown, Vector3(0.55, 0.3, 1.55), Vector3(side * 0.12, 0.0, 0.0))
		for feather_index in range(3):
			_part(wing_pivot, _sphere(0.105, 0.32), Vector3(side * (0.11 + float(feather_index) * 0.035), -0.035, 0.25 + float(feather_index) * 0.12), brown, Vector3(0.58, 0.42, 1.35), Vector3(side * 0.1, 0.0, 0.0))
	for tail_index in range(3):
		_part(body, _sphere(0.11, 0.52), Vector3((float(tail_index) - 1.0) * 0.12, 0.59, 0.7), brown, Vector3(0.7, 0.62, 1.45), Vector3((float(tail_index) - 1.0) * 0.16, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		var leg := _part(body, _capsule(0.04, 0.32), Vector3(side * 0.11, 0.38, 0.13), Color(0.49, 0.34, 0.18), Vector3(0.72, 1.0, 0.72))
		_register_limb(leg, 0.0 if side < 0.0 else PI)
		_part(body, _sphere(0.06, 0.075), Vector3(side * 0.11, 0.2, 0.08), Color(0.47, 0.31, 0.16), Vector3(1.0, 0.55, 1.25))

func _build_fox() -> void:
	var orange := Color(0.72, 0.29, 0.095)
	var rust := Color(0.52, 0.19, 0.075)
	var cream := Color(0.91, 0.82, 0.66)
	var dark := Color(0.055, 0.043, 0.034)
	_part(body, _sphere(0.51, 1.05), Vector3(0.0, 0.7, 0.0), orange, Vector3(0.78, 0.74, 1.0), Vector3(0.05, 0.0, 0.0))
	_part(body, _sphere(0.31, 0.72), Vector3(0.0, 0.78, -0.39), orange, Vector3(0.78, 0.78, 0.82), Vector3(-0.28, 0.0, 0.0))
	_part(body, _sphere(0.35, 0.84), Vector3(0.0, 0.48, 0.06), cream, Vector3(0.8, 0.5, 1.0))
	_part(body, _sphere(0.31, 0.48), Vector3(0.0, 0.99, -0.64), rust, Vector3(0.95, 0.94, 0.9))
	_part(body, _sphere(0.19, 0.34), Vector3(0.0, 0.83, -0.88), cream, Vector3(0.82, 0.68, 1.35), Vector3(-0.18, 0.0, 0.0))
	_part(body, _sphere(0.072, 0.09), Vector3(0.0, 0.81, -1.06), dark, Vector3(1.0, 0.88, 0.65))
	for side in [-1.0, 1.0]:
		_part(body, _sphere(0.065, 0.08), Vector3(side * 0.22, 1.02, -0.81), Color(0.77, 0.57, 0.29), Vector3(1.0, 0.95, 0.72))
		_part(body, _sphere(0.037, 0.05), Vector3(side * 0.23, 1.02, -0.855), dark, Vector3(1.0, 0.92, 0.7))
		_part(body, _cone(0.17, 0.58), Vector3(side * 0.19, 1.32, -0.59), orange, Vector3(0.78, 1.0, 0.6), Vector3(side * -0.12, 0.0, 0.0))
		_part(body, _cone(0.075, 0.34), Vector3(side * 0.19, 1.31, -0.63), Color(0.91, 0.57, 0.42), Vector3(0.65, 1.0, 0.5), Vector3(side * -0.12, 0.0, 0.0))
	for index in range(4):
		var side := -1.0 if index < 2 else 1.0
		var fore := index % 2 == 0
		var leg_z := -0.33 if fore else 0.34
		var leg := _part(body, _capsule(0.105, 0.48), Vector3(side * 0.25, 0.31, leg_z), orange if fore else rust, Vector3(0.82, 1.0, 0.82), Vector3(0.0, 0.0, side * 0.04))
		_register_limb(leg, 0.0 if index % 2 == 0 else PI)
		_part(body, _sphere(0.12, 0.17), Vector3(side * 0.25, 0.08, leg_z - 0.015), dark, Vector3(0.9, 0.58, 1.1))
	tail_pivot = Node3D.new()
	tail_pivot.position = Vector3(0.0, 0.67, 0.48)
	body.add_child(tail_pivot)
	_part(tail_pivot, _sphere(0.29, 1.1), Vector3(0.0, -0.02, 0.32), orange, Vector3(0.76, 0.7, 1.28), Vector3(0.18, 0.0, 0.0))
	_part(tail_pivot, _sphere(0.22, 0.76), Vector3(0.0, 0.0, 0.67), cream, Vector3(0.76, 0.72, 1.06), Vector3(0.18, 0.0, 0.0))

func _build_deer() -> void:
	var coat := Color(0.52, 0.35, 0.20)
	var dark := Color(0.22, 0.14, 0.085)
	var cream := Color(0.88, 0.79, 0.65)
	var antler_color := Color(0.67, 0.54, 0.36)
	_part(body, _sphere(0.57, 1.15), Vector3(0.0, 0.98, 0.03), coat, Vector3(0.8, 0.78, 1.0))
	_part(body, _sphere(0.36, 0.82), Vector3(0.0, 0.84, 0.22), cream, Vector3(0.76, 0.46, 1.05))
	_part(body, _sphere(0.29, 0.93), Vector3(0.0, 1.34, -0.44), coat, Vector3(0.72, 1.08, 0.76), Vector3(-0.28, 0.0, 0.0))
	_part(body, _sphere(0.25, 0.43), Vector3(0.0, 1.7, -0.69), coat, Vector3(0.9, 0.9, 0.95))
	_part(body, _sphere(0.15, 0.25), Vector3(0.0, 1.59, -0.89), cream, Vector3(0.82, 0.75, 1.15))
	_part(body, _sphere(0.063, 0.075), Vector3(0.0, 1.58, -1.025), dark, Vector3(1.0, 0.9, 0.7))
	for spot_index in range(12):
		var z := -0.25 + float(spot_index % 4) * 0.18
		var side := -1.0 if spot_index < 6 else 1.0
		var row := float(spot_index % 3)
		_part(body, _sphere(0.035, 0.045), Vector3(side * (0.28 + row * 0.025), 1.12 + row * 0.12, z), cream, Vector3(1.0, 0.75, 0.7))
	for side in [-1.0, 1.0]:
		_part(body, _sphere(0.095, 0.15), Vector3(side * 0.31, 1.78, -0.67), coat, Vector3(0.78, 0.55, 1.45), Vector3(side * 0.18, 0.0, 0.0))
		_part(body, _sphere(0.05, 0.07), Vector3(side * 0.19, 1.75, -0.84), Color(0.71, 0.52, 0.28), Vector3(1.0, 1.0, 0.7))
		_part(body, _sphere(0.032, 0.045), Vector3(side * 0.195, 1.75, -0.88), dark, Vector3(1.0, 1.0, 0.7))
		_part(body, _cone(0.07, 0.27), Vector3(side * 0.13, 1.99, -0.68), antler_color, Vector3(0.8, 1.0, 0.8), Vector3(0.0, 0.0, side * -0.14))
		_part(body, _cone(0.052, 0.45), Vector3(side * 0.23, 2.27, -0.68), antler_color, Vector3(0.78, 1.0, 0.75), Vector3(0.0, 0.0, side * -0.44))
		_part(body, _cone(0.04, 0.31), Vector3(side * 0.39, 2.43, -0.68), antler_color, Vector3(0.75, 1.0, 0.75), Vector3(0.0, 0.0, side * 0.36))
		_part(body, _cone(0.035, 0.25), Vector3(side * 0.20, 2.46, -0.68), antler_color, Vector3(0.75, 1.0, 0.75), Vector3(0.0, 0.0, side * -0.08))
	for index in range(4):
		var side := -1.0 if index < 2 else 1.0
		var fore := index % 2 == 0
		var leg_z := -0.33 if fore else 0.36
		var leg := _part(body, _capsule(0.075, 0.77), Vector3(side * 0.24, 0.48, leg_z), dark if not fore else coat, Vector3(0.78, 1.0, 0.78), Vector3(side * 0.02, 0.0, side * 0.035))
		_register_limb(leg, 0.0 if index % 2 == 0 else PI)
		_part(body, _sphere(0.095, 0.11), Vector3(side * 0.24, 0.075, leg_z - 0.02), dark, Vector3(0.9, 0.65, 0.95))
