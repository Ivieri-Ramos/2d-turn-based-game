class_name UIManager extends CanvasLayer

signal new_game
signal exit_game

@export var main_menu: PackedScene = null

var _start_menu_instance: MainMenu = null


func show_start_menu() -> void:
	if not _start_menu_instance and main_menu:
		_start_menu_instance = main_menu.instantiate()
		
		add_child(_start_menu_instance)
		
		_start_menu_instance.tree_exited.connect(func() -> void: _start_menu_instance = null)
		
		_connect_signals()

func hide_start_menu() -> void:
	if _start_menu_instance:
		_start_menu_instance.queue_free()

func _connect_signals() -> void:
	_start_menu_instance.new_game.connect(new_game.emit)
	_start_menu_instance.exit_game.connect(exit_game.emit)
