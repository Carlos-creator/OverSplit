extends Node2D

@onready var upgrades_panel: PanelContainer = $CanvasLayer/UpgradesPanel
@onready var upgrades_overlay: ColorRect = $CanvasLayer/UpgradesOverlay
@onready var catalogue_container: VBoxContainer = $CanvasLayer/UpgradesPanel/VBox/ScrollContainer/CatalogueContainer

const CATEGORY_COLORS: Dictionary = {
	"Velocidad":   Color(0.3, 0.8, 1.0, 1),
	"Interacción": Color(0.4, 1.0, 0.6, 1),
	"Clones":      Color(0.8, 0.5, 1.0, 1),
	"Tareas":      Color(1.0, 0.75, 0.2, 1),
	"Eficiencia":  Color(1.0, 0.4, 0.4, 1),
	"Meta":        Color(0.9, 0.9, 0.5, 1),
}

func _ready() -> void:
	$CanvasLayer/Panel/VBox/PlayButton.pressed.connect(_on_play)
	$CanvasLayer/Panel/VBox/UpgradesButton.pressed.connect(_open_upgrades)
	$CanvasLayer/Panel/VBox/QuitButton.pressed.connect(_on_quit)
	$CanvasLayer/UpgradesPanel/VBox/Header/CloseButton.pressed.connect(_close_upgrades)
	upgrades_overlay.gui_input.connect(_on_overlay_input)
	get_node("/root/AudioManager").play_menu_music()

func _on_play() -> void:
	get_node("/root/UpgradeManager").reset_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _open_upgrades() -> void:
	_build_catalogue()
	upgrades_overlay.visible = true
	upgrades_panel.visible = true

func _close_upgrades() -> void:
	upgrades_overlay.visible = false
	upgrades_panel.visible = false

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_upgrades()

func _unhandled_input(event: InputEvent) -> void:
	if upgrades_panel.visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_close_upgrades()

func _build_catalogue() -> void:
	for child in catalogue_container.get_children():
		child.queue_free()

	var catalogue: Array = get_node("/root/UpgradeManager").CATALOGUE
	var by_category: Dictionary = {}
	for upgrade in catalogue:
		var cat: String = upgrade.get("category", "Otro")
		if not by_category.has(cat):
			by_category[cat] = []
		by_category[cat].append(upgrade)

	for category in by_category.keys():
		_add_category_header(category)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)
		catalogue_container.add_child(grid)
		for upgrade in by_category[category]:
			var card := _make_card(upgrade, category)
			grid.add_child(card)

func _add_category_header(category: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	catalogue_container.add_child(hbox)

	var color: Color = CATEGORY_COLORS.get(category, Color.WHITE)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(4, 0)
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.color = color
	hbox.add_child(line)

	var lbl := Label.new()
	lbl.text = category.to_upper()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = color
	hbox.add_child(lbl)

func _make_card(upgrade: Dictionary, category: String) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(240, 0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	pc.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	var icon_lbl := Label.new()
	icon_lbl.text = upgrade.get("icon", "?")
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.custom_minimum_size = Vector2(28, 0)
	header.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = upgrade.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.modulate = CATEGORY_COLORS.get(category, Color.WHITE)
	header.add_child(name_lbl)

	var short_lbl := Label.new()
	short_lbl.text = upgrade.get("desc_short", "")
	short_lbl.add_theme_font_size_override("font_size", 10)
	short_lbl.modulate = Color(0.75, 0.75, 0.75, 1)
	short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(short_lbl)

	var detail_lbl := Label.new()
	detail_lbl.text = upgrade.get("desc_long", "")
	detail_lbl.add_theme_font_size_override("font_size", 10)
	detail_lbl.modulate = Color(0.9, 0.85, 0.5, 1)
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_lbl.visible = false
	vbox.add_child(detail_lbl)

	pc.mouse_entered.connect(func(): pc.modulate = Color(1.15, 1.15, 1.15, 1))
	pc.mouse_exited.connect(func(): pc.modulate = Color(1, 1, 1, 1))
	pc.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			detail_lbl.visible = not detail_lbl.visible
	)

	return pc
