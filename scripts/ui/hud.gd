extends CanvasLayer
class_name TRushHUD

signal options_changed(brightness: float, music_volume: float, effects_volume: float, fov: float)
signal pause_state_changed(is_paused: bool)
signal upgrade_requested(upgrade_id: String)
signal prestige_requested
signal skill_requested(skill_id: String)
signal bestiary_toggled

var money_label: Label
var bag_label: Label
var progress_label: Label
var phase_label: Label
var message_label: Label
var mission_label: Label
var stats_label: Label
var upgrade_buttons: Array[Button] = []
var upgrade_ids: Array[String] = []
var upgrade_descriptions := {"speed": "Movimiento más rápido", "capacity": "+2 espacios de bolsa", "value": "Más ingresos por residuo", "range": "Mayor alcance manual", "day": "Más duración del día", "vacuum": "Amplía el radio y acelera el viaje del residuo a la boquilla", "discount": "Reduce otros costos"}
var upgrade_names := {"speed": "Velocidad", "capacity": "Bolsa", "value": "Valor reciclado", "range": "Alcance manual", "day": "Duración del día", "vacuum": "Aspiradora", "discount": "Descuento"}
var bestiary_panel: PanelContainer
var bestiary_list: VBoxContainer
var stats_panel: PanelContainer
var menu_panel: PanelContainer
var shop_panel: Control
var shop_open: bool = false
var skill_panel: PanelContainer
var skill_status_label: Label
var crosshair: Label
var achievement_count: int = 0
var message_time_left: float = 0.0
var shop_obscured_controls: Array[Control] = []
var pause_panel: PanelContainer
var pause_backdrop: ColorRect
var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_pause_menu(root)

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
	var bag_widget := _make_panel(Vector2(-190, -92), Vector2(170, 68))
	bag_widget.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	root.add_child(bag_widget)
	var bag_box := VBoxContainer.new()
	bag_box.add_theme_constant_override("separation", 3)
	bag_widget.add_child(bag_box)
	var bag_icon_label := _make_label("▱  BOLSA  0%", 16)
	bag_icon_label.name = "BagFillLabel"
	bag_box.add_child(bag_icon_label)
	var bag_bar := ProgressBar.new()
	bag_bar.name = "BagFillBar"
	bag_bar.min_value = 0
	bag_bar.max_value = 100
	bag_bar.value = 0
	bag_bar.show_percentage = false
	bag_bar.custom_minimum_size = Vector2(140, 14)
	bag_box.add_child(bag_bar)
	set_meta("bag_fill_label", bag_icon_label)
	set_meta("bag_fill_bar", bag_bar)

	var shop_center := CenterContainer.new()
	shop_center.name = "ShopCenterContainer"
	shop_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_center.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shop_center)
	var upgrades_panel := _make_panel(Vector2.ZERO, Vector2(490, 500))
	upgrades_panel.custom_minimum_size = Vector2(490, 500)
	shop_center.add_child(upgrades_panel)
	shop_center.visible = false
	shop_panel = shop_center
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
		["day", "Turno", "Más tiempo de trabajo"],
		["vacuum", "Aspiradora", "Radio y velocidad de succión · F"],
		["discount", "Ahorro", "Reduce progresivamente otros costos"]
	]
	for item in upgrade_data:
		var button := _make_button("%s  ·  %s" % [item[1], item[2]])
		button.pressed.connect(_on_upgrade_pressed.bind(item[0]))
		upgrade_box.add_child(button)
		upgrade_buttons.append(button)
		upgrade_ids.append(str(item[0]))
	var shop_close_button := _make_button("CERRAR TIENDA · ESC")
	shop_close_button.pressed.connect(func(): show_shop(false))
	upgrade_box.add_child(shop_close_button)
	var prestige_button := _make_button("✧  RESTAURAR BIOMA · PRESTIGIO")
	prestige_button.pressed.connect(func(): prestige_requested.emit())
	upgrade_box.add_child(prestige_button)

	var skills_button := _make_button("ÁRBOL DE HABILIDADES · TAB")
	skills_button.position = Vector2(20, -112)
	skills_button.size = Vector2(230, 42)
	skills_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	skills_button.position = Vector2(20, -204)
	root.add_child(skills_button)
	shop_obscured_controls.append(skills_button)
	var level_alert := _make_label("!", 22, Color(1.0, 0.12, 0.10))
	level_alert.name = "LevelUpAlert"
	level_alert.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	level_alert.position = Vector2(210, -116)
	level_alert.add_theme_font_size_override("font_size", 25)
	level_alert.visible = false
	root.add_child(level_alert)
	set_meta("level_alert", level_alert)
	skills_button.pressed.connect(_toggle_skills)

	skill_panel = _make_panel(Vector2.ZERO, Vector2(470, 360))
	skill_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# centered popupVector2(20, -490)
	skill_panel.visible = false
	root.add_child(skill_panel)
	var skill_box := VBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 8)
	skill_panel.add_child(skill_box)
	skill_box.add_child(_make_label("ÁRBOL DE HABILIDADES", 22))
	skill_status_label = _make_label("Nivel 1 · 0 puntos", 16)
	skill_box.add_child(skill_status_label)
	for skill in [["agility", "Agilidad · más velocidad"], ["capacity", "Capacidad · +1 espacio"], ["combo", "Combo · mayor bonificación"], ["magnet", "Imán · aspiradora más amplia"]]:
		var skill_button := _make_button(str(skill[1]))
		skill_button.pressed.connect(func(): skill_requested.emit(str(skill[0])))
		skill_box.add_child(skill_button)

	var bestiary_button := _make_button("📖  BESTIARIO")
	bestiary_button.position = Vector2(20, -62)
	bestiary_button.size = Vector2(170, 42)
	bestiary_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bestiary_button.position = Vector2(20, -158)
	root.add_child(bestiary_button)
	shop_obscured_controls.append(bestiary_button)
	bestiary_button.pressed.connect(func(): bestiary_toggled.emit())

	var stats_button := _make_button("ESTADÍSTICAS")
	stats_button.position = Vector2(198, -62)
	stats_button.size = Vector2(150, 42)
	stats_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats_button.position = Vector2(20, -112)
	root.add_child(stats_button)
	shop_obscured_controls.append(stats_button)
	stats_button.pressed.connect(_toggle_stats)

	var menu_button := _make_button("MENÚ")
	menu_button.position = Vector2(356, -62)
	menu_button.size = Vector2(120, 42)
	menu_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu_button.position = Vector2(20, -66)
	root.add_child(menu_button)
	shop_obscured_controls.append(menu_button)
	menu_button.pressed.connect(_toggle_menu)
	menu_panel = _make_panel(Vector2.ZERO, Vector2(440, 300))
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# centered popupVector2(20, -390)
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
	bestiary_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# centered popupVector2(20, -430)
	bestiary_panel.visible = false
	root.add_child(bestiary_panel)
	bestiary_list = VBoxContainer.new()
	bestiary_list.add_theme_constant_override("separation", 10)
	bestiary_panel.add_child(bestiary_list)
	bestiary_list.add_child(_make_label("BESTIARIO DEL BOSQUE", 21))

	stats_panel = _make_panel(Vector2(410, 210), Vector2(430, 250))
	stats_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# centered popupVector2(20, -350)
	stats_panel.visible = false
	root.add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_panel.add_child(stats_box)
	stats_box.add_child(_make_label("RESUMEN DE PARTIDA", 20))
	stats_label = _make_label("Todavía no hay estadísticas.", 16)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_box.add_child(stats_label)

	crosshair = _make_label("+", 30, Color(1.0, 1.0, 1.0, 0.95))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	crosshair.add_theme_constant_override("shadow_offset_x", 2)
	crosshair.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(crosshair)
	shop_obscured_controls.append(crosshair)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if shop_open:
			show_shop(false)
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	is_paused = not is_paused
	if pause_panel:
		pause_panel.visible = is_paused
	if pause_backdrop:
		pause_backdrop.visible = is_paused
	get_tree().paused = is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
	pause_state_changed.emit(is_paused)

