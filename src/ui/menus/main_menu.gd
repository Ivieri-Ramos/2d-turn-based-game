class_name MainMenu extends Control

signal new_game
signal exit_game

@onready var _main_menu: StartMenu = %StartMenu
@onready var _about_menu: AboutMenu = %AboutMenu

func _ready() -> void:
	_about_menu.hide()
	_main_menu.show()
	
	_about_menu.close_about_menu.connect(_on_close_about_menu)
	
	_main_menu.about_pressed.connect(_on_about_pressed)
	
	_main_menu.exit_pressed.connect(func() -> void: exit_game.emit())
	_main_menu.new_game_pressed.connect(func() -> void: new_game.emit())

func _on_about_pressed() -> void:
	_main_menu.hide()
	_about_menu.show()

func _on_close_about_menu() -> void:
	_main_menu.show()
	_about_menu.hide()
