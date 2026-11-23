extends CanvasLayer
class_name TRushHUD

signal options_changed(brightness: float, music_volume: float, effects_volume: float, fov: float, quality_level: int)
signal pause_state_changed(is_paused: bool)
signal upgrade_requested(upgrade_id: String)
signal prestige_requested
signal prestige_confirmed
signal skill_requested(skill_id: String)
signal bestiary_toggled
signal cleaner_collect_requested
signal cleaner_toggle_requested

const BAG_TEXTURE_PATH := "res://assets/ui/bag_silhouette.svg"
const BAG_SHADER_PATH := "res://shaders/bag_fill.gdshader"

const MINIMAP_SCRIPT := preload("res://scripts/ui/minimap.gd")

var money_label: Label
var progress_label: Label
<<<<<<< Updated upstream
var health_label: Label
var health_bar: ProgressBar
=======
var daily_cleanup_label: Label
>>>>>>> Stashed changes
var phase_label: Label
var message_label: Label
var mission_label: Label
var stats_label: Label
var upgrade_buttons: Array[Button] = []
var upgrade_ids: Array[String] = []
<<<<<<< Updated upstream
var upgrade_title_labels: Array[Label] = []
var upgrade_detail_labels: Array[Label] = []
var shop_balance_label: Label
var upgrade_descriptions := {"speed": "Movimiento más rápido", "capacity": "+2 espacios de bolsa", "value": "Más ingresos por residuo", "range": "Mayor alcance manual", "day": "Más duración del día", "vacuum": "Amplía el radio y acelera el viaje del residuo a la boquilla", "discount": "Reduce otros costos"}
var upgrade_names := {"speed": "Velocidad", "capacity": "Bolsa", "value": "Valor reciclado", "range": "Alcance manual", "day": "Duración del día", "vacuum": "Aspiradora", "discount": "Descuento"}
=======
var upgrade_descriptions := {"speed": "Movimiento más rápido", "capacity": "+2 espacios de bolsa", "value": "Más ingresos por residuo", "range": "Mayor alcance manual", "day": "Más duración del día", "vacuum": "Evoluciona el equipo; máximo 10 niveles", "discount": "Reduce otros costos", "daily_quota": "+25 residuos ordinarios en cada mañana nueva"}
var upgrade_names := {"speed": "Velocidad", "capacity": "Bolsa", "value": "Valor reciclado", "range": "Alcance manual", "day": "Duración del día", "vacuum": "Aspiradora", "discount": "Descuento", "daily_quota": "Cantidad de basura diaria"}
>>>>>>> Stashed changes
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
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_health_label: Label
var boss_health_bar: ProgressBar
var boss_health_stage: int = -1
var player_health_label: Label
var player_health_bar: ProgressBar
var fruit_boost_label: Label
var minimap: TRushMinimap
var damage_overlay: ColorRect
var damage_indicator: Label
var bag_fill_texture: TextureRect
var bag_count_label: Label
var bag_fill_material: ShaderMaterial
var bag_fill_tween: Tween
var boss_acquisition_panel: PanelContainer
var boss_acquisition_label: Label
var boss_acquisition_tween: Tween
var cleaner_context_label: Label
var cleaner_shop_status_label: Label
var cleaner_purchase_button: Button
var cleaner_income_button: Button
var cleaner_storage_button: Button
var cleaner_panel: PanelContainer
var cleaner_status_label: Label
var cleaner_income_label: Label
var cleaner_storage_label: Label
var cleaner_fill_bar: ProgressBar
var cleaner_collect_button: Button
var cleaner_toggle_button: Button
var upgrade_access_enabled: bool = true
var cleaner_shop_state: Dictionary = {}
var cleaner_shop_money: int = 0
var cleaner_purchase_price: int = 0
var cleaner_income_cost: int = -1
var cleaner_storage_cost: int = -1
var cleaner_next_income: int = 0
var cleaner_next_capacity: int = 0
var prestige_menu_button: Button
var prestige_overlay: Control
var prestige_points_label: Label
var prestige_history_label: Label
var prestige_confirmation_dialog: ConfirmationDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_pause_menu(root)

<<<<<<< Updated upstream
	var status_panel := _make_panel(Vector2(22, 20), Vector2(370, 226))
=======
	var status_panel := _make_panel(Vector2(22, 20), Vector2(370, 238))
>>>>>>> Stashed changes
	root.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 7)
	status_panel.add_child(status_box)
	money_label = _make_label("✦  $0", 23)
	progress_label = _make_label("Bosque 0% restaurado", 17)
	phase_label = _make_label("☀  DÍA", 17)
	mission_label = _make_label("MISIÓN · Recolecta y recicla residuos", 14)
	for label in [money_label, progress_label, phase_label, mission_label]:
		status_box.add_child(label)
<<<<<<< Updated upstream
	health_label = _make_label("VIDA  100 / 100", 16, Color(1.0, 0.82, 0.72))
	status_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(320, 15)
	status_box.add_child(health_bar)
	var bag_widget := _make_panel(Vector2(-190, -92), Vector2(170, 68))
