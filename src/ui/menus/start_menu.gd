class_name StartMenu extends Control

signal new_game_pressed
signal about_pressed
signal exit_pressed

@export_group("Buttons")

@onready var _new_game_button: TextureButton = %NewGameButton

@onready var _about_button: TextureButton = %AboutButton

@onready var _exit_button: TextureButton = %ExitButton

func _ready() -> void:
	_new_game_button.pressed.connect(new_game_pressed.emit)
	_about_button.pressed.connect(about_pressed.emit)
	_exit_button.pressed.connect(exit_pressed.emit)
