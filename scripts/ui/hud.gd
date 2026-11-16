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
var upgrade_buttons: Array[Button] = []
var bestiary_panel: PanelContainer
var bestiary_list: VBoxContainer

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(340, 160)
	add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	money_label = _make_label("Fondos: $0", 20)
	bag_label = _make_label("Bolsa: 0 / 5", 18)
	progress_label = _make_label("Bioma: 0% restaurado", 16)
	phase_label = _make_label("DÍA", 16)
	layout.add_child(money_label)
	layout.add_child(bag_label)
	layout.add_child(progress_label)
	layout.add_child(phase_label)
	var help := _make_label("WASD mover · Shift correr · Clic recoger · E reciclar · Esc mouse", 13)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(help)

	var right_panel := PanelContainer.new()
	right_panel.position = Vector2(18, 190)
	right_panel.custom_minimum_size = Vector2(340, 290)
	add_child(right_panel)
	var upgrade_box := VBoxContainer.new()
	right_panel.add_child(upgrade_box)
	upgrade_box.add_child(_make_label("MEJORAS (fase nocturna)", 17))
	var upgrade_data := [
		["speed", "1 · Velocidad +", "Mejora el desplazamiento"],
		["capacity", "2 · Bolsa +", "Aumenta capacidad en 2"],
		["value", "3 · Valor +", "Más dinero por residuo"],
		["range", "4 · Alcance +", "Recoge desde más lejos"],
		["day", "5 · Turno +", "Días más largos"]
	]
	for item in upgrade_data:
		var button := Button.new()
		button.text = "%s — %s" % [item[1], item[2]]
		button.pressed.connect(_on_upgrade_pressed.bind(item[0]))
		upgrade_box.add_child(button)
		upgrade_buttons.append(button)
	var prestige_button := Button.new()
	prestige_button.text = "RESTAURAR BIOMA · PRESTIGIO"
	prestige_button.pressed.connect(func(): prestige_requested.emit())
	upgrade_box.add_child(prestige_button)

	var bestiary_button := Button.new()
	bestiary_button.text = "ABRIR BESTIARIO"
	bestiary_button.position = Vector2(18, 500)
	bestiary_button.pressed.connect(func(): bestiary_toggled.emit())
	add_child(bestiary_button)

	bestiary_panel = PanelContainer.new()
	bestiary_panel.position = Vector2(380, 190)
	bestiary_panel.custom_minimum_size = Vector2(360, 260)
	bestiary_panel.visible = false
	add_child(bestiary_panel)
	bestiary_list = VBoxContainer.new()
	bestiary_panel.add_child(bestiary_list)
	bestiary_list.add_child(_make_label("BESTIARIO DEL BOSQUE", 20))

	message_label = _make_label("", 22)
	message_label.position = Vector2(380, 24)
	message_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.82))
	add_child(message_label)

func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _on_upgrade_pressed(upgrade_id: String) -> void:
	upgrade_requested.emit(upgrade_id)

func update_bag(current: int, capacity: int) -> void:
	bag_label.text = "Bolsa: %d / %d" % [current, capacity]

func update_money(amount: int) -> void:
	money_label.text = "Fondos: $%d" % amount

func update_progress(percent: int) -> void:
	progress_label.text = "Bioma: %d%% restaurado" % percent

func update_phase(is_day: bool, seconds_left: int) -> void:
	phase_label.text = "%s · %02d:%02d" % ["DÍA" if is_day else "NOCHE", seconds_left / 60, seconds_left % 60]

func set_upgrade_access(enabled: bool) -> void:
	for button in upgrade_buttons:
		button.disabled = not enabled

func set_bestiary(entries: Array[Dictionary]) -> void:
	for index in range(1, bestiary_list.get_child_count()):
		bestiary_list.get_child(index).queue_free()
	for entry in entries:
		var label := _make_label("✓ %s — %s" % [entry.get("name", "Especie"), entry.get("description", "")], 14)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bestiary_list.add_child(label)

func toggle_bestiary() -> void:
	bestiary_panel.visible = not bestiary_panel.visible

func show_message(message: String) -> void:
	message_label.text = message