=======
	daily_cleanup_label = _make_label("RESIDUOS DEL DÍA · 0 / 200", 14, Color(0.76, 0.89, 0.70))
	status_box.add_child(daily_cleanup_label)
	prestige_menu_button = _make_button("PUNTOS DE PRESTIGIO · 0")
	prestige_menu_button.visible = false
	prestige_menu_button.pressed.connect(toggle_prestige_menu)
	status_box.add_child(prestige_menu_button)
	_build_prestige_interface(root)
	boss_panel = _make_panel(Vector2.ZERO, Vector2(470, 98))
	boss_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -235
	boss_panel.offset_right = 235
	boss_panel.offset_top = 20
	boss_panel.offset_bottom = 118
	boss_panel.visible = false
	root.add_child(boss_panel)
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 4)
	boss_name_label = _make_label("JEFE", 18)
	boss_health_label = _make_label("Salud", 12, Color(0.77, 0.84, 0.77))
	boss_health_bar = ProgressBar.new()
	boss_health_bar.min_value = 0.0
	boss_health_bar.max_value = 100.0
	boss_health_bar.show_percentage = false
	boss_health_bar.custom_minimum_size = Vector2(410, 16)
	boss_box.add_child(boss_name_label)
	boss_box.add_child(boss_health_bar)
	boss_box.add_child(boss_health_label)
	boss_panel.add_child(boss_box)
	var bag_widget := Control.new()
>>>>>>> Stashed changes
	bag_widget.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bag_widget.offset_left = -206.0
	bag_widget.offset_top = -202.0
	bag_widget.offset_right = -20.0
	bag_widget.offset_bottom = -18.0
	root.add_child(bag_widget)
	var bag_backdrop := _make_panel(Vector2.ZERO, Vector2.ZERO)
	bag_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_widget.add_child(bag_backdrop)
	var bag_image := TextureRect.new()
	bag_image.name = "BagSilhouetteFill"
	bag_image.texture = load(BAG_TEXTURE_PATH) as Texture2D
	bag_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bag_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_image.offset_left = 14.0
	bag_image.offset_top = 3.0
	bag_image.offset_right = -14.0
	bag_image.offset_bottom = -8.0
	bag_fill_material = ShaderMaterial.new()
	bag_fill_material.shader = load(BAG_SHADER_PATH) as Shader
	bag_fill_material.set_shader_parameter("fill_ratio", 0.0)
	bag_image.material = bag_fill_material
	bag_widget.add_child(bag_image)
	bag_fill_texture = bag_image
	bag_count_label = _make_label("0 / 5", 23, Color(0.98, 0.97, 0.86))
	bag_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bag_count_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.08, 0.055, 0.98))
	bag_count_label.add_theme_constant_override("shadow_offset_x", 2)
	bag_count_label.add_theme_constant_override("shadow_offset_y", 2)
	bag_count_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_count_label.offset_left = 18.0
	bag_count_label.offset_top = 53.0
	bag_count_label.offset_right = -18.0
	bag_count_label.offset_bottom = -40.0
	bag_widget.add_child(bag_count_label)
	var bag_title := _make_label("BOLSA", 12, Color(0.84, 0.91, 0.78))
	bag_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bag_title.offset_left = 12.0
	bag_title.offset_right = -12.0
	bag_title.offset_top = -27.0
	bag_title.offset_bottom = -7.0
	bag_widget.add_child(bag_title)
	var health_panel := _make_panel(Vector2(22, -142), Vector2(284, 68))
	health_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(health_panel)
	var health_box := VBoxContainer.new()
	health_box.add_theme_constant_override("separation", 3)
	health_panel.add_child(health_box)
	player_health_label = _make_label("♥  SALUD  100 / 100", 15, Color(0.91, 0.84, 0.72))
	health_box.add_child(player_health_label)
	player_health_bar = ProgressBar.new()
	player_health_bar.min_value = 0.0
	player_health_bar.max_value = 100.0
	player_health_bar.show_percentage = false
	player_health_bar.custom_minimum_size = Vector2(246, 13)
	health_box.add_child(player_health_bar)
	fruit_boost_label = _make_label("Sin efecto de fruta", 11, Color(0.74, 0.86, 0.60))
	health_box.add_child(fruit_boost_label)
	minimap = MINIMAP_SCRIPT.new() as TRushMinimap
	minimap.name = "WorldMinimap"
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -258.0
	minimap.offset_right = -20.0
	minimap.offset_top = 20.0
	minimap.offset_bottom = 242.0
	root.add_child(minimap)

	var shop_center := CenterContainer.new()
	shop_center.name = "ShopCenterContainer"
	shop_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_center.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shop_center)
<<<<<<< Updated upstream
	var upgrades_panel := _make_panel(Vector2.ZERO, Vector2(720, 620))
	upgrades_panel.custom_minimum_size = Vector2(720, 620)
=======
	var shop_height := minf(650.0, maxf(430.0, get_viewport().get_visible_rect().size.y - 48.0))
	var upgrades_panel := _make_panel(Vector2.ZERO, Vector2(520, shop_height))
	upgrades_panel.custom_minimum_size = Vector2(520, shop_height)
>>>>>>> Stashed changes
	shop_center.add_child(upgrades_panel)
	shop_center.visible = false
	shop_panel = shop_center
	var shop_outer := VBoxContainer.new()
	shop_outer.add_theme_constant_override("separation", 6)
	upgrades_panel.add_child(shop_outer)
	shop_outer.add_child(_make_label("TALLER DE MEJORAS", 18))
	shop_outer.add_child(_make_label("Disponible durante la noche · Mejora tu equipo", 12, Color(0.70, 0.79, 0.72)))
	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_outer.add_child(shop_scroll)
	var upgrade_box := VBoxContainer.new()
