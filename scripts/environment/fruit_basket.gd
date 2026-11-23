extends Node3D
class_name TRushFruitBasket

@export_range(1, 6, 1) var fruits_per_day: int = 3
var fruits_remaining: int = 3
var fruit_nodes: Array[Node3D] = []
var basket_label: Label3D

func _ready() -> void:
	add_to_group("daily_fruit_basket")
	_build_basket()
	_refresh_fruit_display()

func set_fruits_remaining(amount: int) -> void:
	fruits_remaining = clampi(amount, 0, fruits_per_day)
	if basket_label:
		_refresh_fruit_display()

func consume_fruit() -> bool:
	if fruits_remaining <= 0:
		return false
	fruits_remaining -= 1
	_refresh_fruit_display()
	return true

func refill_for_new_day() -> void:
	fruits_remaining = fruits_per_day
	_refresh_fruit_display()

func _build_basket() -> void:
	var wicker := _material(Color(0.42, 0.25, 0.12), 0.94)
	var wicker_light := _material(Color(0.61, 0.40, 0.20), 0.92)
	var basket_body := MeshInstance3D.new()
	basket_body.name = "WovenBasketBody"
	var basket_mesh := CylinderMesh.new()
	basket_mesh.top_radius = 0.62
	basket_mesh.bottom_radius = 0.43
	basket_mesh.height = 0.55
	basket_mesh.radial_segments = 24
	basket_body.mesh = basket_mesh
	basket_body.position.y = 0.28
	basket_body.material_override = wicker
	add_child(basket_body)
	for row in range(4):
		var weave := MeshInstance3D.new()
		var weave_mesh := TorusMesh.new()
		weave_mesh.inner_radius = 0.47 + float(row) * 0.033
		weave_mesh.outer_radius = 0.50 + float(row) * 0.033
		weave_mesh.rings = 24
		weave_mesh.ring_segments = 7
		weave.mesh = weave_mesh
		weave.position.y = 0.08 + float(row) * 0.13
		weave.material_override = wicker_light if row % 2 == 0 else wicker
		add_child(weave)
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.56
	rim_mesh.outer_radius = 0.65
	rim_mesh.rings = 32
	rim_mesh.ring_segments = 9
	rim.mesh = rim_mesh
	rim.position.y = 0.56
	rim.material_override = wicker_light
	add_child(rim)
	var handle := MeshInstance3D.new()
	var handle_mesh := TorusMesh.new()
	handle_mesh.inner_radius = 0.34
	handle_mesh.outer_radius = 0.40
	handle_mesh.rings = 32
	handle_mesh.ring_segments = 8
	handle.mesh = handle_mesh
	handle.position.y = 0.60
	handle.rotation.x = PI * 0.5
	handle.scale = Vector3(1.0, 0.83, 0.45)
	handle.material_override = wicker
	add_child(handle)
	for stick_index in range(10):
		var angle := TAU * float(stick_index) / 10.0
		var stick := MeshInstance3D.new()
		var stick_mesh := CylinderMesh.new()
		stick_mesh.top_radius = 0.012
		stick_mesh.bottom_radius = 0.018
		stick_mesh.height = 0.50
		stick_mesh.radial_segments = 6
		stick.mesh = stick_mesh
		stick.position = Vector3(cos(angle) * 0.52, 0.29, sin(angle) * 0.52)
		stick.rotation.z = cos(angle) * 0.08
		stick.rotation.x = sin(angle) * 0.08
		stick.material_override = wicker_light if stick_index % 2 == 0 else wicker
		add_child(stick)
	_create_fruit(Vector3(-0.22, 0.58, 0.0), Color(0.72, 0.17, 0.12), "RedApple")
	_create_fruit(Vector3(0.20, 0.60, -0.06), Color(0.91, 0.48, 0.11), "Orange")
	_create_fruit(Vector3(0.02, 0.60, 0.22), Color(0.58, 0.70, 0.20), "GreenPear")
	basket_label = Label3D.new()
	basket_label.name = "DailyFruitPrompt"
	basket_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	basket_label.position = Vector3(0.0, 1.42, 0.0)
	basket_label.font_size = 28
	basket_label.modulate = Color(1.0, 0.91, 0.62)
	basket_label.outline_size = 5
	basket_label.outline_modulate = Color(0.08, 0.07, 0.04, 0.95)
	add_child(basket_label)

func _create_fruit(location: Vector3, color: Color, fruit_name: String) -> void:
	var fruit := Node3D.new()
	fruit.name = fruit_name
	fruit.position = location
	add_child(fruit)
	var fruit_material := _material(color, 0.36)
	var body := MeshInstance3D.new()
	var fruit_mesh := SphereMesh.new()
	fruit_mesh.radial_segments = 24
	fruit_mesh.rings = 16
	fruit_mesh.radius = 0.20
	fruit_mesh.height = 0.40
	body.mesh = fruit_mesh
	body.scale = Vector3(0.86, 1.0 if fruit_name == "GreenPear" else 0.85, 0.86)
	body.material_override = fruit_material
	fruit.add_child(body)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.012
	stem_mesh.bottom_radius = 0.023
	stem_mesh.height = 0.12
	stem_mesh.radial_segments = 7
	stem.mesh = stem_mesh
	stem.position.y = 0.19
	stem.rotation.z = -0.18
	stem.material_override = _material(Color(0.27, 0.17, 0.08), 0.9)
	fruit.add_child(stem)
	var leaf := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radial_segments = 16
	leaf_mesh.rings = 10
	leaf_mesh.radius = 0.09
	leaf_mesh.height = 0.06
	leaf.mesh = leaf_mesh
	leaf.position = Vector3(0.065, 0.22, 0.0)
	leaf.rotation.z = -0.45
	leaf.scale = Vector3(1.5, 0.6, 0.7)
	leaf.material_override = _material(Color(0.19, 0.42, 0.15), 0.8)
	fruit.add_child(leaf)
	fruit_nodes.append(fruit)

func _refresh_fruit_display() -> void:
	for index in range(fruit_nodes.size()):
		fruit_nodes[index].visible = index < fruits_remaining
	if basket_label:
		basket_label.text = "FRUTA DEL DÍA · %d/%d\n[R] COMER" % [fruits_remaining, fruits_per_day] if fruits_remaining > 0 else "CANASTA VACÍA\nVuelve mañana"

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
