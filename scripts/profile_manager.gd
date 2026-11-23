extends Node
class_name TRushProfileManager

const SAVE_VERSION: int = 5
const SLOT_COUNT: int = 3
const LEGACY_PATH: String = "user://trush_save.cfg"
const SETTINGS_PATH: String = "user://trush_settings.cfg"
const SETTINGS_DEFAULTS := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"effects_volume": 0.9,
	"mouse_sensitivity": 0.0025,
	"brightness": 1.0,
	"fov": 80.0,
	"quality": "high",
	"resolution": Vector2i(1600, 900),
	"fullscreen": false,
	"ui_font_scale": 1.0,
	"ui_theme": "forest",
	"ui_accent_color": Color(0.42, 0.67, 0.40),
	"ui_texts": {
		"help": "WASD mover · Shift correr · Clic recoger · E reciclar · R fruta/radar · Esc opciones",
		"recycle": "RECICLAJE\n[E]",
		"shop": "TIENDA DE MEJORAS\n[E]",
		"rest": "DESCANSAR\n[E]"
	}
}

var active_slot: int = 0
var active_profile_name: String = ""
var last_error: String = ""
var global_settings: Dictionary = {}
var profile_storage_prefix: String = "user://"

func _ready() -> void:
	_load_global_settings()
	_migrate_legacy_save()

func slot_path(slot_id: int) -> String:
	return profile_storage_prefix.path_join("trush_profile_%d.cfg" % clampi(slot_id, 1, SLOT_COUNT))

func activate_slot(slot_id: int) -> bool:
	last_error = ""
	if slot_id < 1 or slot_id > SLOT_COUNT:
		last_error = "El perfil seleccionado no existe."
		return false
	var path := slot_path(slot_id)
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		last_error = "Ese perfil está vacío o no se pudo leer."
		return false
	var version := int(config.get_value("meta", "save_version", 1))
	if version > SAVE_VERSION:
		last_error = "El perfil se creó con una versión más nueva del juego."
		return false
	active_slot = slot_id
	active_profile_name = str(config.get_value("meta", "profile_name", "Explorador"))
	return true

func create_profile(slot_id: int, profile_name: String, overwrite_confirmed: bool = false) -> bool:
	last_error = ""
	if slot_id < 1 or slot_id > SLOT_COUNT:
		last_error = "Elige uno de los tres espacios disponibles."
		return false
	var path := slot_path(slot_id)
	if FileAccess.file_exists(path) and not overwrite_confirmed:
		last_error = "Este espacio ya contiene una partida; confirma el reemplazo."
		return false
	var sanitized_name := profile_name.strip_edges().left(20)
	if sanitized_name.is_empty():
		sanitized_name = "Explorador %d" % slot_id
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("meta", "profile_name", sanitized_name)
	config.set_value("meta", "created_unix", int(Time.get_unix_time_from_system()))
	config.set_value("economy", "money", 0)
	config.set_value("progress", "collected_trash", 0)
	config.set_value("progress", "radar_unlocked", false)
	config.set_value("progress", "radar_active", false)
	var error := config.save(path)
	if error != OK:
		last_error = "No se pudo crear el perfil en user://. Error %d." % error
		return false
	active_slot = slot_id
	active_profile_name = sanitized_name
	return true

func delete_profile(slot_id: int, confirmed: bool = false) -> bool:
	last_error = ""
	if slot_id < 1 or slot_id > SLOT_COUNT:
		last_error = "El perfil seleccionado no existe."
		return false
	if not confirmed:
		last_error = "Confirma el borrado de este perfil."
		return false
	var path := slot_path(slot_id)
	if not FileAccess.file_exists(path):
		last_error = "Ese espacio ya está vacío."
		return false
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		last_error = "No se pudo borrar el perfil. Error %d." % error
		return false
	if active_slot == slot_id:
		active_slot = 0
		active_profile_name = ""
	return true

func get_slot_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for slot_id in range(1, SLOT_COUNT + 1):
		var path := slot_path(slot_id)
		var summary := {"slot": slot_id, "occupied": false, "valid": true, "name": "Espacio %d · vacío" % slot_id, "money": 0, "cleanup": 0, "version": 0}
		if FileAccess.file_exists(path):
			var config := ConfigFile.new()
			var error := config.load(path)
			if error != OK:
				summary["occupied"] = true
				summary["valid"] = false
				summary["name"] = "Espacio %d · archivo dañado" % slot_id
			else:
				var version := int(config.get_value("meta", "save_version", 1))
				summary["occupied"] = true
				summary["valid"] = version <= SAVE_VERSION
				summary["version"] = version
				summary["name"] = str(config.get_value("meta", "profile_name", "Explorador"))
				summary["money"] = maxi(0, int(config.get_value("economy", "money", 0)))
				summary["cleanup"] = clampi(int(config.get_value("progress", "cleanup_percent", 0)), 0, 100)
				if not bool(summary["valid"]):
					summary["name"] = str(summary["name"]) + " · versión incompatible"
		summaries.append(summary)
	return summaries

func get_active_save_path() -> String:
	return slot_path(active_slot) if active_slot > 0 else LEGACY_PATH