<<<<<<< Updated upstream
	upgrade_box.add_theme_constant_override("separation", 10)
	upgrades_panel.add_child(upgrade_box)
	var shop_header := HBoxContainer.new()
	shop_header.add_theme_constant_override("separation", 12)
	upgrade_box.add_child(shop_header)
	var shop_heading := _make_label("MERCADO DEL GUARDABOSQUES", 24, Color(0.91, 0.96, 0.84))
	shop_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_header.add_child(shop_heading)
	shop_balance_label = _make_label("SALDO  $0", 19, Color(0.91, 0.82, 0.48))
	shop_header.add_child(shop_balance_label)
	upgrade_box.add_child(_make_label("Invierte lo que recuperas. Cada mejora fortalece tu próxima expedición.", 14, Color(0.70, 0.81, 0.72)))
	var shop_section := _make_label("EQUIPAMIENTO Y MEJORAS PERMANENTES", 12, Color(0.54, 0.77, 0.58))
	shop_section.add_theme_font_size_override("font_size", 12)
	upgrade_box.add_child(shop_section)
	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.custom_minimum_size = Vector2(0, 360)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	upgrade_box.add_child(shop_scroll)
	var shop_items := VBoxContainer.new()
	shop_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_items.add_theme_constant_override("separation", 8)
	shop_scroll.add_child(shop_items)
	var upgrade_data := [
		["speed", "Botas de explorador", "Aumenta tu velocidad al caminar y correr."],
		["capacity", "Mochila reforzada", "Amplía la capacidad de residuos que puedes transportar."],
		["value", "Prensa de reciclaje", "Mejora el valor de cada entrega en la estación."],
		["range", "Guantes de alcance", "Recoge residuos desde una distancia mayor."],
		["day", "Jornada extendida", "Añade tiempo útil a cada día de trabajo."],
		["vacuum", "Aspiradora ecológica", "Aumenta el radio y la velocidad de succión · F."],
		["discount", "Convenio de suministros", "Reduce el costo de futuras mejoras."]
=======
	upgrade_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_box.add_theme_constant_override("separation", 6)
	shop_scroll.add_child(upgrade_box)
	var upgrade_data := [
		["speed", "Velocidad", "Movimiento más rápido"],
		["capacity", "Bolsa", "+2 unidades de capacidad"],
		["value", "Reciclaje", "Más ingresos por residuo"],
		["range", "Alcance", "Recogida a más distancia"],
		["day", "Turno", "Más tiempo de trabajo"],
		["vacuum", "Aspiradora", "Radio y velocidad de succión · F"],
		["discount", "Ahorro", "Reduce progresivamente otros costos"],
		["daily_quota", "Basura diaria", "+25 residuos ordinarios por día"]
>>>>>>> Stashed changes
	]
	for item in upgrade_data:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 68)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.075, 0.145, 0.105, 0.96)
		card_style.border_color = Color(0.24, 0.39, 0.27, 0.9)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(12)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 7
		card_style.content_margin_bottom = 7
		card.add_theme_stylebox_override("panel", card_style)
		shop_items.add_child(card)
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 12)
		card.add_child(card_row)
		var card_copy := VBoxContainer.new()
		card_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_copy.add_theme_constant_override("separation", 2)
		card_row.add_child(card_copy)
		var title_label := _make_label(str(item[1]), 16, Color(0.91, 0.95, 0.87))
		card_copy.add_child(title_label)
		var detail_label := _make_label(str(item[2]), 12, Color(0.68, 0.78, 0.69))
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_copy.add_child(detail_label)
		var button := _make_button("MEJORAR")
		button.custom_minimum_size = Vector2(150, 48)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(_on_upgrade_pressed.bind(item[0]))
		card_row.add_child(button)
		upgrade_buttons.append(button)
		upgrade_ids.append(str(item[0]))
<<<<<<< Updated upstream
		upgrade_title_labels.append(title_label)
		upgrade_detail_labels.append(detail_label)
	var shop_footer := HBoxContainer.new()
	shop_footer.add_theme_constant_override("separation", 10)
	upgrade_box.add_child(shop_footer)
	var shop_close_button := _make_button("VOLVER AL BOSQUE  ·  ESC")
	shop_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
=======
	upgrade_box.add_child(HSeparator.new())
	upgrade_box.add_child(_make_label("LIMPIEZA AUTOMÁTICA", 16, Color(0.76, 0.87, 0.71)))
	cleaner_shop_status_label = _make_label("Aún no tienes la limpiadora portable.", 12, Color(0.76, 0.83, 0.73))
	cleaner_shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_box.add_child(cleaner_shop_status_label)
	cleaner_purchase_button = _make_button("Limpiadora Automática Portable · $5200")
	cleaner_purchase_button.custom_minimum_size.y = 48.0
	cleaner_purchase_button.pressed.connect(_on_upgrade_pressed.bind("cleaner_purchase"))
	upgrade_box.add_child(cleaner_purchase_button)
	cleaner_income_button = _make_button("Mejora de $ por minuto · requiere instalar máquina")
	cleaner_income_button.custom_minimum_size.y = 48.0
	cleaner_income_button.pressed.connect(_on_upgrade_pressed.bind("cleaner_income"))
	upgrade_box.add_child(cleaner_income_button)
	cleaner_storage_button = _make_button("Capacidad de almacenamiento · requiere instalar máquina")
	cleaner_storage_button.custom_minimum_size.y = 48.0
	cleaner_storage_button.pressed.connect(_on_upgrade_pressed.bind("cleaner_storage"))
	upgrade_box.add_child(cleaner_storage_button)
	var shop_close_button := _make_button("CERRAR TIENDA · ESC")
>>>>>>> Stashed changes
	shop_close_button.pressed.connect(func(): show_shop(false))
	shop_footer.add_child(shop_close_button)
	var prestige_button := _make_button("✧  PRESTIGIO")
	prestige_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prestige_button.pressed.connect(func(): prestige_requested.emit())
<<<<<<< Updated upstream
	shop_footer.add_child(prestige_button)
