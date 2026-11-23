extends Control
class_name TRushMainMenu

const GAME_SCENE := "res://scenes/main/main.tscn"

var home_panel: PanelContainer
var slots_panel: PanelContainer
var options_panel: PanelContainer
var status_label: Label
var slots_status_label: Label
var profile_name_input: LineEdit
var selected_slot: int = 0
var slot_mode: String = "load"
var confirm_overwrite: ConfirmationDialog
var confirm_delete: ConfirmationDialog
var options_scroll: ScrollContainer
var ui_preview: PanelContainer
var ui_preview_label: Label
var ui_preview_button: Button
var ui_text_inputs: Dictionary = {}
var accent_picker: ColorPickerButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	TRushProfiles.apply_runtime_settings(get_viewport())
	_build_menu()
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 1600.0)
	var height := maxf(size.y, 900.0)
	for band in range(18):
		var blend := float(band) / 17.0
		draw_rect(Rect2(0.0, blend * height, width, height / 18.0 + 1.0), Color(0.10, 0.21, 0.20).lerp(Color(0.04, 0.11, 0.085), blend), true)
	draw_circle(Vector2(width * 0.80, height * 0.20), 58.0, Color(0.91, 0.76, 0.46, 0.84), true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, height * 0.57), Vector2(width * 0.27, height * 0.28), Vector2(width * 0.53, height * 0.62), Vector2(width * 0.72, height * 0.38), Vector2(width, height * 0.61), Vector2(width, height), Vector2(0, height)]), Color(0.12, 0.26, 0.18, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(0, height * 0.74), Vector2(width * 0.32, height * 0.54), Vector2(width * 0.62, height * 0.76), Vector2(width, height * 0.58), Vector2(width, height), Vector2(0, height)]), Color(0.08, 0.19, 0.13, 0.98))
	for tree_index in range(24):
		var x := float(tree_index) * width / 23.0
		var y := height * (0.71 + 0.10 * sin(float(tree_index) * 1.7))
		var tree_height := 68.0 + fposmod(float(tree_index * 41), 92.0)
		draw_rect(Rect2(x - 3.0, y, 6.0, tree_height), Color(0.07, 0.13, 0.095, 0.95), true)
		draw_circle(Vector2(x, y - 16.0), 19.0 + fposmod(float(tree_index * 17), 13.0), Color(0.10, 0.25 + fposmod(float(tree_index), 4.0) * 0.025, 0.15, 0.92), true)

func _build_menu() -> void:
	home_panel = _make_panel(Vector2(36.0, -360.0), Vector2(500.0, 720.0))
	home_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	home_panel.anchor_top = 0.5
	home_panel.anchor_bottom = 0.5
	home_panel.offset_left = 36.0
	home_panel.offset_right = 536.0
	home_panel.offset_top = -360.0
	home_panel.offset_bottom = 360.0
	add_child(home_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 18)
	box.add_theme_constant_override("margin_bottom", 18)
	home_panel.add_child(box)
	var title := _label("TRush", 54, Color(0.86, 0.94, 0.75))
	box.add_child(title)
	box.add_child(_label("RESTAURAR · EXPLORAR · RENACER", 14, Color(0.76, 0.85, 0.72)))
	box.add_child(HSeparator.new())
	var intro := _label("Un bosque vivo espera. Recorre sus regiones, recupera lo que se perdió y ayuda a que la fauna vuelva.", 17)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(intro)
	box.add_spacer(false)
	var new_button := _button("INICIAR PARTIDA NUEVA")
	new_button.pressed.connect(func(): _open_slots("new"))
	box.add_child(new_button)
	var load_button := _button("CARGAR PARTIDA")
	load_button.pressed.connect(func(): _open_slots("load"))
	box.add_child(load_button)
	var options_button := _button("OPCIONES")
	options_button.pressed.connect(_open_options)
	box.add_child(options_button)
	var quit_button := _button("SALIR")
	quit_button.pressed.connect(get_tree().quit)
	box.add_child(quit_button)
	status_label = _label("", 13, Color(1.0, 0.72, 0.55))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)
	var footer := _label("BOSQUE TEMPLADO · ESTACIÓN DE RESTAURACIÓN", 11, Color(0.63, 0.74, 0.63))
	box.add_child(footer)
	_build_slots_panel()
	_build_options_panel()
	confirm_overwrite = ConfirmationDialog.new()
	confirm_overwrite.title = "Reemplazar perfil"
	confirm_overwrite.dialog_text = "Este espacio contiene una partida. ¿Quieres reemplazarla?"
	confirm_overwrite.confirmed.connect(_confirm_new_profile)
	add_child(confirm_overwrite)
	confirm_delete = ConfirmationDialog.new()
	confirm_delete.title = "Eliminar perfil"
	confirm_delete.confirmed.connect(_confirm_delete_profile)
	add_child(confirm_delete)

