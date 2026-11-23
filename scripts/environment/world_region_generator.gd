extends RefCounted
class_name TRushWorldRegionGenerator

const SIGN_SCRIPT := preload("res://scripts/environment/player_facing_sign.gd")

## Small reusable world-building helpers. Regions stay static; only trees,
## wildlife, clouds, bosses and water shaders animate at runtime.

static func add_path(parent: Node3D, points: Array[Vector3], width: float, material: Material, path_name: String) -> void:
	var path_root := Node3D.new()
	path_root.name = path_name
	parent.add_child(path_root)
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var direction := finish - start
		var segment := MeshInstance3D.new()
		segment.name = "PathSegment_%02d" % index
		var path_mesh := BoxMesh.new()
		path_mesh.size = Vector3(width, 0.035, direction.length())
		segment.mesh = path_mesh
		segment.position = (start + finish) * 0.5 + Vector3.UP * 0.01
		segment.rotation.y = atan2(direction.x, direction.z)
		segment.material_override = material
		path_root.add_child(segment)

static func add_water_ribbon(parent: Node3D, points: Array[Vector3], width: float, material: Material, water_name: String) -> MeshInstance3D:
	var water := MeshInstance3D.new()
	water.name = water_name
	if points.size() < 2:
		parent.add_child(water)
		return water
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	var half_width := width * 0.5
	var extended := points.duplicate()
	var first_direction := (points[1] - points[0]).normalized()
	var last_direction := (points[points.size() - 1] - points[points.size() - 2]).normalized()
	extended[0] -= first_direction * half_width
	extended[extended.size() - 1] += last_direction * half_width
	var left_edges: Array[Vector3] = []
	var right_edges: Array[Vector3] = []
	for point_index in range(extended.size()):
		var tangent: Vector3
		if point_index == 0:
			tangent = (extended[1] - extended[0]).normalized()
		elif point_index == extended.size() - 1:
			tangent = (extended[point_index] - extended[point_index - 1]).normalized()
		else:
			tangent = (extended[point_index + 1] - extended[point_index - 1]).normalized()
		var side := Vector3(tangent.z, 0.0, -tangent.x).normalized()
		left_edges.append(extended[point_index] + side * half_width + Vector3.UP * 0.11)
		right_edges.append(extended[point_index] - side * half_width + Vector3.UP * 0.11)
	for segment_index in range(extended.size() - 1):
		var u0 := float(segment_index) / float(extended.size() - 1)
		var u1 := float(segment_index + 1) / float(extended.size() - 1)
		surface.set_uv(Vector2(u0, 0.0))
		surface.add_vertex(left_edges[segment_index])
		surface.set_uv(Vector2(u0, 1.0))
		surface.add_vertex(right_edges[segment_index])
		surface.set_uv(Vector2(u1, 0.0))
		surface.add_vertex(left_edges[segment_index + 1])
		surface.set_uv(Vector2(u1, 0.0))
		surface.add_vertex(left_edges[segment_index + 1])
		surface.set_uv(Vector2(u0, 1.0))
		surface.add_vertex(right_edges[segment_index])
		surface.set_uv(Vector2(u1, 1.0))
		surface.add_vertex(right_edges[segment_index + 1])
	surface.generate_normals()
	water.mesh = surface.commit()
	water.material_override = material
	parent.add_child(water)
	return water