=======
	upgrade_box.add_child(prestige_button)
	_build_cleaner_management(root)
	_build_boss_acquisition_intro(root)
	_build_cleaner_context(root)
>>>>>>> Stashed changes

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
	var help := _make_label(TRushProfiles.get_ui_text("help"), 13)
	help.name = "CustomizableHelpLabel"
	help.position = Vector2(12, 11)
	help_panel.add_child(help)
	set_meta("customizable_help", help)

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
	damage_overlay = ColorRect.new()
	damage_overlay.name = "DamageFlash"
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.color = Color(0.8, 0.035, 0.015, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_overlay)
	damage_indicator = _make_label("✕", 34, Color(1.0, 0.25, 0.16))
	damage_indicator.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	damage_indicator.position = Vector2(-11.0, 12.0)
	damage_indicator.visible = false
	root.add_child(damage_indicator)

func _make_panel(position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = size_value
	var style := StyleBoxFlat.new()
	var theme_name := str(TRushProfiles.get_setting("ui_theme", "forest"))
	style.bg_color = Color(0.075, 0.11, 0.16, 0.94) if theme_name == "night" else Color(0.72, 0.77, 0.67, 0.94) if theme_name == "light" else Color(0.055, 0.105, 0.085, 0.91)
	style.border_color = TRushProfiles.get_setting("ui_accent_color", Color(0.36, 0.57, 0.39, 0.85))
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
	button.add_theme_font_size_override("font_size", roundi(14.0 * float(TRushProfiles.get_setting("ui_font_scale", 1.0))))
	var normal := StyleBoxFlat.new()
	var theme_name := str(TRushProfiles.get_setting("ui_theme", "forest"))
	normal.bg_color = Color(0.075, 0.11, 0.16, 0.98) if theme_name == "night" else Color(0.80, 0.83, 0.73, 0.98) if theme_name == "light" else Color(0.13, 0.24, 0.18, 0.98)
	normal.border_color = TRushProfiles.get_setting("ui_accent_color", Color(0.32, 0.48, 0.34))
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
	if theme_name == "light":
		button.add_theme_color_override("font_color", Color(0.10, 0.14, 0.10))
	return button

func _make_label(value: String, font_size: int, color: Color = Color(0.91, 0.95, 0.89)) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", roundi(font_size * float(TRushProfiles.get_setting("ui_font_scale", 1.0))))
	var theme_color := color
	if str(TRushProfiles.get_setting("ui_theme", "forest")) == "light" and color.r > 0.45 and color.g > 0.45 and color.b > 0.40:
		theme_color = Color(0.12, 0.16, 0.12)
	label.add_theme_color_override("font_color", theme_color)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if shop_open:
			show_shop(false)
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if cleaner_panel and cleaner_panel.visible:
		show_cleaner_management(false)
		return
	is_paused = not is_paused
	if pause_panel:
		pause_panel.visible = is_paused
	if pause_backdrop:
		pause_backdrop.visible = is_paused
	get_tree().paused = is_paused
	if is_paused:
		hide_boss()
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
	brightness.value = float(TRushProfiles.get_setting("brightness", 1.0))
	box.add_child(_make_label("Brillo", 15))
	box.add_child(brightness)
	var music := HSlider.new()
	music.min_value = 0.0
	music.max_value = 1.0
	music.step = 0.05
	music.value = float(TRushProfiles.get_setting("music_volume", 0.8))
	box.add_child(_make_label("Volumen de música", 15))
	box.add_child(music)
	var effects := HSlider.new()
	effects.min_value = 0.0
	effects.max_value = 1.0
	effects.step = 0.05
	effects.value = float(TRushProfiles.get_setting("effects_volume", 0.9))
	box.add_child(_make_label("Volumen de efectos", 15))
	box.add_child(effects)
	box.add_child(_make_label("Calidad gráfica", 15))
	var quality := OptionButton.new()
	quality.add_item("Baja · máximo rendimiento", 0)
	quality.add_item("Media · equilibrada", 1)
	quality.add_item("Alta · más sombras y detalle", 2)
	quality.select(1)
	box.add_child(quality)
	set_meta("quality_option", quality)
	var fov := HSlider.new()
	fov.min_value = 65.0
	fov.max_value = 105.0
	fov.step = 1.0
	fov.value = float(TRushProfiles.get_setting("fov", 80.0))
	box.add_child(_make_label("Campo de visión (FOV)", 15))
	box.add_child(fov)
	var apply := func(_value: float = 0.0): options_changed.emit(brightness.value, music.value, effects.value, fov.value, quality.get_selected_id())
	var apply_quality := func(_index: int): options_changed.emit(brightness.value, music.value, effects.value, fov.value, quality.get_selected_id())
	brightness.value_changed.connect(apply)
	music.value_changed.connect(apply)
	effects.value_changed.connect(apply)
	fov.value_changed.connect(apply)
	quality.item_selected.connect(apply_quality)
	var resume := _make_button("VOLVER AL JUEGO · ESC")
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	backdrop.visible = false
	pause_panel.visible = false

func _build_cleaner_management(root: Control) -> void:
	cleaner_panel = _make_panel(Vector2.ZERO, Vector2(390.0, 300.0))
	cleaner_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cleaner_panel.offset_left = -195.0
	cleaner_panel.offset_right = 195.0
	cleaner_panel.offset_top = -150.0
	cleaner_panel.offset_bottom = 150.0
	cleaner_panel.visible = false
	root.add_child(cleaner_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	cleaner_panel.add_child(box)
	box.add_child(_make_label("LIMPIADORA AUTOMÁTICA", 20))
	cleaner_status_label = _make_label("Estado: operativa", 14, Color(0.76, 0.87, 0.71))
	box.add_child(cleaner_status_label)
	cleaner_income_label = _make_label("Ingreso: $1 / min", 14)
	box.add_child(cleaner_income_label)
	cleaner_storage_label = _make_label("Depósito: $0 / $180 · 0%", 14)
	box.add_child(cleaner_storage_label)
	cleaner_fill_bar = ProgressBar.new()
	cleaner_fill_bar.min_value = 0.0
	cleaner_fill_bar.max_value = 100.0
	cleaner_fill_bar.show_percentage = false
	cleaner_fill_bar.custom_minimum_size = Vector2(320.0, 18.0)
	box.add_child(cleaner_fill_bar)
	cleaner_collect_button = _make_button("COBRAR INGRESOS · $0")
	cleaner_collect_button.pressed.connect(func(): cleaner_collect_requested.emit())
	box.add_child(cleaner_collect_button)
	cleaner_toggle_button = _make_button("APAGAR MÁQUINA")
	cleaner_toggle_button.pressed.connect(func(): cleaner_toggle_requested.emit())
	box.add_child(cleaner_toggle_button)
	var close_button := _make_button("CERRAR · ESC")
	close_button.pressed.connect(func(): show_cleaner_management(false))
	box.add_child(close_button)

func _build_boss_acquisition_intro(root: Control) -> void:
	var overlay := Control.new()
	overlay.name = "BossVacuumIntroduction"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	overlay.visible = false
	root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.015, 0.028, 0.022, 0.46)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dimmer)
	boss_acquisition_panel = _make_panel(Vector2.ZERO, Vector2(900.0, 168.0))
	boss_acquisition_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	boss_acquisition_panel.anchor_left = 0.06
	boss_acquisition_panel.anchor_right = 0.94
	boss_acquisition_panel.offset_left = 0.0
	boss_acquisition_panel.offset_right = 0.0
	boss_acquisition_panel.anchor_top = 0.5
	boss_acquisition_panel.anchor_bottom = 0.5
	boss_acquisition_panel.offset_top = -84.0
	boss_acquisition_panel.offset_bottom = 84.0
	overlay.add_child(boss_acquisition_panel)
	boss_acquisition_label = _make_label("", 30, Color(0.92, 0.96, 0.84))
	boss_acquisition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_acquisition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_acquisition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_acquisition_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boss_acquisition_panel.add_child(boss_acquisition_label)
	overlay.modulate.a = 0.0
	set_meta("boss_acquisition_overlay", overlay)