func _build_slots_panel() -> void:
	slots_panel = _make_panel(Vector2.ZERO, Vector2(550.0, 535.0))
	slots_panel.set_anchors_preset(Control.PRESET_CENTER)
	slots_panel.offset_left = -275.0
	slots_panel.offset_right = 275.0
	slots_panel.offset_top = -268.0
	slots_panel.offset_bottom = 268.0
	add_child(slots_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	slots_panel.add_child(box)
	box.add_child(_label("ESPACIOS DE PARTIDA", 25))
	box.add_child(_label("Tres perfiles locales e independientes", 14, Color(0.71, 0.82, 0.72)))
	profile_name_input = LineEdit.new()
	profile_name_input.placeholder_text = "Nombre del perfil · hasta 20 caracteres"
	profile_name_input.max_length = 20
	box.add_child(profile_name_input)
	var list := VBoxContainer.new()
	list.name = "SlotList"
	list.add_theme_constant_override("separation", 9)
	box.add_child(list)
	var back := _button("VOLVER")
	back.pressed.connect(_show_home)
	box.add_child(back)
	slots_status_label = _label("", 13, Color(1.0, 0.72, 0.55))
	slots_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(slots_status_label)
	slots_panel.visible = false

func _build_options_panel() -> void:
	options_panel = _make_panel(Vector2.ZERO, Vector2(640.0, 760.0))
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -320.0
	options_panel.offset_right = 320.0
	options_panel.offset_top = -380.0
	options_panel.offset_bottom = 380.0
	add_child(options_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	options_panel.add_child(outer)
	outer.add_child(_label("OPCIONES", 28))
	options_scroll = ScrollContainer.new()
	options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(options_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	options_scroll.add_child(content)
	content.add_child(_label("AUDIO Y JUGABILIDAD", 17, Color(0.76, 0.87, 0.71)))
	_add_slider(content, "Volumen maestro", "master_volume", 0.0, 1.0, 0.05, true)
	_add_slider(content, "Música", "music_volume", 0.0, 1.0, 0.05, true)
	_add_slider(content, "Efectos", "effects_volume", 0.0, 1.0, 0.05, true)
	_add_slider(content, "Sensibilidad del ratón", "mouse_sensitivity", 0.0004, 0.008, 0.0002, false)
	_add_slider(content, "Brillo", "brightness", 0.5, 1.6, 0.05, false)
	_add_slider(content, "Campo de visión", "fov", 65.0, 105.0, 1.0, false)
	_add_choice(content, "Calidad gráfica", "quality", ["Baja", "Media", "Alta"], ["low", "medium", "high"])
	_add_choice(content, "Resolución de ventana", "resolution", ["1280 × 720", "1600 × 900", "1920 × 1080"], [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)])
	var fullscreen := CheckButton.new()
	fullscreen.text = "Pantalla completa"
	fullscreen.button_pressed = bool(TRushProfiles.get_setting("fullscreen", false))
	fullscreen.toggled.connect(func(enabled: bool):
		TRushProfiles.set_setting("fullscreen", enabled)
		TRushProfiles.apply_runtime_settings(get_viewport())
	)
	content.add_child(fullscreen)
	content.add_child(HSeparator.new())
	content.add_child(_label("MODIFICAR UI", 19, Color(0.76, 0.87, 0.71)))
	content.add_child(_label("Personaliza textos, tamaño y tema. Los cambios se guardan para todos los perfiles en user://trush_settings.cfg.", 12, Color(0.72, 0.78, 0.70)))
	content.add_child(_label("Texto de ayuda", 13))
	var help_text := LineEdit.new()
	help_text.text = TRushProfiles.get_ui_text("help")
	help_text.max_length = 54
	ui_text_inputs["help"] = help_text
	help_text.text_submitted.connect(func(value: String):
		TRushProfiles.set_ui_text("help", value)
		_refresh_preview()
	)
	help_text.focus_exited.connect(func():
		TRushProfiles.set_ui_text("help", help_text.text)
		_refresh_preview()
	)
	content.add_child(help_text)
	for key in ["recycle", "shop", "rest"]:
		var readable: String = {"recycle": "Rótulo de reciclaje", "shop": "Rótulo de tienda", "rest": "Rótulo de descanso"}[key]
		content.add_child(_label(readable, 13))
		var text_input := LineEdit.new()
		text_input.text = TRushProfiles.get_ui_text(key).replace("\n", " ")
		text_input.max_length = 40
		ui_text_inputs[key] = text_input
		text_input.text_submitted.connect(_save_ui_text.bind(key))
		text_input.focus_exited.connect(_save_focused_ui_text.bind(key, text_input))
		content.add_child(text_input)
	_add_slider(content, "Tamaño de texto", "ui_font_scale", 0.8, 1.2, 0.05, false)
	_add_choice(content, "Estilo de paneles", "ui_theme", ["Bosque", "Noche", "Claro"], ["forest", "night", "light"])
	var accent_row := HBoxContainer.new()
	accent_row.add_child(_label("Color de acento", 13))
	accent_picker = ColorPickerButton.new()
	accent_picker.color = TRushProfiles.get_setting("ui_accent_color", Color(0.42, 0.67, 0.40))
	accent_picker.color_changed.connect(func(color: Color):
		TRushProfiles.set_setting("ui_accent_color", color)
		_refresh_preview()
	)
	accent_row.add_child(accent_picker)
	content.add_child(accent_row)
	ui_preview = _make_panel(Vector2.ZERO, Vector2(0.0, 82.0))
	ui_preview.custom_minimum_size.y = 82.0
	content.add_child(ui_preview)
	var preview_box := VBoxContainer.new()
	ui_preview.add_child(preview_box)
	ui_preview_label = _label("Vista previa de TRush", 16)
	preview_box.add_child(ui_preview_label)
	ui_preview_button = _button("RECICLAR · E")
	preview_box.add_child(ui_preview_button)
	var reset := _button("RESTABLECER PERSONALIZACIÓN")
	reset.pressed.connect(func():
		TRushProfiles.reset_ui_customization()
		for text_key in ui_text_inputs:
			(ui_text_inputs[text_key] as LineEdit).text = TRushProfiles.get_ui_text(str(text_key)).replace("\n", " ")
		accent_picker.color = TRushProfiles.get_setting("ui_accent_color", Color(0.42, 0.67, 0.40))
		_refresh_preview()
	)
	content.add_child(reset)
	var back := _button("VOLVER")
	back.pressed.connect(_show_home)
	outer.add_child(back)
	options_panel.visible = false
	_refresh_preview()

func _open_slots(mode: String) -> void:
	slot_mode = mode
	selected_slot = 0
	status_label.text = ""
	slots_status_label.text = ""
	home_panel.visible = false
	slots_panel.visible = true
	options_panel.visible = false
	profile_name_input.visible = mode == "new"
	profile_name_input.text = ""
	var list := slots_panel.find_child("SlotList", true, false) as VBoxContainer
	for child in list.get_children():
		child.queue_free()
	for summary in TRushProfiles.get_slot_summaries():
		var slot_id := int(summary["slot"])
		var text := "ESPACIO %d  ·  %s" % [slot_id, str(summary["name"])]
		if bool(summary["occupied"]):
			text += "\n$%d   ·   Bosque restaurado %d%%" % [int(summary["money"]), int(summary["cleanup"])]
		else:
			text += "\nPartida nueva disponible"
		var slot_row := HBoxContainer.new()
		slot_row.add_theme_constant_override("separation", 8)
		list.add_child(slot_row)
		var button := _button(text)
		button.custom_minimum_size.y = 76.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = mode == "load" and (not bool(summary["occupied"]) or not bool(summary["valid"]))
		button.pressed.connect(_select_slot.bind(slot_id, bool(summary["occupied"])))
		slot_row.add_child(button)
		var delete_button := _button("ELIMINAR")
		delete_button.custom_minimum_size = Vector2(108.0, 76.0)
		delete_button.disabled = not bool(summary["occupied"])
		delete_button.pressed.connect(_request_delete_slot.bind(slot_id, str(summary["name"])))
		slot_row.add_child(delete_button)

func _select_slot(slot_id: int, occupied: bool) -> void:
	selected_slot = slot_id
	if slot_mode == "load":
		if not TRushProfiles.activate_slot(slot_id):
			slots_status_label.text = TRushProfiles.last_error
			return
		get_tree().change_scene_to_file(GAME_SCENE)
		return
	if occupied:
		confirm_overwrite.dialog_text = "El espacio %d ya contiene progreso. Reemplazarlo borrará solo ese perfil. ¿Continuar?" % slot_id
		confirm_overwrite.popup_centered()
	else:
		_confirm_new_profile()

func _confirm_new_profile() -> void:
	if selected_slot <= 0:
		return
	var occupied := FileAccess.file_exists(TRushProfiles.slot_path(selected_slot))
	if not TRushProfiles.create_profile(selected_slot, profile_name_input.text, occupied):
		slots_status_label.text = TRushProfiles.last_error
		return
	get_tree().change_scene_to_file(GAME_SCENE)

func _request_delete_slot(slot_id: int, profile_name: String) -> void:
	selected_slot = slot_id
	confirm_delete.dialog_text = "¿Eliminar «%s» del espacio %d? Esta acción borra solo ese perfil local." % [profile_name, slot_id]
	confirm_delete.popup_centered()

func _confirm_delete_profile() -> void:
	if not TRushProfiles.delete_profile(selected_slot, true):
		slots_status_label.text = TRushProfiles.last_error
		return
	_open_slots(slot_mode)
	slots_status_label.text = "Perfil eliminado."

func _open_options() -> void:
	home_panel.visible = false
	slots_panel.visible = false
	options_panel.visible = true
	status_label.text = ""
	_refresh_preview()

func _show_home() -> void:
	home_panel.visible = true
	slots_panel.visible = false
	options_panel.visible = false

func _add_slider(parent: VBoxContainer, title: String, key: String, minimum: float, maximum: float, step: float, is_volume: bool) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(title, 13))
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = float(TRushProfiles.get_setting(key, minimum))
	var value_label := _label("%.2f" % slider.value, 12, Color(0.75, 0.85, 0.73))
	row.add_child(slider)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float):
		value_label.text = "%.2f" % value
		TRushProfiles.set_setting(key, value)
		TRushProfiles.apply_runtime_settings(get_viewport())
		if key.begins_with("ui_"):
			_refresh_preview()
	)
	parent.add_child(row)

