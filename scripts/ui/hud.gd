extends CanvasLayer
class_name TRushHUD

var money_label: Label
var bag_label: Label
var help_label: Label
var message_label: Label

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(330, 120)
	add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	money_label = Label.new()
	money_label.text = "Fondos: $0"
	bag_label = Label.new()
	bag_label.text = "Bolsa: 0 / 5"
	help_label = Label.new()
	help_label.text = "WASD mover | Shift correr | Clic recoger | E reciclar | Esc liberar mouse"
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(money_label)
	layout.add_child(bag_label)
	layout.add_child(help_label)
	message_label = Label.new()
	message_label.position = Vector2(20, 155)
	message_label.add_theme_font_size_override("font_size", 22)
	add_child(message_label)

func update_bag(current: int, capacity: int) -> void:
	if bag_label:
		bag_label.text = "Bolsa: %d / %d" % [current, capacity]

func update_money(amount: int) -> void:
	if money_label:
		money_label.text = "Fondos: $%d" % amount

func show_message(message: String) -> void:
	if message_label:
		message_label.text = message