func _build_cleaner_context(root: Control) -> void:
	cleaner_context_label = _make_label("", 15, Color(0.92, 0.96, 0.83))
	cleaner_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cleaner_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cleaner_context_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	cleaner_context_label.offset_left = 220.0
	cleaner_context_label.offset_right = -220.0
	cleaner_context_label.offset_top = -240.0
	cleaner_context_label.offset_bottom = -208.0
	cleaner_context_label.visible = false
	root.add_child(cleaner_context_label)

func show_boss_acquisition_intro(message: String) -> void:
	if boss_acquisition_panel == null:
		return
	var overlay := get_meta("boss_acquisition_overlay") as Control
	if overlay == null:
		return
	if boss_acquisition_tween and boss_acquisition_tween.is_running():
		boss_acquisition_tween.kill()
	boss_acquisition_label.text = message
	overlay.visible = true
	overlay.modulate.a = 0.0
	boss_acquisition_tween = create_tween()
	boss_acquisition_tween.tween_property(overlay, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_SINE)
	boss_acquisition_tween.tween_interval(3.0)
	boss_acquisition_tween.tween_property(overlay, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	boss_acquisition_tween.tween_callback(func(): overlay.visible = false)

func set_cleaner_context(message: String, is_visible: bool) -> void:
	if cleaner_context_label:
		cleaner_context_label.text = message
		cleaner_context_label.visible = is_visible

func show_cleaner_management(is_visible: bool) -> void:
	if cleaner_panel == null:
		return
	if is_visible:
		show_shop(false)
		close_cleaner_management(false)
		bestiary_panel.visible = false
		stats_panel.visible = false
		menu_panel.visible = false
		skill_panel.visible = false
		hide_boss()
	cleaner_panel.visible = is_visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_visible else Input.MOUSE_MODE_CAPTURED

func close_cleaner_management(_restore_mouse: bool = true) -> void:
	if cleaner_panel:
		cleaner_panel.visible = false

func update_cleaner_management(state: Dictionary) -> void:
	if cleaner_status_label == null:
		return
	var installed := bool(state.get("installed", false))
	var operational := bool(state.get("operational", false))
	var income := int(state.get("income_per_minute", 0))
	var stored := int(state.get("stored_money", 0))
	var capacity := maxi(1, int(state.get("storage_capacity", 1)))
	var fill := clampf(float(stored) / float(capacity), 0.0, 1.0)
	cleaner_status_label.text = "Estado: %s · %s" % ["instalada" if installed else "sin instalar", "operativa" if operational else "apagada"]
	cleaner_income_label.text = "Ingreso: $%d / min" % income
	cleaner_storage_label.text = "Depósito: $%d / $%d · %d%%" % [stored, capacity, roundi(fill * 100.0)]
	cleaner_fill_bar.value = fill * 100.0
	cleaner_collect_button.text = "COBRAR INGRESOS · $%d" % stored
	cleaner_collect_button.disabled = stored <= 0
	cleaner_toggle_button.text = "APAGAR MÁQUINA" if operational else "ENCENDER MÁQUINA"

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
	var fill_ratio := clampf(float(current) / float(maxi(1, capacity)), 0.0, 1.0)
	if bag_count_label:
		bag_count_label.text = "%d / %d" % [current, capacity]
		bag_count_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.52) if fill_ratio >= 1.0 else Color(0.98, 0.97, 0.86))
	if bag_fill_material:
		if bag_fill_tween and bag_fill_tween.is_running():
			bag_fill_tween.kill()
		bag_fill_tween = create_tween()
		var current_ratio := float(bag_fill_material.get_shader_parameter("fill_ratio"))
		bag_fill_tween.tween_method(func(value: float): bag_fill_material.set_shader_parameter("fill_ratio", value), current_ratio, fill_ratio, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if current >= capacity:
		show_message("Bolsa llena · vuelve a reciclar")

func update_money(amount: int) -> void:
	money_label.text = "✦  $%d" % amount
	if shop_balance_label:
		shop_balance_label.text = "SALDO  $%d" % amount

func update_health(current: float, maximum: float) -> void:
	if health_label:
		health_label.text = "VIDA  %.0f / %.0f" % [current, maximum]
	if health_bar:
		health_bar.max_value = maxf(1.0, maximum)
		health_bar.value = clampf(current, 0.0, maximum)
		health_bar.modulate = Color(0.35, 0.86, 0.48) if current / maxf(1.0, maximum) > 0.5 else Color(1.0, 0.35, 0.25)

func update_graphics_quality(level: int) -> void:
	var quality := get_meta("quality_option") as OptionButton
	if quality:
		quality.select(clampi(level, 0, 2))

func update_player_health(current_health: float, maximum_health: float) -> void:
	if player_health_label == null or player_health_bar == null:
		return
	var health_ratio := clampf(current_health / maxf(maximum_health, 1.0), 0.0, 1.0)
	player_health_label.text = "♥  SALUD  %d / %d" % [roundi(current_health), roundi(maximum_health)]
	player_health_bar.max_value = maximum_health
	player_health_bar.value = current_health
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.18, 0.14) if health_ratio < 0.28 else Color(0.81, 0.56, 0.20) if health_ratio < 0.58 else Color(0.28, 0.64, 0.37)
	fill.set_corner_radius_all(5)
	player_health_bar.add_theme_stylebox_override("fill", fill)

