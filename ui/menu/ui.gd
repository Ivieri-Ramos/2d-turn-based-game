class_name UIManager extends CanvasLayer

@export var main_menu: PackedScene = null

var _start_menu_instance: Control = null

func show_start_menu() -> void:
	if not _start_menu_instance and main_menu:
		_start_menu_instance = main_menu.instantiate()
		
		add_child(_start_menu_instance)
		
		_start_menu_instance.tree_exited.connect(func() -> void: _start_menu_instance = null)

func hide_start_menu() -> void:
	if _start_menu_instance:
		_start_menu_instance.queue_free()
