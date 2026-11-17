extends CanvasLayer
class_name TRushHUD

signal upgrade_requested(upgrade_id: String)
signal prestige_requested
signal bestiary_toggled

var money_label: Label
var bag_label: Label
var progress_label: Label
var phase_label: Label
var message_label: Label
var mission_label: Label
var stats_label: Label
var upgrade_buttons: Array[Button] = []
var bestiary_panel: PanelContainer
var bestiary_list: VBoxContainer
var stats_panel: PanelContainer
var menu_panel: PanelContainer
var achievement_count: int = 0
var message_time_left: float = 0.0

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var status_panel := _make_panel(Vector2(22, 20), Vector2(370, 190))
	root.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 7)
	status_panel.add_child(status_box)
	money_label = _make_label("✦  $0", 23)
	bag_label = _make_label("♧  Bolsa 0 / 5", 18)
	progress_label = _make_label("Bosque 0% restaurado", 17)
	phase_label = _make_label("☀  DÍA", 17)
	mission_label = _make_label("MISIÓN · Recolecta y recicla residuos", 14)
	for label in [money_label, bag_label, progress_label, phase_label, mission_label]:
		status_box.add_child(label)

	var upgrades_panel := _make_panel(Vector2(22, 225), Vector2(370, 330))
	root.add_child(upgrades_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 6)
	upgrades_panel.add_child(upgrade_box)
	upgrade_box.add_child(_make_label("TALLER DE MEJORAS", 18))
	upgrade_box.add_child(_make_label("Disponible durante la noche", 12, Color(0.70, 0.79, 0.72)))
	var upgrade_data := [
		["speed", "Velocidad", "Movimiento más rápido"],
		["capacity", "Bolsa", "+2 unidades de capacidad"],
		["value", "Reciclaje", "Más ingresos por residuo"],
		["range", "Alcance", "Recogida a más distancia"],
		["day", "Turno", "Más tiempo de trabajo"]
	]
	for item in upgrade_data:
		var button := _make_button("%s  ·  %s" % [item[1], item[2]])
		button.pressed.connect(_on_upgrade_pressed.bind(item[0]))
		upgrade_box.add_child(button)
		upgrade_buttons.append(button)
	var prestige_button := _make_button("✧  RESTAURAR BIOMA · PRESTIGIO")
	prestige_button.pressed.connect(func(): prestige_requested.emit())
	upgrade_box.add_child(prestige_button)

	var bestiary_button := _make_button("📖  BESTIARIO")
	bestiary_button.position = Vector2(22, 570)
	bestiary_button.size = Vector2(170, 42)
	root.add_child(bestiary_button)
	bestiary_button.pressed.connect(func(): bestiary_toggled.emit())

	var stats_button := _make_button("ESTADÍSTICAS")
	stats_button.position = Vector2(202, 570)
	stats_button.size = Vector2(170, 42)
	root.add_child(stats_button)
	stats_button.pressed.connect(_toggle_stats)

	var menu_button := _make_button("MENÚ")
	menu_button.position = Vector2(382, 570)
	menu_button.size = Vector2(120, 42)
	root.add_child(menu_button)
	menu_button.pressed.connect(_toggle_menu)
	menu_panel = _make_panel(Vector2.ZERO, Vector2(440, 300))
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.visible = false
	root.add_child(menu_panel)
	var menu_box := VBoxContainer.new()
	menu_panel.add_child(menu_box)
	menu_box.add_child(_make_label("TRush · RESTAURACIÓN", 24))
	menu_box.add_child(_make_label("Explora, recupera residuos y devuelve la vida al bosque.", 15))
	var resume_button := _make_button("CONTINUAR JUGANDO")
	resume_button.pressed.connect(_toggle_menu)
	menu_box.add_child(resume_button)
	var menu_stats_button := _make_button("VER ESTADÍSTICAS")
	menu_stats_button.pressed.connect(_toggle_stats)
	menu_box.add_child(menu_stats_button)
	menu_box.add_child(_make_label("WASD mover · Shift correr · Clic recoger · E reciclar", 13))

	bestiary_panel = _make_panel(Vector2(410, 210), Vector2(430, 330))
	bestiary_panel.visible = false
	root.add_child(bestiary_panel)
	bestiary_list = VBoxContainer.new()
	bestiary_list.add_theme_constant_override("separation", 10)
	bestiary_panel.add_child(bestiary_list)
	bestiary_list.add_child(_make_label("BESTIARIO DEL BOSQUE", 21))

	stats_panel = _make_panel(Vector2(410, 210), Vector2(430, 250))
	stats_panel.visible = false
	root.add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_panel.add_child(stats_box)
	stats_box.add_child(_make_label("RESUMEN DE PARTIDA", 20))
	stats_label = _make_label("Todavía no hay estadísticas.", 16)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_box.add_child(stats_label)

	var help_panel := _make_panel(Vector2(22, -62), Vector2(550, 46))
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(help_panel)
	var help := _make_label("WASD mover   ·   Shift correr   ·   Clic recoger   ·   E reciclar   ·   Esc liberar mouse", 13)
	help.position = Vector2(12, 11)
	help_panel.add_child(help)

	var notification_panel := _make_panel(Vector2(0, 28), Vector2(560, 62))
	notification_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notification_panel.position = Vector2(0, 26)
	notification_panel.anchor_left = 0.5
	notification_panel.anchor_right = 0.5
	notification_panel.offset_left = -280
	notification_panel.offset_right = 280
	notification_panel.visible = false
	root.add_child(notification_panel)
	message_label = _make_label("", 18)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_panel.add_child(message_label)
	set_meta("notification_panel", notification_panel)

