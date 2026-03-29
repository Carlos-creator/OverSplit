extends CanvasLayer

signal closed

const LANGUAGES: Array = [
	{"code": "es", "label": "🇪🇸  Español"},
	{"code": "en", "label": "🇬🇧  English"},
	{"code": "pt", "label": "🇧🇷  Português"},
]

@onready var music_slider: HSlider        = $Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider          = $Panel/VBox/SFXRow/SFXSlider
@onready var music_label: Label           = $Panel/VBox/MusicRow/MusicLabel
@onready var sfx_label: Label             = $Panel/VBox/SFXRow/SFXLabel
@onready var close_btn: Button            = $Panel/VBox/CloseButton
@onready var lang_container: HBoxContainer = $Panel/VBox/LangRow/LangContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	close_btn.pressed.connect(_on_close)

	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	# Leer volumen actual del AudioManager
	var am := get_node("/root/AudioManager")
	music_slider.value = am.get_music_volume()
	sfx_slider.value   = am.get_sfx_volume()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	_build_language_buttons()
	_update_labels()

func open() -> void:
	# Refrescar valores actuales al abrir
	var am := get_node("/root/AudioManager")
	music_slider.value = am.get_music_volume()
	sfx_slider.value   = am.get_sfx_volume()
	visible = true

func _on_close() -> void:
	visible = false
	emit_signal("closed")

func _on_music_changed(value: float) -> void:
	get_node("/root/AudioManager").set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	get_node("/root/AudioManager").set_sfx_volume(value)

func _build_language_buttons() -> void:
	for child in lang_container.get_children():
		child.queue_free()
	var current := TranslationServer.get_locale().substr(0, 2)
	for lang in LANGUAGES:
		var btn := Button.new()
		btn.text = lang["label"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 13)
		if lang["code"] == current:
			btn.modulate = Color(0.3, 1.0, 0.5, 1)
		btn.pressed.connect(_on_language_selected.bind(lang["code"]))
		lang_container.add_child(btn)

func _on_language_selected(code: String) -> void:
	TranslationServer.set_locale(code)
	_build_language_buttons()
	_update_labels()
	# Propagar a todo el árbol incluyendo escenas de juego activas
	_propagate_translation(get_tree().root)

func _propagate_translation(node: Node) -> void:
	node.notification(NOTIFICATION_TRANSLATION_CHANGED)
	for child in node.get_children():
		_propagate_translation(child)

func _update_labels() -> void:
	music_label.text = tr("MUSIC_VOLUME")
	sfx_label.text   = tr("SFX_VOLUME")
	close_btn.text   = tr("CLOSE")
