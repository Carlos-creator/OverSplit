extends Node2D

func _ready() -> void:
	var original := $Player/OriginalPlayer
	$CloneManager.register_original(original)