func update_minimap(player_position: Vector3, yaw: float, garbage_positions: Array[Vector3], boss_positions: Array[Vector3], radar_active: bool, radar_range: float) -> void:
	if minimap:
		minimap.update_world_state(player_position, yaw, garbage_positions, boss_positions, radar_active, radar_range)

func show_damage_feedback() -> void:
	if damage_overlay == null or damage_indicator == null:
		return
	var previous_flash: Tween = get_meta("damage_flash_tween") if has_meta("damage_flash_tween") else null
	if previous_flash and previous_flash.is_running():
		previous_flash.kill()
	damage_overlay.color = Color(0.82, 0.035, 0.018, 0.22)
	var flash := create_tween()
	flash.tween_property(damage_overlay, "color", Color(0.82, 0.035, 0.018, 0.0), 0.42).set_trans(Tween.TRANS_SINE)
	set_meta("damage_flash_tween", flash)
	var previous_indicator: Tween = get_meta("damage_indicator_tween") if has_meta("damage_indicator_tween") else null
	if previous_indicator and previous_indicator.is_running():
		previous_indicator.kill()
	damage_indicator.visible = true
	damage_indicator.modulate.a = 1.0
	var indicator_tween := create_tween()
	indicator_tween.tween_property(damage_indicator, "modulate:a", 0.0, 0.34)
	indicator_tween.tween_callback(func(): damage_indicator.visible = false)
	set_meta("damage_indicator_tween", indicator_tween)

func update_fruit_boost(boost_id: String, seconds_left: int) -> void:
	if fruit_boost_label == null:
		return
	if boost_id.is_empty() or seconds_left <= 0:
		fruit_boost_label.text = "Sin efecto de fruta"
		return
	var boost_names := {"speed": "Patas ligeras", "vacuum": "Vórtice frutal", "range": "Imán de semillas", "shield": "Escudo de cáscara"}
	fruit_boost_label.text = "● %s · %d s" % [str(boost_names.get(boost_id, boost_id)), seconds_left]

func update_progress(percent: int) -> void:
	progress_label.text = "Bosque %d%% restaurado" % percent
	var milestones := [{"value": 25, "name": "Primeros brotes"}, {"value": 50, "name": "Manos a la tierra"}, {"value": 75, "name": "Guardián del bosque"}, {"value": 100, "name": "Ecosistema restaurado"}]
	for milestone in milestones:
		var key := "achievement_" + str(milestone["value"])
		if percent >= int(milestone["value"]) and not has_meta(key):
			set_meta(key, true)
			achievement_count += 1
			show_message("Logro desbloqueado: " + str(milestone["name"]))

func update_daily_cleanup(target: int, collected: int, bonus_paid: bool) -> void:
	if daily_cleanup_label == null:
		return
	var safe_target := maxi(1, target)
	var safe_collected := clampi(collected, 0, safe_target)
	var remaining := safe_target - safe_collected
	var state := "BONO PAGADO" if bonus_paid else "BONO 10%% AL COMPLETAR" if remaining > 0 else "CUOTA COMPLETA"
	daily_cleanup_label.text = "RESIDUOS DEL DÍA · %d / %d · faltan %d · %s" % [safe_collected, safe_target, remaining, state]