static func add_hill(parent: Node3D, center: Vector3, radius: float, height: float, seed_value: int, material: Material) -> MeshInstance3D:
	var resolution := 32
	var side := resolution + 1
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for z_index in range(side):
		for x_index in range(side):
			var x := lerpf(-radius, radius, float(x_index) / float(resolution))
			var z := lerpf(-radius, radius, float(z_index) / float(resolution))
			var radial_distance := Vector2(x, z).length() / radius
			var profile := maxf(0.0, 1.0 - radial_distance)
			var ridge := 1.0 + 0.045 * sin(x * 0.43 + float(seed_value)) * cos(z * 0.37 - float(seed_value))
			var elevation := pow(profile, 1.55) * height * ridge
			surface.set_uv(Vector2(float(x_index) / float(resolution), float(z_index) / float(resolution)))
			surface.add_vertex(Vector3(x, elevation, z))
	for z_index in range(resolution):
		for x_index in range(resolution):
			var a := z_index * side + x_index
			var b := a + 1
			var c := a + side
			var d := c + 1
			surface.add_index(a)
			surface.add_index(c)
			surface.add_index(b)
			surface.add_index(b)
			surface.add_index(c)
			surface.add_index(d)
	surface.generate_normals()
	var hill_mesh := surface.commit()
	var hill_visual := MeshInstance3D.new()
	hill_visual.name = "ErodedHill"
	hill_visual.add_to_group("decorative_mountain")
	hill_visual.mesh = hill_mesh
	hill_visual.position = center
	parent.add_child(hill_visual)
	return hill_visual

static func add_region_sign(parent: Node3D, label_text: String, location: Vector3, tint: Color) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "RegionSign_" + label_text.to_lower().replace(" ", "_")
	sign_root.position = location
	sign_root.set_script(SIGN_SCRIPT)
	parent.add_child(sign_root)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.28, 0.18, 0.11)
	wood.roughness = 0.96
	var board := StandardMaterial3D.new()
	board.albedo_color = tint.darkened(0.5)
	board.roughness = 0.85
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.10
	post_mesh.bottom_radius = 0.14
	post_mesh.height = 1.8
	post.mesh = post_mesh
	post.position.y = 0.9
	post.material_override = wood
	sign_root.add_child(post)
	var plaque := MeshInstance3D.new()
	var plaque_mesh := BoxMesh.new()
	plaque_mesh.size = Vector3(2.5, 0.72, 0.12)
	plaque.mesh = plaque_mesh
	plaque.position.y = 1.62
	plaque.material_override = board
	sign_root.add_child(plaque)
	var label := Label3D.new()
	label.text = label_text
	label.position = Vector3(0.0, 1.62, -0.08)
	label.font_size = 28
	label.modulate = tint.lightened(0.24)
	label.no_depth_test = false
	sign_root.add_child(label)

static func add_landmark(parent: Node3D, label_text: String, location: Vector3, tint: Color) -> Node3D:
	var landmark := Node3D.new()
	landmark.name = "Landmark_" + label_text.to_lower().replace(" ", "_")
	landmark.position = location
	parent.add_child(landmark)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = tint
	stone.roughness = 0.93
	var foundation := MeshInstance3D.new()
	var foundation_mesh := CylinderMesh.new()
	foundation_mesh.top_radius = 3.2
	foundation_mesh.bottom_radius = 3.6
	foundation_mesh.height = 0.55
	foundation.mesh = foundation_mesh
	foundation.position.y = 0.28
	foundation.material_override = stone
	landmark.add_child(foundation)
	for pillar_index in range(3):
		var pillar := MeshInstance3D.new()
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.32, 3.5 + float(pillar_index % 2) * 0.55, 0.32)
		pillar.mesh = pillar_mesh
		var angle := TAU * float(pillar_index) / 3.0
		pillar.position = Vector3(cos(angle) * 2.15, pillar_mesh.size.y * 0.5 + 0.55, sin(angle) * 2.15)
		pillar.rotation.z = cos(angle) * 0.08
		pillar.material_override = stone
		landmark.add_child(pillar)
	var sign_root := Node3D.new()
	sign_root.name = "LandmarkNameSign"
	sign_root.position.y = 4.5
	sign_root.set_script(SIGN_SCRIPT)
	landmark.add_child(sign_root)
	var marker := Label3D.new()
	marker.text = label_text
	marker.font_size = 32
	marker.modulate = tint.lightened(0.25)
	sign_root.add_child(marker)
	return landmark
