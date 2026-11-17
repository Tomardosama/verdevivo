extends Node3D
class_name TRushWildlife

@export_enum("bird", "fox", "deer") var species_id: String = "bird"
@export var wander_radius: float = 3.0
@export var move_speed: float = 0.8

var origin: Vector3
var target: Vector3
var wander_timer: float = 0.0
var body: MeshInstance3D
var animation_clock: float = 0.0
var base_height: float = 0.0

func _ready() -> void:
	origin = global_position
	base_height = position.y
	_build_creature()
	_choose_target()

func _process(delta: float) -> void:
	animation_clock += delta
	wander_timer -= delta
	if wander_timer <= 0.0:
		_choose_target()
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		global_position += direction.normalized() * move_speed * delta
		var facing_target := Vector3(target.x, global_position.y, target.z)
		if global_position.distance_squared_to(facing_target) > 0.0004:
			look_at(facing_target, Vector3.UP)
	rotation.z = sin(animation_clock * 2.0) * 0.025
	if species_id == "bird":
		position.y = base_height + sin(animation_clock * 3.0) * 0.08


func _choose_target() -> void:
	wander_timer = randf_range(2.0, 5.0)
	target = origin + Vector3(randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius))

func _build_creature() -> void:
	match species_id:
		"bird":
			_build_bird()
		"fox":
			_build_fox()
		"deer":
			_build_deer()
		_:
			_build_bird()

func _part(parent: Node3D, mesh: Mesh, location: Vector3, color: Color, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if mesh is SphereMesh:
		var sphere := mesh as SphereMesh
		sphere.radial_segments = 32
		sphere.rings = 20
	node.mesh = mesh
	node.position = location
	node.scale = scale_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	node.material_override = material
	parent.add_child(node)
	return node

func _build_bird() -> void:
	var brown := Color(0.38, 0.24, 0.14)
	var cream := Color(0.78, 0.68, 0.48)
	_part(self, SphereMesh.new(), Vector3(0, 0.8, 0), brown, Vector3(0.34, 0.25, 0.48))
	_part(self, SphereMesh.new(), Vector3(0, 0.95, -0.32), brown, Vector3(0.2, 0.2, 0.2))
	_part(self, SphereMesh.new(), Vector3(-0.27, 0.84, 0), cream, Vector3(0.28, 0.08, 0.24))
	_part(self, SphereMesh.new(), Vector3(0.27, 0.84, 0), cream, Vector3(0.28, 0.08, 0.24))
	_part(self, BoxMesh.new(), Vector3(0, 0.72, 0.48), Color(0.8, 0.55, 0.12), Vector3(0.12, 0.08, 0.22))
	var eye_material := Color(0.04, 0.035, 0.025)
	for side in [-1.0, 1.0]:
		_part(self, SphereMesh.new(), Vector3(side * 0.13, 1.0, -0.48), eye_material, Vector3(0.045, 0.045, 0.035))
		_part(self, CylinderMesh.new(), Vector3(side * 0.1, 0.58, 0.02), Color(0.55, 0.38, 0.16), Vector3(0.025, 0.35, 0.025))

func _build_fox() -> void:
	var orange := Color(0.78, 0.32, 0.10)
	var white := Color(0.92, 0.84, 0.68)
	_part(self, SphereMesh.new(), Vector3(0, 0.62, 0), orange, Vector3(0.42, 0.34, 0.72))
	_part(self, SphereMesh.new(), Vector3(0, 0.54, 0.02), white, Vector3(0.25, 0.18, 0.48))
	for leg_side in [-1.0, 1.0]:
		for leg_z in [-0.34, 0.28]:
			_part(self, CylinderMesh.new(), Vector3(leg_side * 0.23, 0.27, leg_z), orange, Vector3(0.075, 0.62, 0.075))
	_part(self, SphereMesh.new(), Vector3(0, 0.78, -0.55), orange, Vector3(0.3, 0.3, 0.32))
	_part(self, SphereMesh.new(), Vector3(0, 0.63, 0.72), white, Vector3(0.2, 0.2, 0.55))
	for side in [-1.0, 1.0]:
		_part(self, CylinderMesh.new(), Vector3(side * 0.2, 0.32, -0.28), orange, Vector3(0.12, 0.55, 0.12))
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.0
		ear_mesh.bottom_radius = 0.5
		ear_mesh.height = 1.0
		_part(self, ear_mesh, Vector3(side * 0.17, 1.08, -0.58), orange, Vector3(0.55, 0.65, 0.35))
		_part(self, SphereMesh.new(), Vector3(side * 0.12, 0.83, -0.81), Color(0.025, 0.02, 0.015), Vector3(0.045, 0.045, 0.035))
		_part(self, SphereMesh.new(), Vector3(side * 0.18, 1.08, -0.59), Color(0.95, 0.68, 0.55), Vector3(0.07, 0.13, 0.045))
	var tail := SphereMesh.new()
	tail.radius = 0.28
	tail.height = 1.0
	_part(self, tail, Vector3(0.0, 0.58, 0.85), orange, Vector3(0.7, 0.7, 1.8))

func _build_deer() -> void:
	var coat_tan := Color(0.55, 0.36, 0.20)
	var dark := Color(0.25, 0.16, 0.1)
	_part(self, SphereMesh.new(), Vector3(0, 1.0, 0), coat_tan, Vector3(0.42, 0.48, 0.78))
	var cream := Color(0.86, 0.79, 0.66)
	_part(self, SphereMesh.new(), Vector3(0, 0.88, 0.12), cream, Vector3(0.28, 0.28, 0.58))
	_part(self, SphereMesh.new(), Vector3(0, 1.22, -0.84), cream, Vector3(0.14, 0.12, 0.18))
	for spot_index in range(7):
		_part(self, SphereMesh.new(), Vector3(randf_range(-0.3, 0.3), randf_range(1.05, 1.34), randf_range(-0.25, 0.3)), cream, Vector3(0.035, 0.025, 0.035))
	_part(self, SphereMesh.new(), Vector3(0, 1.35, -0.62), tan, Vector3(0.25, 0.32, 0.28))
	for side in [-1.0, 1.0]:
		_part(self, CylinderMesh.new(), Vector3(side * 0.2, 0.45, -0.32), dark, Vector3(0.08, 1.0, 0.08))
		_part(self, CylinderMesh.new(), Vector3(side * 0.2, 1.7, -0.62), dark, Vector3(0.035, 0.55, 0.035))
		_part(self, SphereMesh.new(), Vector3(side * 0.34, 1.95, -0.62), dark, Vector3(0.06, 0.22, 0.06))
		_part(self, CylinderMesh.new(), Vector3(side * 0.34, 1.88, -0.58), Color(0.38, 0.25, 0.14), Vector3(0.025, 0.34, 0.025))
		_part(self, SphereMesh.new(), Vector3(side * 0.10, 1.42, -0.84), Color(0.025, 0.02, 0.015), Vector3(0.04, 0.04, 0.04))
		_part(self, CylinderMesh.new(), Vector3(side * 0.18, 0.36, 0.05), dark, Vector3(0.07, 0.75, 0.07))
	var antler_material := Color(0.68, 0.56, 0.38)
	for side in [-1.0, 1.0]:
		var antler := CylinderMesh.new()
		antler.top_radius = 0.0
		antler.bottom_radius = 0.07
		antler.height = 0.72
		_part(self, antler, Vector3(side * 0.23, 1.82, -0.61), antler_material, Vector3(1.0, 1.0, 0.55))