func _build_prestige_interface(root: Control) -> void:
	prestige_confirmation_dialog = ConfirmationDialog.new()
	prestige_confirmation_dialog.title = "Confirmar prestigio"
	prestige_confirmation_dialog.ok_button_text = "Confirmar reinicio"
	prestige_confirmation_dialog.cancel_button_text = "Seguir jugando"
	prestige_confirmation_dialog.confirmed.connect(func(): prestige_confirmed.emit())
	root.add_child(prestige_confirmation_dialog)
	prestige_overlay = Control.new()
	prestige_overlay.name = "PrestigeMenuOverlay"
	prestige_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prestige_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	prestige_overlay.visible = false
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.045, 0.035, 0.84)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	prestige_overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prestige_overlay.add_child(center)
	var panel := _make_panel(Vector2.ZERO, Vector2(560, 420))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_make_label("PRESTIGIO PERMANENTE", 22, Color(0.82, 0.91, 0.68)))
	prestige_points_label = _make_label("Puntos disponibles: 0", 18)
	box.add_child(prestige_points_label)
	box.add_child(_make_label("Los puntos se conservan entre partidas y guardados.", 13, Color(0.77, 0.84, 0.75)))
	for slot_index in range(1, 4):
		var slot := _make_button("Espacio permanente %d · Próximamente" % slot_index)
		slot.disabled = true
		box.add_child(slot)
	prestige_history_label = _make_label("Historial: todavía no hay prestigios.", 12, Color(0.72, 0.79, 0.72))
	prestige_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(prestige_history_label)
	var close_button := _make_button("CERRAR")
	close_button.pressed.connect(func(): prestige_overlay.visible = false)
	box.add_child(close_button)
	root.add_child(prestige_overlay)

func show_prestige_confirmation(points: int, restoration: int, defeated_bosses: int) -> void:
	prestige_confirmation_dialog.dialog_text = "Vas a reiniciar el dinero, mejoras, aspiradora, bolsa, habilidades, cuota diaria, jefes, limpiadoras y progresión de esta partida.\n\nConservarás el perfil, el espacio de guardado, las opciones y los puntos permanentes.\n\nRequisito: 98%% de restauración. Estado actual: %d%%. Jefes mayores derrotados: %d. Puntos que recibirás: %d.\n\n¿Confirmas el reinicio completo?" % [restoration, defeated_bosses, points]
	prestige_confirmation_dialog.popup_centered(Vector2i(600, 360))

func update_prestige_state(points: int, prestige_total: int, history: Array[Dictionary]) -> void:
	if prestige_menu_button:
		prestige_menu_button.text = "PUNTOS DE PRESTIGIO · %d" % points
		prestige_menu_button.visible = prestige_total > 0
	if prestige_points_label:
		prestige_points_label.text = "Puntos disponibles: %d" % points
	if prestige_history_label:
		var recent: Array[String] = []
		for record in history.slice(maxi(0, history.size() - 4)):
			recent.append("#%s · +%s pts · día %s" % [record.get("prestige", "?"), record.get("points", "?"), record.get("day", "?")])
		prestige_history_label.text = "Historial:\n" + ("\n".join(recent) if not recent.is_empty() else "Todavía no hay prestigios.")

func toggle_prestige_menu() -> void:
	if prestige_overlay:
		prestige_overlay.visible = not prestige_overlay.visible

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
<<<<<<< Updated upstream
			detail = "Radio %.1f m · Trayecto %.2f s" % [3.2 + maxf(0.0, float(current_level - 1)) * 0.85, maxf(0.08, 0.24 - maxf(0.0, float(current_level - 1)) * 0.025)]
		if index < upgrade_title_labels.size():
			upgrade_title_labels[index].text = "%s  ·  NIVEL %d" % [display_name.to_upper(), current_level]
		if index < upgrade_detail_labels.size():
			upgrade_detail_labels[index].text = detail
		upgrade_buttons[index].text = "MEJORAR  ·  $%d" % price
		upgrade_buttons[index].tooltip_text = "%s. %s Precio actual: $%d." % [display_name, detail, price]
=======
			detail = "Nivel %d / 10 · Cada nivel añade un componente visible. Radio %.1f m; trayecto %.2f s." % [current_level, 3.2 + maxf(0.0, float(current_level - 1)) * 0.85, maxf(0.08, 0.24 - maxf(0.0, float(current_level - 1)) * 0.025)]
			upgrade_buttons[index].text = "%s · Nv.%d/10 · %s" % [display_name, current_level, "MÁX." if price < 0 else "$%d" % price]
		elif upgrade_id == "daily_quota":
			detail = "Cuota de hoy: 200 + 25 por nivel comprado (%d niveles). El nuevo tamaño se aplica a la mañana siguiente." % current_level
			upgrade_buttons[index].text = "%s · Nv.%d · %s" % [display_name, current_level, "MÁX." if price < 0 else "$%d" % price]
		else:
			upgrade_buttons[index].text = "%s  ·  Nivel %d  ·  %s" % [display_name, current_level, "MÁX." if price < 0 else "$%d" % price]
		upgrade_buttons[index].tooltip_text = "%s. %s Precio actual: %s." % [display_name, detail, "máximo" if price < 0 else "$%d" % price]
		upgrade_buttons[index].disabled = price < 0 or not upgrade_access_enabled
	_refresh_cleaner_shop_controls()

func update_cleaner_shop(state: Dictionary, available_money: int, purchase_price: int, income_cost: int, storage_cost: int, next_income: int, next_capacity: int) -> void:
	cleaner_shop_state = state.duplicate(true)
	cleaner_shop_money = available_money
	cleaner_purchase_price = purchase_price
	cleaner_income_cost = income_cost
	cleaner_storage_cost = storage_cost
	cleaner_next_income = next_income
	cleaner_next_capacity = next_capacity
	_refresh_cleaner_shop_controls()

