extends Control
class_name TRushMinimap

const WORLD_DATA := preload("res://scripts/environment/world_map_data.gd")

var player_position: Vector3 = Vector3.ZERO
var player_yaw: float = 0.0
var garbage_positions: Array[Vector3] = []
var boss_positions: Array[Vector3] = []
var radar_active: bool = false
var radar_range: float = 90.0

func _ready() -> void:
	custom_minimum_size = Vector2(238.0, 222.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func update_world_state(player_pos: Vector3, yaw: float, garbage: Array[Vector3], bosses: Array[Vector3], radar_enabled: bool, coverage: float) -> void:
	player_position = player_pos
	player_yaw = yaw
	garbage_positions = garbage
	boss_positions = bosses
	radar_active = radar_enabled
	radar_range = coverage
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.085, 0.064, 0.94)
	panel.border_color = Color(0.50, 0.70, 0.52, 0.82)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(14)
	draw_style_box(panel, bounds)
	draw_string(ThemeDB.fallback_font, Vector2(12.0, 19.0), "MAPA  ·  %s" % ("RADAR ACTIVO" if radar_active else "EXPLORACIÓN"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.88, 0.94, 0.82))
	var map_size := maxf(1.0, minf(size.x - 20.0, size.y - 37.0))
	var map_rect := Rect2(Vector2((size.x - map_size) * 0.5, 27.0), Vector2(map_size, map_size))
	draw_rect(map_rect, Color(0.13, 0.22, 0.15, 0.97), true)
	draw_rect(map_rect, Color(0.55, 0.70, 0.51, 0.72), false, 1.0)
	_draw_region_patch(map_rect, Vector2(-67.0, -68.0), 27.0, Color(0.10, 0.33, 0.20, 0.76))
	_draw_region_patch(map_rect, Vector2(66.0, -65.0), 29.0, Color(0.38, 0.30, 0.18, 0.75))
	_draw_region_patch(map_rect, Vector2(-70.0, 66.0), 25.0, Color(0.34, 0.37, 0.34, 0.78))
	_draw_region_patch(map_rect, Vector2(70.0, 68.0), 20.0, Color(0.12, 0.34, 0.40, 0.72))
	_draw_trails(map_rect)
	_draw_water(map_rect)
	if radar_active and radar_range > 0.0:
		draw_circle(_world_to_map(Vector2(player_position.x, player_position.z), map_rect), radar_range / (WORLD_DATA.WORLD_HALF_EXTENT * 2.0) * map_rect.size.x, Color(0.37, 0.82, 0.58, 0.08), true)
		draw_arc(_world_to_map(Vector2(player_position.x, player_position.z), map_rect), radar_range / (WORLD_DATA.WORLD_HALF_EXTENT * 2.0) * map_rect.size.x, 0.0, TAU, 64, Color(0.56, 0.91, 0.65, 0.55), 1.0, true)
		for trash_pos in garbage_positions:
			var horizontal := Vector2(trash_pos.x - player_position.x, trash_pos.z - player_position.z).length()
			if horizontal <= radar_range:
				draw_circle(_world_to_map(Vector2(trash_pos.x, trash_pos.z), map_rect), 2.2, Color(1.0, 0.22, 0.16, 0.96), true)
	for landmark in WORLD_DATA.landmarks():
		_draw_landmark(map_rect, landmark)
	for boss_pos in boss_positions:
		_draw_boss_marker(map_rect, Vector2(boss_pos.x, boss_pos.z))
	_draw_player(map_rect)
	if radar_active:
		draw_string(ThemeDB.fallback_font, Vector2(map_rect.position.x + 5.0, map_rect.end.y - 6.0), "ROJOS: RESIDUOS EN RADIO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(1.0, 0.55, 0.44))

func _world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	var normalized := (world_position + Vector2.ONE * WORLD_DATA.WORLD_HALF_EXTENT) / (WORLD_DATA.WORLD_HALF_EXTENT * 2.0)
	return Vector2(map_rect.position.x + normalized.x * map_rect.size.x, map_rect.position.y + (1.0 - normalized.y) * map_rect.size.y)

func _draw_region_patch(map_rect: Rect2, center: Vector2, radius: float, color: Color) -> void:
	draw_circle(_world_to_map(center, map_rect), radius / (WORLD_DATA.WORLD_HALF_EXTENT * 2.0) * map_rect.size.x, color, true)

func _draw_trails(map_rect: Rect2) -> void:
	var center := _world_to_map(Vector2.ZERO, map_rect)
	for endpoint in [Vector2(-67.0, -68.0), Vector2(66.0, -65.0), Vector2(-70.0, 66.0), Vector2(70.0, 68.0), Vector2(0.0, 99.0)]:
		draw_line(center, _world_to_map(endpoint, map_rect), Color(0.66, 0.56, 0.38, 0.55), 1.5, true)

func _draw_water(map_rect: Rect2) -> void:
	var water_points := PackedVector2Array()
	for point in WORLD_DATA.STREAM_POINTS:
		water_points.append(_world_to_map(point, map_rect))
	draw_polyline(water_points, Color(0.24, 0.78, 0.91, 0.90), 4.0, true)
	draw_circle(_world_to_map(Vector2(-18.0, -20.0), map_rect), 5.8 / (WORLD_DATA.WORLD_HALF_EXTENT * 2.0) * map_rect.size.x, Color(0.24, 0.78, 0.91, 0.85), true)

func _draw_landmark(map_rect: Rect2, landmark: Dictionary) -> void:
	var position: Vector3 = landmark["position"]
	var point := _world_to_map(Vector2(position.x, position.z), map_rect)
	var color: Color = landmark["color"]
	draw_circle(point, 5.8, Color(0.025, 0.055, 0.038, 0.98), true)
	draw_circle(point, 4.7, color, true)
	draw_string(ThemeDB.fallback_font, point + Vector2(-4.0, 3.5), str(landmark["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.025, 0.055, 0.038))
	if str(landmark["id"]) in ["recycling", "lookout", "shop", "cabin"]:
		draw_string(ThemeDB.fallback_font, point + Vector2(7.0, 3.5), str(landmark["label"]), HORIZONTAL_ALIGNMENT_LEFT, 62.0, 9, Color(0.90, 0.93, 0.82))

func _draw_boss_marker(map_rect: Rect2, world_position: Vector2) -> void:
	var point := _world_to_map(world_position, map_rect)
	var diamond := PackedVector2Array([point + Vector2(0.0, -6.0), point + Vector2(6.0, 0.0), point + Vector2(0.0, 6.0), point + Vector2(-6.0, 0.0)])
	draw_colored_polygon(diamond, Color(0.98, 0.34, 0.19))
	draw_string(ThemeDB.fallback_font, point + Vector2(-2.0, 3.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.12, 0.035, 0.025))

func _draw_player(map_rect: Rect2) -> void:
	var point := _world_to_map(Vector2(player_position.x, player_position.z), map_rect)
	var world_forward := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, player_yaw)
	var facing := Vector2(world_forward.x, -world_forward.z).normalized()
	var side := Vector2(-facing.y, facing.x)
	var arrow := PackedVector2Array([point + facing * 9.0, point - facing * 6.0 + side * 5.0, point - facing * 6.0 - side * 5.0])
	draw_colored_polygon(arrow, Color(0.96, 0.99, 0.87))
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), Color(0.035, 0.09, 0.05), 1.4, true)
