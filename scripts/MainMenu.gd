extends Node2D

@onready var upgrades_panel: PanelContainer = $CanvasLayer/UpgradesPanel
@onready var upgrades_overlay: ColorRect = $CanvasLayer/UpgradesOverlay
@onready var catalogue_container: VBoxContainer = $CanvasLayer/UpgradesPanel/VBox/ScrollContainer/CatalogueContainer

const CATEGORY_COLORS: Dictionary = {
	"CAT_SPEED":       Color(0.3, 0.8, 1.0, 1),
	"CAT_INTERACTION": Color(0.4, 1.0, 0.6, 1),
	"CAT_CLONES":      Color(0.8, 0.5, 1.0, 1),
	"CAT_TASKS":       Color(1.0, 0.75, 0.2, 1),
	"CAT_EFFICIENCY":  Color(1.0, 0.4, 0.4, 1),
	"CAT_META":        Color(0.9, 0.9, 0.5, 1),
}

const TUTORIAL_STEPS: Array = [
	{ "title_key": "TUT1_TITLE", "text_key": "TUT1_TEXT" },
	{ "title_key": "TUT2_TITLE", "text_key": "TUT2_TEXT" },
	{ "title_key": "TUT3_TITLE", "text_key": "TUT3_TEXT" },
	{ "title_key": "TUT4_TITLE", "text_key": "TUT4_TEXT" },
	{ "title_key": "TUT5_TITLE", "text_key": "TUT5_TEXT" },
	{ "title_key": "TUT6_TITLE", "text_key": "TUT6_TEXT" },
]

var _tutorial_step: int = 0
var _options_menu: Node = null

func _ready() -> void:
	$CanvasLayer/Panel/VBox/PlayButton.pressed.connect(_on_play)
	$CanvasLayer/Panel/VBox/UpgradesButton.pressed.connect(_open_upgrades)
	$CanvasLayer/Panel/VBox/TutorialButton.pressed.connect(_open_tutorial)
	$CanvasLayer/Panel/VBox/OptionsButton.pressed.connect(_on_options)
	$CanvasLayer/Panel/VBox/QuitButton.pressed.connect(_on_quit)
	$CanvasLayer/UpgradesPanel/VBox/Header/CloseButton.pressed.connect(_close_upgrades)
	upgrades_overlay.gui_input.connect(_on_overlay_input)
	$CanvasLayer/TutorialPanel/VBox/NavRow/PrevButton.pressed.connect(_tutorial_prev)
	$CanvasLayer/TutorialPanel/VBox/NavRow/NextButton.pressed.connect(_tutorial_next)
	$CanvasLayer/TutorialPanel/VBox/CloseButton.pressed.connect(_close_tutorial)
	$CanvasLayer/TutorialOverlay.gui_input.connect(_on_tutorial_overlay_input)
	get_node("/root/AudioManager").play_menu_music()
	_update_texts()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if not is_node_ready():
			return
		_update_texts()
		if upgrades_panel != null and upgrades_panel.visible:
			_build_catalogue()
		if has_node("CanvasLayer/TutorialPanel") and $CanvasLayer/TutorialPanel.visible:
			_update_tutorial_display()

func _update_texts() -> void:
	$CanvasLayer/Panel/VBox/PlayButton.text     = tr("PLAY")
	$CanvasLayer/Panel/VBox/UpgradesButton.text = tr("SEE_UPGRADES")
	$CanvasLayer/Panel/VBox/TutorialButton.text = tr("HOW_TO_PLAY")
	$CanvasLayer/Panel/VBox/OptionsButton.text  = tr("OPTIONS")
	$CanvasLayer/Panel/VBox/QuitButton.text     = tr("QUIT")
	$CanvasLayer/Panel/VBox/Tagline.text        = tr("TAGLINE")
	$CanvasLayer/UpgradesPanel/VBox/Header/TitleLabel.text  = tr("UPGRADES_CATALOGUE")
	$CanvasLayer/UpgradesPanel/VBox/Header/CloseButton.text = tr("CLOSE")
	$CanvasLayer/UpgradesPanel/VBox/SubtitleLabel.text      = tr("UPGRADES_HINT")
	$CanvasLayer/TutorialPanel/VBox/TitleLabel.text         = tr("TUTORIAL_TITLE")
	$CanvasLayer/TutorialPanel/VBox/CloseButton.text        = tr("CLOSE")