func _add_choice(parent: VBoxContainer, title: String, key: String, labels: Array, values: Array) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(title, 13))
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in range(labels.size()):
		option.add_item(str(labels[index]), index)
		if values[index] == TRushProfiles.get_setting(key):
			option.select(index)
	option.item_selected.connect(func(index: int):
		TRushProfiles.set_setting(key, values[index])
		TRushProfiles.apply_runtime_settings(get_viewport())
		_refresh_preview()
	)
	row.add_child(option)
	parent.add_child(row)

func _refresh_preview() -> void:
	if ui_preview_label == null:
		return
	var scale_value := float(TRushProfiles.get_setting("ui_font_scale", 1.0))
	var theme_name := str(TRushProfiles.get_setting("ui_theme", "forest"))
	var colors := _theme_colors(theme_name)
	ui_preview_label.add_theme_font_size_override("font_size", roundi(16.0 * scale_value))
	ui_preview_label.text = TRushProfiles.get_ui_text("help")
	ui_preview_button.text = TRushProfiles.get_ui_text("recycle").replace("\n", " · ")
	ui_preview_button.add_theme_color_override("font_color", colors["text"])
	var style := StyleBoxFlat.new()
	style.bg_color = colors["panel"]
	style.border_color = TRushProfiles.get_setting("ui_accent_color", Color(0.42, 0.67, 0.40))
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	ui_preview.add_theme_stylebox_override("panel", style)

