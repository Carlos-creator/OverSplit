extends CanvasLayer

var _cards: Array = []
var _running: bool = false

@onready var panel: PanelContainer = $Panel
@onready var cards_container: HBoxContainer = $Panel/VBox/CardsContainer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if not is_node_ready() or not visible:
			return
		if cards_container == null or not is_instance_valid(cards_container):
			return
		_build_cards()

func show_cards(upgrades: Array) -> void:
	_cards = upgrades
	_running = true
	_build_cards()
	visible = true
	get_tree().paused = true

func _build_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	for upgrade in _cards:
		var card := _make_card(upgrade)
		cards_container.add_child(card)
	if _cards.is_empty():
		_close(null)
	if has_node("Panel/VBox/TitleLabel"):
		$Panel/VBox/TitleLabel.text = tr("CHOOSE_UPGRADE")
	if has_node("Panel/VBox/SkipLabel"):
		$Panel/VBox/SkipLabel.text = tr("SKIP_UPGRADE")

func _make_card(upgrade: Dictionary) -> Control:
	var panel_card := PanelContainer.new()
	panel_card.custom_minimum_size = Vector2(200, 220)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel_card.add_child(vbox)

	var icon_lbl := Label.new()
	icon_lbl.text = upgrade.get("icon", "?")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 36)
	vbox.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = tr(upgrade.get("name_key", upgrade.get("name", "")))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var cat_lbl := Label.new()
	cat_lbl.text = "[" + tr(upgrade.get("category_key", "")) + "]"
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_lbl.add_theme_font_size_override("font_size", 10)
	cat_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
	vbox.add_child(cat_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = tr(upgrade.get("short_key", upgrade.get("desc_short", "")))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.modulate = Color(0.9, 0.9, 0.9, 1)
	vbox.add_child(desc_lbl)

	var long_lbl := Label.new()
	long_lbl.text = tr(upgrade.get("long_key", upgrade.get("desc_long", "")))
	long_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	long_lbl.add_theme_font_size_override("font_size", 10)
	long_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	long_lbl.modulate = Color(0.85, 0.82, 0.6, 1)
	long_lbl.visible = false
	vbox.add_child(long_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var detail_btn := Button.new()
	detail_btn.text = tr("VIEW_DETAIL")
	detail_btn.focus_mode = Control.FOCUS_NONE
	detail_btn.add_theme_font_size_override("font_size", 11)
	detail_btn.modulate = Color(0.7, 0.7, 0.7, 1)
	detail_btn.pressed.connect(func():
		long_lbl.visible = not long_lbl.visible
		detail_btn.text = tr("HIDE_DETAIL") if long_lbl.visible else tr("VIEW_DETAIL")
	)
	vbox.add_child(detail_btn)

	var btn := Button.new()
	btn.text = tr("CHOOSE")
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(_close.bind(upgrade))
	vbox.add_child(btn)

	return panel_card

func _process(_delta: float) -> void:
	pass

func _close(chosen) -> void:
	if not _running:
		return
	_running = false
	var um := get_node("/root/UpgradeManager")
	if chosen != null:
		um.apply_upgrade(chosen)
		for u in _cards:
			if u["id"] != chosen["id"]:
				um.discard_upgrade(u)
	else:
		for u in _cards:
			um.discard_upgrade(u)
	visible = false
	get_tree().paused = false