func note_save_completed(money: int, cleanup: int) -> void:
	if active_slot <= 0:
		return
	var config := ConfigFile.new()
	if config.load(slot_path(active_slot)) != OK:
		return
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("meta", "profile_name", active_profile_name)
	config.set_value("meta", "saved_unix", int(Time.get_unix_time_from_system()))
	config.set_value("meta", "active_slot", active_slot)
	config.set_value("economy", "money", maxi(0, money))
	config.set_value("progress", "cleanup_percent", clampi(cleanup, 0, 100))
	config.save(slot_path(active_slot))

func get_setting(key: String, fallback: Variant = null) -> Variant:
	return global_settings.get(key, fallback if fallback != null else SETTINGS_DEFAULTS.get(key))

func set_setting(key: String, value: Variant) -> void:
	if not SETTINGS_DEFAULTS.has(key):
		return
	global_settings[key] = _sanitize_setting(key, value)
	_save_global_settings()

func get_ui_text(key: String) -> String:
	var texts: Dictionary = global_settings.get("ui_texts", SETTINGS_DEFAULTS["ui_texts"]).duplicate()
	return str(texts.get(key, SETTINGS_DEFAULTS["ui_texts"].get(key, "")))

func set_ui_text(key: String, value: String) -> void:
	if not SETTINGS_DEFAULTS["ui_texts"].has(key):
		return
	var texts: Dictionary = global_settings.get("ui_texts", SETTINGS_DEFAULTS["ui_texts"]).duplicate()
	texts[key] = value.strip_edges().left(54 if key == "help" else 30)
	global_settings["ui_texts"] = texts
	_save_global_settings()

func reset_ui_customization() -> void:
	global_settings["ui_font_scale"] = SETTINGS_DEFAULTS["ui_font_scale"]
	global_settings["ui_theme"] = SETTINGS_DEFAULTS["ui_theme"]
	global_settings["ui_accent_color"] = SETTINGS_DEFAULTS["ui_accent_color"]
	global_settings["ui_texts"] = SETTINGS_DEFAULTS["ui_texts"].duplicate(true)
	_save_global_settings()

func apply_runtime_settings(viewport: Viewport = null) -> void:
	_set_audio_bus("Master", float(get_setting("master_volume", 1.0)))
	_set_audio_bus("Music", float(get_setting("music_volume", 0.8)))
	_set_audio_bus("SFX", float(get_setting("effects_volume", 0.9)))
	if viewport:
		match str(get_setting("quality", "high")):
			"low": viewport.msaa_3d = Viewport.MSAA_DISABLED
			"medium": viewport.msaa_3d = Viewport.MSAA_2X
			_: viewport.msaa_3d = Viewport.MSAA_4X
	var resolution: Vector2i = get_setting("resolution", Vector2i(1600, 900))
	if bool(get_setting("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)

func _set_audio_bus(bus_name: String, linear_volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_linear(index, clampf(linear_volume, 0.0, 1.0))

func _load_global_settings() -> void:
	global_settings = SETTINGS_DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in SETTINGS_DEFAULTS:
		global_settings[key] = _sanitize_setting(key, config.get_value("settings", key, SETTINGS_DEFAULTS[key]))

func _save_global_settings() -> void:
	var config := ConfigFile.new()
	for key in SETTINGS_DEFAULTS:
		config.set_value("settings", key, _sanitize_setting(key, global_settings.get(key, SETTINGS_DEFAULTS[key])))
	config.set_value("meta", "settings_version", 1)
	config.save(SETTINGS_PATH)

func _sanitize_setting(key: String, value: Variant) -> Variant:
	match key:
		"master_volume", "music_volume", "effects_volume": return clampf(float(value), 0.0, 1.0)
		"mouse_sensitivity": return clampf(float(value), 0.0004, 0.008)
		"brightness": return clampf(float(value), 0.5, 1.6)
		"fov": return clampf(float(value), 65.0, 105.0)
		"ui_font_scale": return clampf(float(value), 0.8, 1.2)
		"quality": return str(value) if str(value) in ["low", "medium", "high"] else str(SETTINGS_DEFAULTS[key])
		"ui_theme": return str(value) if str(value) in ["forest", "night", "light"] else str(SETTINGS_DEFAULTS[key])
		"ui_accent_color": return value if value is Color else SETTINGS_DEFAULTS[key]
		"resolution":
			if value is Vector2i:
				var resolution: Vector2i = value
				return Vector2i(clampi(resolution.x, 960, 3840), clampi(resolution.y, 540, 2160))
			return SETTINGS_DEFAULTS[key]
		"fullscreen": return bool(value)
		"ui_texts":
			if value is Dictionary:
				var safe_texts: Dictionary = SETTINGS_DEFAULTS["ui_texts"].duplicate()
				for text_key in safe_texts:
					if value.has(text_key):
						safe_texts[text_key] = str(value[text_key]).strip_edges().left(54 if text_key == "help" else 30)
				return safe_texts
		_: return value
	return SETTINGS_DEFAULTS.get(key, value)

func _migrate_legacy_save() -> void:
	var first_slot := slot_path(1)
	if FileAccess.file_exists(first_slot) or not FileAccess.file_exists(LEGACY_PATH):
		return
	var legacy := ConfigFile.new()
	if legacy.load(LEGACY_PATH) != OK:
		return
	legacy.set_value("meta", "save_version", 1)
	legacy.set_value("meta", "profile_name", "Partida anterior")
	legacy.set_value("meta", "migrated_from_legacy", true)
	legacy.save(first_slot)
