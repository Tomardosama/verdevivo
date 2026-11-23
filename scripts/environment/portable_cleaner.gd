extends Node3D
class_name TRushPortableCleaner

var is_preview: bool = false
var preview_valid: bool = false
var installed: bool = false
var operational: bool = false
var rotor: MeshInstance3D
var status_lamp: MeshInstance3D
var preview_parts: Array[MeshInstance3D] = []
var preview_material: StandardMaterial3D
var install_tween: Tween
var operation_clock: float = 0.0

func _ready() -> void:
	add_to_group("portable_cleaner")
	_build_model()
	set_process(false)

func set_preview_mode(valid: bool) -> void:
	if is_preview and preview_valid == valid:
		return
	is_preview = true
	preview_valid = valid
	installed = false
	operational = false
	if preview_material == null:
		preview_material = StandardMaterial3D.new()
		preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		preview_material.emission_enabled = true
		preview_material.emission_energy_multiplier = 0.35
	preview_material.albedo_color = Color(0.20, 0.94, 0.44, 0.47) if valid else Color(1.0, 0.16, 0.12, 0.48)
	preview_material.emission = Color(0.11, 0.85, 0.28) if valid else Color(0.95, 0.07, 0.035)
	_apply_material_recursive(self, preview_material)
	set_process(false)

func set_operational_state(is_installed: bool, is_operational: bool) -> void:
	installed = is_installed
	operational = is_installed and is_operational
	set_process(operational)
	if status_lamp and not is_preview:
		var lamp_material := status_lamp.material_override as StandardMaterial3D
		if lamp_material:
			lamp_material.albedo_color = Color(0.22, 0.93, 0.52) if operational else Color(0.92, 0.51, 0.13)
			lamp_material.emission = lamp_material.albedo_color

func play_installation_feedback() -> void:
	if install_tween and install_tween.is_running():
		install_tween.kill()
	scale = Vector3(0.78, 0.78, 0.78)
	position.y += 0.28
	rotation.y -= 0.24
	install_tween = create_tween()
	install_tween.set_parallel(true)
	install_tween.tween_property(self, "scale", Vector3.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	install_tween.tween_property(self, "position:y", position.y - 0.28, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	install_tween.tween_property(self, "rotation:y", rotation.y + 0.24, 0.38).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	operation_clock += delta
	if rotor:
		rotor.rotate_object_local(Vector3.RIGHT, delta * 3.6)
	if status_lamp:
		var lamp_material := status_lamp.material_override as StandardMaterial3D
		if lamp_material:
			lamp_material.emission_energy_multiplier = 1.2 + 0.45 * sin(operation_clock * 3.0)

func _build_model() -> void:
	var painted := _material(Color(0.105, 0.38, 0.31), 0.44, 0.22)
	var dark := _material(Color(0.075, 0.105, 0.09), 0.78, 0.0)
	var metal := _material(Color(0.58, 0.66, 0.59), 0.32, 0.72)
	var hose := _material(Color(0.12, 0.17, 0.14), 0.62, 0.08)
	var glass := _material(Color(0.22, 0.55, 0.63, 0.82), 0.22, 0.34)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_add_box("Chassis", Vector3(0.94, 0.12, 0.70), Vector3(0.0, 0.16, 0.0), dark)
	_add_box("MainHousing", Vector3(0.78, 0.55, 0.58), Vector3(0.0, 0.51, 0.04), painted)
	_add_box("UpperFilter", Vector3(0.49, 0.35, 0.36), Vector3(0.0, 0.92, 0.06), metal)
	_add_box("FilterWindow", Vector3(0.31, 0.23, 0.035), Vector3(0.0, 0.91, -0.145), glass)
	_add_box("Nameplate", Vector3(0.34, 0.11, 0.035), Vector3(0.0, 0.61, -0.265), dark)
	_add_tube("FrontIntake", 0.23, 0.30, 0.10, Vector3(0.0, 0.38, -0.39), 0.0, metal)
	_add_tube("IntakeHose", 0.065, 0.105, 0.48, Vector3(0.0, 0.59, -0.54), PI * 0.48, hose)
	_add_tube("OutletPipe", 0.045, 0.065, 0.48, Vector3(0.0, 0.51, 0.43), PI * 0.5, metal)
	_add_box("OutletLip", Vector3(0.23, 0.06, 0.12), Vector3(0.0, 0.52, 0.65), painted)
	rotor = _add_tube("RotatingFilterDrum", 0.14, 0.18, 0.39, Vector3(0.0, 0.94, 0.08), PI * 0.5, metal)
	rotor.rotation.z = PI * 0.5
	for wheel_x in [-0.49, 0.49]:
		for wheel_z in [-0.23, 0.29]:
			_add_tube("RubberWheel", 0.075, 0.11, 0.10, Vector3(wheel_x, 0.19, wheel_z), PI * 0.5, dark)
	for vent_index in range(3):
		_add_box("Vent", Vector3(0.46, 0.025, 0.045), Vector3(0.0, 0.57 + float(vent_index) * 0.08, 0.337), dark)
	var lamp_material := _material(Color(0.22, 0.93, 0.52), 0.24, 0.0)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(0.22, 0.93, 0.52)
	lamp_material.emission_energy_multiplier = 1.5
	status_lamp = _add_sphere("StatusLamp", Vector3(0.29, 0.81, -0.278), 0.055, lamp_material)
	for foot_x in [-0.31, 0.31]:
		for foot_z in [-0.22, 0.25]:
			_add_box("RubberFoot", Vector3(0.15, 0.07, 0.14), Vector3(foot_x, 0.08, foot_z), hose)
	set_operational_state(installed, operational)

func _add_box(part_name: String, dimensions: Vector3, location: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = location
	part.material_override = material
	add_child(part)
	preview_parts.append(part)
	return part

func _add_tube(part_name: String, top_radius: float, bottom_radius: float, height: float, location: Vector3, tilt_x: float, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 20
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	part.mesh = mesh
	part.position = location
	part.rotation.x = tilt_x
	part.material_override = material
	add_child(part)
	preview_parts.append(part)
	return part

func _add_sphere(part_name: String, location: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.radius = radius
	mesh.height = radius * 2.0
	part.mesh = mesh
	part.position = location
	part.material_override = material
	add_child(part)
	preview_parts.append(part)
	return part

func _material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func _apply_material_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_recursive(child, material)