func _build_pause_menu(root: Control) -> void:
	pause_backdrop = ColorRect.new()
	var backdrop := pause_backdrop
	backdrop.color = Color(0.015, 0.025, 0.02, 0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(backdrop)
	pause_panel = _make_panel(Vector2.ZERO, Vector2(460, 430))
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	root.add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)
	box.add_child(_make_label("TRUSH · OPCIONES", 24))
	var brightness := HSlider.new()
	brightness.min_value = 0.5
	brightness.max_value = 1.6
	brightness.step = 0.05
	brightness.value = 1.0
	box.add_child(_make_label("Brillo", 15))
	box.add_child(brightness)
	var music := HSlider.new()
	music.min_value = 0.0
	music.max_value = 1.0
	music.step = 0.05
	music.value = 0.8
	box.add_child(_make_label("Volumen de música", 15))
	box.add_child(music)
	var effects := HSlider.new()
	effects.min_value = 0.0
	effects.max_value = 1.0
	effects.step = 0.05
	effects.value = 0.9
	box.add_child(_make_label("Volumen de efectos", 15))
	box.add_child(effects)
	var fov := HSlider.new()
	fov.min_value = 65.0
	fov.max_value = 105.0
	fov.step = 1.0
	fov.value = 80.0
	box.add_child(_make_label("Campo de visión (FOV)", 15))
	box.add_child(fov)
	var apply := func(_value: float = 0.0): options_changed.emit(brightness.value, music.value, effects.value, fov.value)
	brightness.value_changed.connect(apply)
	music.value_changed.connect(apply)
	effects.value_changed.connect(apply)
	fov.value_changed.connect(apply)
	var resume := _make_button("VOLVER AL JUEGO · ESC")
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	backdrop.visible = false
	pause_panel.visible = false

