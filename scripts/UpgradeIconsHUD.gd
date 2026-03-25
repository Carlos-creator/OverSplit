extends CanvasLayer

var _tooltip: PanelContainer = null
var _tooltip_name: Label = null
var _tooltip_desc: Label = null
var _detail: PanelContainer = null
var _detail_icon: Label = null
var _detail_name: Label = null
var _detail_cat: Label = null
var _detail_desc: Label = null

func _ready() -> void:
	get_node("/root/UpgradeManager").upgrade_chosen.connect(_on_upgrade_chosen)
	_build_tooltip()
	_build_detail()
	_refresh()

func _on_upgrade_chosen(_upgrade: Dictionary) -> void:
	_refresh()

func _refresh() -> void:
	var container: HBoxContainer = $Container
	for child in container.get_children():
		child.queue_free()
	var upgrades: Array = get_node("/root/UpgradeManager").active_upgrades
	for upgrade in upgrades:
		var slot := _make_slot(upgrade)
		container.add_child(slot)

func _make_slot(upgrade: Dictionary) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(44, 44)
	var lbl := Label.new()
	lbl.text = upgrade.get("icon", "?")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	pc.add_child(lbl)
	pc.mouse_entered.connect(_show_tooltip.bind(upgrade, pc))
	pc.mouse_exited.connect(_hide_tooltip)
	pc.gui_input.connect(_on_slot_input.bind(upgrade))
	return pc

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 20
	var vb := VBoxContainer.new()
	_tooltip.add_child(vb)
	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 12)
	vb.add_child(_tooltip_name)
	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 10)
	_tooltip_desc.modulate = Color(0.85, 0.85, 0.85, 1)
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(180, 0)
	vb.add_child(_tooltip_desc)
	add_child(_tooltip)

func _build_detail() -> void:
	_detail = PanelContainer.new()
	_detail.visible = false
	_detail.z_index = 21
	_detail.custom_minimum_size = Vector2(260, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_detail.add_child(vb)
	var row := HBoxContainer.new()
	vb.add_child(row)
	_detail_icon = Label.new()
	_detail_icon.add_theme_font_size_override("font_size", 22)
	row.add_child(_detail_icon)
	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 14)
	_detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_detail_name)
	_detail_cat = Label.new()
	_detail_cat.add_theme_font_size_override("font_size", 10)
	_detail_cat.modulate = Color(0.6, 0.6, 0.6, 1)
	vb.add_child(_detail_cat)
	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 11)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_desc)
	var close_btn := Button.new()
	close_btn.text = "Cerrar"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func(): _detail.visible = false)
	vb.add_child(close_btn)
	add_child(_detail)

func _show_tooltip(upgrade: Dictionary, slot: Control) -> void:
	_tooltip_name.text = upgrade.get("icon", "") + "  " + upgrade.get("name", "")
	_tooltip_desc.text = upgrade.get("desc_short", "")
	_tooltip.visible = true
	await get_tree().process_frame
	var slot_pos: Vector2 = slot.get_global_rect().position
	_tooltip.position = slot_pos - Vector2(0, _tooltip.size.y + 6)

func _hide_tooltip() -> void:
	_tooltip.visible = false

func _on_slot_input(event: InputEvent, upgrade: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_detail_icon.text = upgrade.get("icon", "")
		_detail_name.text = upgrade.get("name", "")
		_detail_cat.text = "[" + upgrade.get("category", "") + "]"
		_detail_desc.text = upgrade.get("desc_long", "")
		_detail.visible = true
		await get_tree().process_frame
		_detail.position = Vector2(960 - _detail.size.x - 16, 540 - 44 - _detail.size.y - 8)
