extends RefCounted
class_name TRushWorldMapData

const WORLD_HALF_EXTENT: float = 120.0
const STREAM_POINTS: Array[Vector2] = [
	Vector2(40.0, 51.0), Vector2(50.0, 55.0), Vector2(59.0, 60.0),
	Vector2(70.0, 68.0), Vector2(81.0, 80.0), Vector2(91.0, 91.0), Vector2(101.0, 102.0)
]

static func landmarks() -> Array[Dictionary]:
	return [
		{"id": "recycling", "label": "Estación", "icon": "♻", "position": Vector3(0.0, 0.0, 0.0), "color": Color(0.38, 0.88, 0.55)},
		{"id": "shop", "label": "Tienda", "icon": "$", "position": Vector3(7.5, 0.0, 0.0), "color": Color(0.98, 0.76, 0.34)},
		{"id": "cabin", "label": "Cabaña", "icon": "⌂", "position": Vector3(-7.5, 0.0, 0.0), "color": Color(0.85, 0.72, 0.50)},
		{"id": "pond", "label": "Laguna", "icon": "≈", "position": Vector3(-18.0, 0.0, -20.0), "color": Color(0.40, 0.82, 0.94)},
		{"id": "lookout", "label": "Mirador", "icon": "◎", "position": Vector3(0.0, 0.0, 99.0), "color": Color(0.87, 0.80, 0.49)},
		{"id": "forest", "label": "Bosque", "icon": "♣", "position": Vector3(-67.0, 0.0, -50.0), "color": Color(0.39, 0.76, 0.43)},
		{"id": "waste_valley", "label": "Valle", "icon": "!", "position": Vector3(68.0, 0.0, -45.0), "color": Color(0.91, 0.61, 0.37)},
		{"id": "rocky_highlands", "label": "Sierras", "icon": "▲", "position": Vector3(-70.0, 0.0, 44.0), "color": Color(0.75, 0.77, 0.70)},
		{"id": "east_stream", "label": "Arroyo", "icon": "≈", "position": Vector3(70.0, 0.0, 42.0), "color": Color(0.40, 0.82, 0.94)}
	]

static func stream_world_points() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point in STREAM_POINTS:
		result.append(Vector3(point.x, 0.0, point.y))
	return result