func _process(delta: float) -> void:
	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0:
			var panel := get_meta("notification_panel") as PanelContainer
			if panel:
				panel.visible = false
			var alert := get_meta("level_alert") as Label
			if alert:
				alert.visible = false

func _on_upgrade_pressed(upgrade_id: String) -> void:
	upgrade_requested.emit(upgrade_id)

func update_bag(current: int, capacity: int) -> void:
	bag_label.text = "♧  Bolsa %d / %d" % [current, capacity]
	var fill_percent := int(roundf(100.0 * float(current) / float(maxi(1, capacity))))
	var fill_label := get_meta("bag_fill_label") as Label
	var fill_bar := get_meta("bag_fill_bar") as ProgressBar
	if fill_label:
		fill_label.text = "▱  BOLSA  %d%%" % fill_percent
	if fill_bar:
		fill_bar.value = fill_percent

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
	phase_label.text = "%s  %s  ·  %02d:%02d" % ["☀" if is_day else "☾", "DÍA" if is_day else "NOCHE", int(seconds_left / 60.0), seconds_left % 60]

func update_mission(value: String) -> void:
	mission_label.text = "MISIÓN · " + value

func update_upgrade_prices(costs: Dictionary, levels: Dictionary) -> void:
	for index in range(upgrade_buttons.size()):
		if index >= upgrade_ids.size():
			continue
		var upgrade_id := upgrade_ids[index]
		var price := int(costs.get(upgrade_id, 0))
		var current_level := int(levels.get(upgrade_id, 0))
		var display_name := str(upgrade_names.get(upgrade_id, upgrade_id.capitalize()))
		var detail := str(upgrade_descriptions.get(upgrade_id, "Mejora permanente"))
		if upgrade_id == "discount":
			var current_discount := (1.0 - pow(0.92, float(current_level))) * 100.0
			detail = "Descuento actual: %.1f%%. Al comprar: +8%% multiplicativo." % current_discount
		if upgrade_id == "day":
			detail = "Cada nivel agrega +30 s al día (+14,3%% respecto de los 210 s base)."
		if upgrade_id == "discount":
			var discount_percent := (1.0 - pow(0.92, float(current_level + 1))) * 100.0
			detail = "Este nivel deja los precios un 8%% más bajos. Descuento acumulado tras comprarlo: %.1f%%." % discount_percent
		if upgrade_id == "vacuum":
			detail = "Radio %.1f m · Trayecto %.2f s" % [3.2 + maxf(0.0, float(current_level - 1)) * 0.85, maxf(0.08, 0.24 - maxf(0.0, float(current_level - 1)) * 0.025)]
			upgrade_buttons[index].text = "%s · Nv.%d · %.1f m · $%d" % [display_name, current_level, 3.2 + maxf(0.0, float(current_level - 1)) * 0.85, price]
		else:
			upgrade_buttons[index].text = "%s  ·  Nivel %d  ·  $%d" % [display_name, current_level, price]
		upgrade_buttons[index].tooltip_text = "%s. %s Precio actual: $%d." % [display_name, detail, price]

