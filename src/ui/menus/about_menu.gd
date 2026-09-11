class_name AboutMenu extends Control

signal close_about_menu

@onready var _close_button: TextureButton = %CloseButton

func _ready() -> void:
	_close_button.pressed.connect(close_about_menu.emit)
