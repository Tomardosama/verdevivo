extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TRASH_SCENE := preload("res://scenes/garbage/trash.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")

@export var starting_trash_count: int = 18
@export var trash_value: int = 1
@export var value_per_trash: int = 5

var player: TRushPlayer
var hud: TRushHUD
var money: int = 0

func _ready() -> void:
	_build_world()
	_spawn_player()
	_spawn_trash()
	_spawn_station()
	_create_hud()
	hud.update_money(money)

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

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	var environment_node := WorldEnvironment.new()
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
	environment_node.environment = environment
	add_child(environment_node)

	var trees := Node3D.new()
	trees.name = "Trees"
	add_child(trees)
	for i in range(22):
		var angle := TAU * float(i) / 22.0
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

func _spawn_trash() -> void:
	var positions := [
		Vector3(-3, 0, 1), Vector3(2, 0, 0), Vector3(4, 0, 3),
		Vector3(-5, 0, 4), Vector3(1, 0, -4), Vector3(-2, 0, -5),
		Vector3(6, 0, -3), Vector3(-7, 0, -2), Vector3(8, 0, 5),
		Vector3(0, 0, -8), Vector3(-9, 0, 7), Vector3(10, 0, -7),
		Vector3(3, 0, 8), Vector3(-4, 0, -9), Vector3(7, 0, 9),
		Vector3(-10, 0, -6), Vector3(11, 0, 1), Vector3(-1, 0, 10)
	]
	for i in range(min(starting_trash_count, positions.size())):
		var trash := TRASH_SCENE.instantiate() as TrashPickup
		trash.trash_value = trash_value
		trash.position = positions[i]
		var material := StandardMaterial3D.new()
		var colors := [Color(0.75, 0.78, 0.72), Color(0.75, 0.48, 0.18), Color(0.22, 0.48, 0.72)]
		material.albedo_color = colors[i % colors.size()]
		var visual := trash.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if visual:
			visual.material_override = material
		add_child(trash)

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
	hud.update_bag(0, player.bag_capacity)

func _on_inventory_changed(current: int, capacity: int) -> void:
	if hud:
		hud.update_bag(current, capacity)

func _on_deposit_requested() -> void:
	var amount := player.collect_bag_contents()
	var earned := amount * value_per_trash
	money += earned
	hud.update_money(money)
	hud.show_message("¡Reciclaste %d residuos! +$%d" % [amount, earned])