func _theme_colors(theme_name: String) -> Dictionary:
	match theme_name:
		"night": return {"panel": Color(0.08, 0.12, 0.18, 0.97), "text": Color(0.78, 0.91, 0.96)}
		"light": return {"panel": Color(0.76, 0.79, 0.67, 0.97), "text": Color(0.08, 0.14, 0.10)}
		_: return {"panel": Color(0.10, 0.18, 0.13, 0.97), "text": Color(0.86, 0.94, 0.78)}

func _make_panel(panel_position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var theme_name := str(TRushProfiles.get_setting("ui_theme", "forest"))
	style.bg_color = Color(0.075, 0.10, 0.16, 0.95) if theme_name == "night" else Color(0.70, 0.76, 0.64, 0.95) if theme_name == "light" else Color(0.055, 0.105, 0.073, 0.93)
	style.border_color = TRushProfiles.get_setting("ui_accent_color", Color(0.44, 0.61, 0.40, 0.75))
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 48.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", roundi(16.0 * float(TRushProfiles.get_setting("ui_font_scale", 1.0))))
	var normal := StyleBoxFlat.new()
	var theme_name := str(TRushProfiles.get_setting("ui_theme", "forest"))
	normal.bg_color = Color(0.13, 0.20, 0.30, 0.98) if theme_name == "night" else Color(0.83, 0.85, 0.75, 0.98) if theme_name == "light" else Color(0.12, 0.25, 0.16, 0.98)
	normal.border_color = TRushProfiles.get_setting("ui_accent_color", Color(0.41, 0.62, 0.37, 0.85))
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_color_override("font_color", Color(0.10, 0.14, 0.10) if theme_name == "light" else Color(0.88, 0.95, 0.82))
	return button

func _label(text_value: String, font_size: int, color: Color = Color(0.91, 0.95, 0.89)) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", roundi(font_size * float(TRushProfiles.get_setting("ui_font_scale", 1.0))))
	var theme_color := color
	if str(TRushProfiles.get_setting("ui_theme", "forest")) == "light" and color.r > 0.45 and color.g > 0.45 and color.b > 0.40:
		theme_color = Color(0.12, 0.16, 0.12)
	label.add_theme_color_override("font_color", theme_color)
	return label

func _save_ui_text(value: String, key: String) -> void:
	TRushProfiles.set_ui_text(key, value)
	_refresh_preview()

func _save_focused_ui_text(key: String, input: LineEdit) -> void:
	TRushProfiles.set_ui_text(key, input.text)
	_refresh_preview()
