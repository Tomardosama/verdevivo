extends Node3D
class_name TRushPondFrog

@export_range(1.0, 8.0, 0.1) var hop_wait_min: float = 2.7
@export_range(1.0, 10.0, 0.1) var hop_wait_max: float = 4.6
@export_range(0.5, 2.0, 0.05) var hop_height: float = 1.1

var lily_positions: Array[Vector3] = []
var current_lily_index: int = 0
var hop_wait: float = 2.0
var idle_clock: float = 0.0
var hopping: bool = false
var frog_visual: Node3D

func configure_lilies(positions: Array[Vector3]) -> void:
	lily_positions = positions.duplicate()

func _ready() -> void:
	if lily_positions.is_empty():
		set_process(false)
		return
	_build_frog()
	position = lily_positions[0]
	hop_wait = randf_range(hop_wait_min, hop_wait_max)

func _process(delta: float) -> void:
	idle_clock += delta
	if frog_visual and not hopping:
		frog_visual.position.y = sin(idle_clock * 2.3) * 0.018
		hop_wait -= delta
		if hop_wait <= 0.0 and lily_positions.size() > 1:
			_hop_to_another_lily()

func _hop_to_another_lily() -> void:
	var choices: Array[int] = []
	for index in range(lily_positions.size()):
		if index != current_lily_index:
			choices.append(index)
	if choices.is_empty():
		hop_wait = randf_range(hop_wait_min, hop_wait_max)
		return
	var next_index := choices[randi_range(0, choices.size() - 1)]
	var start := position
	var destination := lily_positions[next_index]
	var apex := start.lerp(destination, 0.5) + Vector3.UP * hop_height
	hopping = true
	var jump := create_tween()
	jump.tween_property(self, "position", apex, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	jump.parallel().tween_property(frog_visual, "scale", Vector3(1.08, 0.86, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jump.chain().tween_property(self, "position", destination, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	jump.parallel().tween_property(frog_visual, "scale", Vector3.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jump.chain().tween_callback(_finish_hop.bind(next_index))

func _finish_hop(next_index: int) -> void:
	current_lily_index = next_index
	hopping = false
	hop_wait = randf_range(hop_wait_min, hop_wait_max)

func _build_frog() -> void:
	frog_visual = Node3D.new()
	frog_visual.name = "TreeFrogVisual"
	add_child(frog_visual)
	var skin := _material(Color(0.26, 0.53, 0.22), 0.76)
	var belly := _material(Color(0.72, 0.78, 0.43), 0.88)
	var eye_gold := _material(Color(0.91, 0.71, 0.22), 0.34)
	var pupil := _material(Color(0.035, 0.029, 0.021), 0.26)
	var toes := _material(Color(0.4, 0.65, 0.28), 0.74)
	_add_ellipsoid("Body", Vector3(0.0, 0.2, 0.06), Vector3(0.25, 0.17, 0.34), skin)
	_add_ellipsoid("Belly", Vector3(0.0, 0.13, -0.01), Vector3(0.2, 0.07, 0.25), belly)
	_add_ellipsoid("Head", Vector3(0.0, 0.28, -0.2), Vector3(0.22, 0.18, 0.23), skin)
	for side in [-1.0, 1.0]:
		_add_ellipsoid("EyeBrow", Vector3(side * 0.13, 0.39, -0.22), Vector3(0.095, 0.105, 0.10), skin)
		_add_ellipsoid("GoldenEye", Vector3(side * 0.14, 0.405, -0.255), Vector3(0.067, 0.072, 0.068), eye_gold)
		_add_ellipsoid("Pupil", Vector3(side * 0.14, 0.405, -0.31), Vector3(0.031, 0.04, 0.027), pupil)
		_add_ellipsoid("Nostril", Vector3(side * 0.055, 0.285, -0.407), Vector3(0.018, 0.014, 0.012), pupil)
		var rear_thigh := _add_ellipsoid("RearThigh", Vector3(side * 0.2, 0.13, 0.28), Vector3(0.12, 0.105, 0.18), skin)
		rear_thigh.rotation.x = 0.34
		_add_ellipsoid("HindFoot", Vector3(side * 0.27, 0.09, 0.34), Vector3(0.13, 0.05, 0.085), toes)
		_add_ellipsoid("FrontLeg", Vector3(side * 0.13, 0.105, -0.05), Vector3(0.055, 0.1, 0.065), skin)
		for toe_index in range(3):
			_add_ellipsoid("Toe", Vector3(side * (0.24 + float(toe_index % 2) * 0.035), 0.08, -0.08 + float(toe_index) * 0.07), Vector3(0.045, 0.035, 0.04), toes)

func _add_ellipsoid(part_name: String, location: Vector3, scale_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 32
	mesh.rings = 20
	mesh.radius = 0.5
	mesh.height = 1.0
	part.mesh = mesh
	part.position = location
	part.scale = scale_value * 2.0
	part.material_override = material
	frog_visual.add_child(part)
	return part

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