func _on_play() -> void:
	get_node("/root/UpgradeManager").reset_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_options() -> void:
	if _options_menu == null or not is_instance_valid(_options_menu):
		var scene := load("res://scenes/ui/OptionsMenu.tscn") as PackedScene
		_options_menu = scene.instantiate()
		get_tree().root.add_child(_options_menu)
	_options_menu.open()

# --- Upgrades panel ---

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
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if upgrades_panel.visible:
			_close_upgrades()
		elif $CanvasLayer/TutorialPanel.visible:
			_close_tutorial()

# --- Tutorial panel ---

func _open_tutorial() -> void:
	_tutorial_step = 0
	_update_tutorial_display()
	$CanvasLayer/TutorialOverlay.visible = true
	$CanvasLayer/TutorialPanel.visible = true

func _close_tutorial() -> void:
	$CanvasLayer/TutorialOverlay.visible = false
	$CanvasLayer/TutorialPanel.visible = false

func _on_tutorial_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_tutorial()

func _tutorial_prev() -> void:
	_tutorial_step = max(0, _tutorial_step - 1)
	_update_tutorial_display()

func _tutorial_next() -> void:
	if _tutorial_step < TUTORIAL_STEPS.size() - 1:
		_tutorial_step += 1
		_update_tutorial_display()
	else:
		_close_tutorial()

func _update_tutorial_display() -> void:
	var step: Dictionary = TUTORIAL_STEPS[_tutorial_step]
	$CanvasLayer/TutorialPanel/VBox/TitleLabel.text   = tr(step["title_key"])
	$CanvasLayer/TutorialPanel/VBox/ContentLabel.text = tr(step["text_key"])
	$CanvasLayer/TutorialPanel/VBox/NavRow/StepLabel.text = tr("TUT_STEP") % [_tutorial_step + 1, TUTORIAL_STEPS.size()]
	$CanvasLayer/TutorialPanel/VBox/NavRow/PrevButton.disabled = _tutorial_step == 0
	var is_last := _tutorial_step == TUTORIAL_STEPS.size() - 1
	$CanvasLayer/TutorialPanel/VBox/NavRow/PrevButton.text = tr("TUT_PREV")
	$CanvasLayer/TutorialPanel/VBox/NavRow/NextButton.text = tr("TUT_LAST") if is_last else tr("TUT_NEXT")

# --- Catalogue ---

func _build_catalogue() -> void:
	for child in catalogue_container.get_children():
		child.queue_free()
	var catalogue: Array = get_node("/root/UpgradeManager").CATALOGUE
	var by_category: Dictionary = {}
	for upgrade in catalogue:
		var cat_key: String = upgrade.get("category_key", "CAT_META")
		if not by_category.has(cat_key):
			by_category[cat_key] = []
		by_category[cat_key].append(upgrade)
	for category_key in by_category.keys():
		_add_category_header(category_key)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)
		catalogue_container.add_child(grid)
		for upgrade in by_category[category_key]:
			var card := _make_card(upgrade, category_key)
			grid.add_child(card)

func _add_category_header(category_key: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	catalogue_container.add_child(hbox)
	var color: Color = CATEGORY_COLORS.get(category_key, Color.WHITE)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(4, 0)
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.color = color
	hbox.add_child(line)
	var lbl := Label.new()
	lbl.text = tr(category_key).to_upper()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = color
	hbox.add_child(lbl)

func _make_card(upgrade: Dictionary, category_key: String) -> Control:
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
	name_lbl.text = tr(upgrade.get("name_key", upgrade.get("name", "")))
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.modulate = CATEGORY_COLORS.get(category_key, Color.WHITE)
	header.add_child(name_lbl)
	var short_lbl := Label.new()
	short_lbl.text = tr(upgrade.get("short_key", upgrade.get("desc_short", "")))
	short_lbl.add_theme_font_size_override("font_size", 10)
	short_lbl.modulate = Color(0.75, 0.75, 0.75, 1)
	short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(short_lbl)
	var detail_lbl := Label.new()
	detail_lbl.text = tr(upgrade.get("long_key", upgrade.get("desc_long", "")))
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
