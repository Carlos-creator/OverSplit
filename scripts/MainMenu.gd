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

# --- Tutorial data ---
const TUTORIAL_STEPS: Array = [
	{
		"title": "¿Qué es OverSplit?",
		"text": "Eres un trabajador que se divide en clones para completar tareas antes de que expiren. Cada clon que creas reduce tu eficiencia, pero completar tareas requiere presencia. ¡Encuentra el equilibrio!"
	},
	{
		"title": "Controles",
		"text": "Mover              →  Flechas / WASD\nCrear clon         →  SPACE\nEliminar clon      →  Q\nInteractuar        →  E (en rango)\nAsignar prioridad  →  Click izquierdo en tarea\nCancelar prioridad →  Click derecho en tarea\nPausar             →  ESC / Botón Pausa\nVelocidad          →  Botón x1 / x1.5 / x2\nSaltar oleada      →  Botón Skip"
	},
	{
		"title": "Clones y eficiencia",
		"text": "Con 1 clon tienes 100% de eficiencia. Cada clon extra la reduce. Más clones = más tareas en paralelo, pero se mueven y actúan más lento. ¡Demasiados clones puede ser peor!"
	},
	{
		"title": "Asignar prioridad a clones",
		"text": "Haz click izquierdo en una tarea para asignar el siguiente clon disponible a ella. Cada click asigna un clon más. Haz click derecho para cancelar todas las asignaciones de esa tarea. Los clones asignados se muestran con un borde cyan pulsante."
	},
	{
		"title": "Estrés y colapso",
		"text": "Fallar tareas sube el estrés (máx 5). Con estrés alto pierdes velocidad, eficiencia y tiempo. Si llegas al máximo y no bajas el estrés, la barra de colapso se llena y pierdes."
	},
	{
		"title": "Mejoras",
		"text": "Cada 3 oleadas eliges 1 mejora de 3 opciones aleatorias. Las que no eliges se descartan para siempre en esa partida. ¡Planifica tu build con cuidado!"
	},
]

var _tutorial_step: int = 0

func _ready() -> void:
	$CanvasLayer/Panel/VBox/PlayButton.pressed.connect(_on_play)
	$CanvasLayer/Panel/VBox/UpgradesButton.pressed.connect(_open_upgrades)
	$CanvasLayer/Panel/VBox/TutorialButton.pressed.connect(_open_tutorial)
	$CanvasLayer/Panel/VBox/QuitButton.pressed.connect(_on_quit)
	$CanvasLayer/UpgradesPanel/VBox/Header/CloseButton.pressed.connect(_close_upgrades)
	upgrades_overlay.gui_input.connect(_on_overlay_input)

	# Tutorial buttons
	$CanvasLayer/TutorialPanel/VBox/NavRow/PrevButton.pressed.connect(_tutorial_prev)
	$CanvasLayer/TutorialPanel/VBox/NavRow/NextButton.pressed.connect(_tutorial_next)
	$CanvasLayer/TutorialPanel/VBox/CloseButton.pressed.connect(_close_tutorial)
	$CanvasLayer/TutorialOverlay.gui_input.connect(_on_tutorial_overlay_input)

	get_node("/root/AudioManager").play_menu_music()

func _on_play() -> void:
	get_node("/root/UpgradeManager").reset_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()

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
	$CanvasLayer/TutorialPanel/VBox/TitleLabel.text = step["title"]
	$CanvasLayer/TutorialPanel/VBox/ContentLabel.text = step["text"]
	$CanvasLayer/TutorialPanel/VBox/NavRow/StepLabel.text = "%d / %d" % [_tutorial_step + 1, TUTORIAL_STEPS.size()]
	$CanvasLayer/TutorialPanel/VBox/NavRow/PrevButton.disabled = _tutorial_step == 0
	var is_last := _tutorial_step == TUTORIAL_STEPS.size() - 1
	$CanvasLayer/TutorialPanel/VBox/NavRow/NextButton.text = "¡Entendido!" if is_last else "Siguiente →"

# --- Catalogue ---

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