func notify_level_up(level: int) -> void:
	var alert := get_meta("level_alert") as Label
	if alert:
		alert.visible = true
		alert.text = "! %d" % level
	var panel := get_meta("notification_panel") as PanelContainer
	if panel and message_label:
		message_label.text = "¡SUBISTE AL NIVEL %d!" % level
		panel.visible = true
	message_time_left = 3.2

func update_skill_status(level: int, points: int, levels: Dictionary) -> void:
	if skill_status_label:
		skill_status_label.text = "Nivel %d · %d puntos disponibles\nAgilidad %d · Bolsa %d · Combo %d · Imán %d" % [level, points, int(levels.get("agility", 0)), int(levels.get("capacity", 0)), int(levels.get("combo", 0)), int(levels.get("magnet", 0))]

func toggle_skills() -> void:
	skill_panel.visible = not skill_panel.visible
	if skill_panel.visible:
		close_shop()
	stats_panel.visible = false
	bestiary_panel.visible = false
	menu_panel.visible = false
	if skill_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_skills() -> void:
	toggle_skills()

func show_shop(is_open: bool) -> void:
	shop_open = is_open
	shop_panel.visible = is_open
	for control in shop_obscured_controls:
		control.visible = not is_open
	if is_open:
		bestiary_panel.visible = false
		stats_panel.visible = false
		menu_panel.visible = false
		skill_panel.visible = false
	if is_open:
		skill_panel.visible = false
		bestiary_panel.visible = false
		stats_panel.visible = false
		menu_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED

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

func close_shop() -> void:
	if shop_open:
		show_shop(false)

func toggle_bestiary() -> void:
	bestiary_panel.visible = not bestiary_panel.visible
	if bestiary_panel.visible:
		close_shop()
		stats_panel.visible = false
		menu_panel.visible = false
		skill_panel.visible = false
	stats_panel.visible = false

func _toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	if stats_panel.visible:
		close_shop()
		skill_panel.visible = false
	bestiary_panel.visible = false
	menu_panel.visible = false

func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible
	if menu_panel.visible:
		close_shop()
		skill_panel.visible = false
	stats_panel.visible = false
	bestiary_panel.visible = false
	if menu_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_stats(money: int, collected: int, prestige: int, elapsed_seconds: int) -> void:
	stats_label.text = "Fondos acumulados: $%d\nResiduos recuperados: %d\nPrestigios: %d\nTiempo de sesión: %02d:%02d" % [money, collected, prestige, int(elapsed_seconds / 60.0), elapsed_seconds % 60]

func show_message(message: String) -> void:
	message_label.text = message
	var panel := get_meta("notification_panel") as PanelContainer
	if panel:
		panel.visible = true
	message_time_left = 3.8
