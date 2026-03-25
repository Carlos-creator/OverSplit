extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/MenuButton.pressed.connect(_on_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		return
	if event.is_action_pressed("ui_cancel", false):
		if get_tree().paused:
			_on_resume()
		else:
			_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		_on_resume()
	else:
		_pause()

func _pause() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = true
	_populate_upgrades()
	visible = true

func _on_resume() -> void:
	get_tree().paused = false
	visible = false

func _on_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_node("/root/GameManager").stop_game()
	get_node("/root/UpgradeManager").reset_run()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _populate_upgrades() -> void:
	var list: VBoxContainer = $Panel/VBox/UpgradesScroll/UpgradesList
	for child in list.get_children():
		child.queue_free()

	var upgrades: Array = get_node("/root/UpgradeManager").active_upgrades
	var no_label: Label = $Panel/VBox/NoUpgradesLabel
	no_label.visible = upgrades.is_empty()

	for upgrade in upgrades:
		var row := _make_row(upgrade)
		list.add_child(row)

func _make_row(upgrade: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = upgrade.get("icon", "?")
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(icon_lbl)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_lbl := Label.new()
	name_lbl.text = upgrade.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(name_lbl)

	var short_lbl := Label.new()
	short_lbl.text = upgrade.get("desc_short", "")
	short_lbl.add_theme_font_size_override("font_size", 10)
	short_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
	short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(short_lbl)

	var detail_lbl := Label.new()
	detail_lbl.text = upgrade.get("desc_long", "")
	detail_lbl.add_theme_font_size_override("font_size", 10)
	detail_lbl.modulate = Color(0.9, 0.85, 0.5, 1)
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_lbl.visible = false
	vbox.add_child(detail_lbl)

	hbox.mouse_entered.connect(func(): hbox.modulate = Color(1.2, 1.2, 1.2, 1))
	hbox.mouse_exited.connect(func(): hbox.modulate = Color(1, 1, 1, 1))
	hbox.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			detail_lbl.visible = not detail_lbl.visible
	)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	return vbox