func _make_panel(position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = size_value
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.105, 0.085, 0.91)
	style.border_color = Color(0.36, 0.57, 0.39, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 37)
	button.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.24, 0.18, 0.98)
	normal.border_color = Color(0.32, 0.48, 0.34)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.19, 0.34, 0.23, 1.0)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.10, 0.13, 0.11, 0.8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	return button

func _make_label(value: String, font_size: int, color: Color = Color(0.91, 0.95, 0.89)) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _process(delta: float) -> void:
	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0:
			var panel := get_meta("notification_panel") as PanelContainer
			if panel:
				panel.visible = false

func _on_upgrade_pressed(upgrade_id: String) -> void:
	upgrade_requested.emit(upgrade_id)

func update_bag(current: int, capacity: int) -> void:
	bag_label.text = "♧  Bolsa %d / %d" % [current, capacity]

func update_money(amount: int) -> void:
	money_label.text = "✦  $%d" % amount

func update_progress(percent: int) -> void:
	progress_label.text = "Bosque %d%% restaurado" % percent
	var milestones := [{"value": 25, "name": "Primeros brotes"}, {"value": 50, "name": "Manos a la tierra"}, {"value": 75, "name": "Guardián del bosque"}, {"value": 100, "name": "Ecosistema restaurado"}]
	for milestone in milestones:
		var key := "achievement_" + str(milestone["value"])
		if percent >= int(milestone["value"]) and not has_meta(key):
			set_meta(key, true)
			achievement_count += 1
			show_message("Logro desbloqueado: " + str(milestone["name"]))

func update_phase(is_day: bool, seconds_left: int) -> void:
	phase_label.text = "%s  %s  ·  %02d:%02d" % ["☀" if is_day else "☾", "DÍA" if is_day else "NOCHE", seconds_left / 60, seconds_left % 60]

func update_mission(value: String) -> void:
	mission_label.text = "MISIÓN · " + value

func set_upgrade_access(enabled: bool) -> void:
	for button in upgrade_buttons:
		button.disabled = not enabled

func set_bestiary(entries: Array[Dictionary]) -> void:
	for index in range(1, bestiary_list.get_child_count()):
		bestiary_list.get_child(index).queue_free()
	if entries.is_empty():
		bestiary_list.add_child(_make_label("Aún no descubriste especies. Limpia el bosque para atraer fauna.", 15))
	for entry in entries:
		var label := _make_label("✦ %s\n%s" % [entry.get("name", "Especie"), entry.get("description", "")], 15)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bestiary_list.add_child(label)

func toggle_bestiary() -> void:
	bestiary_panel.visible = not bestiary_panel.visible
	stats_panel.visible = false

func _toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	bestiary_panel.visible = false
	menu_panel.visible = false

func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible
	stats_panel.visible = false
	bestiary_panel.visible = false
	if menu_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_stats(money: int, collected: int, prestige: int, elapsed_seconds: int) -> void:
	stats_label.text = "Fondos acumulados: $%d\nResiduos recuperados: %d\nPrestigios: %d\nTiempo de sesión: %02d:%02d" % [money, collected, prestige, elapsed_seconds / 60, elapsed_seconds % 60]

func show_message(message: String) -> void:
	message_label.text = message
	var panel := get_meta("notification_panel") as PanelContainer
	if panel:
		panel.visible = true
	message_time_left = 3.8