func _refresh_cleaner_shop_controls() -> void:
	if cleaner_purchase_button == null or cleaner_shop_state.is_empty():
		return
	var owned := bool(cleaner_shop_state.get("owned", false))
	var installed := bool(cleaner_shop_state.get("installed", false))
	var income_level := int(cleaner_shop_state.get("income_level", 0))
	var storage_level := int(cleaner_shop_state.get("storage_level", 0))
	var current_income := int(cleaner_shop_state.get("income_per_minute", 0))
	var current_capacity := int(cleaner_shop_state.get("storage_capacity", 0))
	cleaner_shop_status_label.text = "En mano · lleva la máquina a una zona de agua" if owned and not installed else "Instalada · mejora cualquiera de sus dos sistemas" if installed else "Una inversión de largo plazo · requiere $%d" % cleaner_purchase_price
	cleaner_purchase_button.text = "Limpiadora Automática Portable · %s" % ("COMPRADA" if owned else "$%d" % cleaner_purchase_price)
	cleaner_purchase_button.disabled = owned or not upgrade_access_enabled or cleaner_shop_money < cleaner_purchase_price
	cleaner_income_button.text = "$/min · Nv.%d · $%d → $%d/min · %s" % [income_level, current_income, cleaner_next_income, "MÁX." if cleaner_income_cost < 0 else "$%d" % cleaner_income_cost]
	cleaner_income_button.tooltip_text = "Mejora gradual del ingreso por minuto. Nivel %d: $%d/min; siguiente: $%d/min. Coste: %s." % [income_level, current_income, cleaner_next_income, "máximo" if cleaner_income_cost < 0 else "$%d" % cleaner_income_cost]
	cleaner_storage_button.text = "Almacenamiento · Nv.%d · $%d → $%d · %s" % [storage_level, current_capacity, cleaner_next_capacity, "MÁX." if cleaner_storage_cost < 0 else "$%d" % cleaner_storage_cost]
	cleaner_storage_button.tooltip_text = "Amplía el depósito sin perder el dinero guardado. Nivel %d: $%d; siguiente: $%d. Coste: %s." % [storage_level, current_capacity, cleaner_next_capacity, "máximo" if cleaner_storage_cost < 0 else "$%d" % cleaner_storage_cost]
	var system_unlocked := owned and installed
	cleaner_income_button.disabled = not system_unlocked or not upgrade_access_enabled or cleaner_income_cost < 0 or cleaner_shop_money < cleaner_income_cost
	cleaner_storage_button.disabled = not system_unlocked or not upgrade_access_enabled or cleaner_storage_cost < 0 or cleaner_shop_money < cleaner_storage_cost
>>>>>>> Stashed changes

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
		show_cleaner_management(false)
		hide_boss()
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
	if is_open:
		show_cleaner_management(false)
	shop_open = is_open
	shop_panel.visible = is_open
	if is_open:
		hide_boss()
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
	upgrade_access_enabled = enabled
	for button in upgrade_buttons:
		button.disabled = not enabled
<<<<<<< Updated upstream
	if shop_panel and not enabled and shop_open:
		show_message("La tienda vuelve a abrir durante la noche.")
=======
	_refresh_cleaner_shop_controls()
>>>>>>> Stashed changes

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
		show_cleaner_management(false)
		hide_boss()
		close_shop()
		stats_panel.visible = false
		menu_panel.visible = false
		skill_panel.visible = false
	stats_panel.visible = false

func _toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	if stats_panel.visible:
		show_cleaner_management(false)
		hide_boss()
		close_shop()
		skill_panel.visible = false
	bestiary_panel.visible = false
	menu_panel.visible = false

func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible
	if menu_panel.visible:
		show_cleaner_management(false)
		hide_boss()
		close_shop()
		skill_panel.visible = false
	stats_panel.visible = false
	bestiary_panel.visible = false
	if menu_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_stats(money: int, collected: int, prestige: int, elapsed_seconds: int) -> void:
	stats_label.text = "Fondos acumulados: $%d\nResiduos recuperados: %d\nPrestigios: %d\nTiempo de sesión: %02d:%02d" % [money, collected, prestige, int(elapsed_seconds / 60.0), elapsed_seconds % 60]

func update_boss(name: String, current_health: float, maximum_health: float, stage: int, distance: float) -> void:
	if is_modal_open():
		hide_boss()
		return
	boss_panel.visible = true
	boss_name_label.text = "%s · %s" % [name, ["ACTIVO", "DAÑADO", "CRÍTICO"][clampi(stage, 0, 2)]]
	boss_health_bar.value = 100.0 * clampf(current_health / maxf(maximum_health, 1.0), 0.0, 1.0)
	boss_health_label.text = "%d / %d HP    ·    Distancia %.0f m" % [roundi(current_health), roundi(maximum_health), distance]
	if boss_health_stage != stage:
		boss_health_stage = stage
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = Color(0.75, 0.22, 0.14) if stage == 2 else Color(0.74, 0.48, 0.20) if stage == 1 else Color(0.29, 0.63, 0.36)
		bar_style.set_corner_radius_all(5)
		boss_health_bar.add_theme_stylebox_override("fill", bar_style)

func hide_boss() -> void:
	if boss_panel:
		boss_panel.visible = false

func is_modal_open() -> bool:
	return shop_open or is_paused or (cleaner_panel and cleaner_panel.visible) or (skill_panel and skill_panel.visible) or (bestiary_panel and bestiary_panel.visible) or (stats_panel and stats_panel.visible) or (menu_panel and menu_panel.visible)

func show_message(message: String) -> void:
	message_label.text = message
	var panel := get_meta("notification_panel") as PanelContainer
	if panel:
		panel.visible = true
	message_time_left = 3.8
