class_name Main extends Node

@export_group("States")

@export var main_menu_state: AtomicState = null

@export var playing_state: CompoundState = null

@export var exploring_state: AtomicState = null

@export var battling_state: AtomicState = null

@export_group("Systems")

@export var state_chart: StateChart = null

@export var ui: UIManager = null

@export var world: WorldManager = null

@export_group("Scenes")

@export var battle_scene: PackedScene = null

var _battle_instance: Battle = null

func _ready() -> void:
	_connect_state_signals()

func _connect_state_signals() -> void:
	ui.new_game.connect(_on_new_game)
	ui.exit_game.connect(_on_exit_game)
	
	main_menu_state.state_entered.connect(_on_main_menu_state_entered)
	main_menu_state.state_exited.connect(_on_main_menu_state_exited)
	
	playing_state.state_entered.connect(_on_playing_state_entered)
	
	EventBus.battle_requested.connect(_on_battle_requested)
	EventBus.end_battle.connect(_on_battle_end)
	battling_state.state_exited.connect(_on_battling_state_exited)

func _on_main_menu_state_entered() -> void:
	ui.show_start_menu()

func _on_main_menu_state_exited() -> void:
	ui.hide_start_menu()

func _on_new_game() -> void:
	state_chart.send_event(&"start_game")

func _on_exit_game() -> void:
	get_tree().quit()

func _on_playing_state_entered() -> void:
	world.start_game()

func _on_battle_requested(enemy_data: EnemyData, enemy_reference: OverworldEnemy) -> void:
	state_chart.send_event(&"start_battle")
	
	_battle_instance = battle_scene.instantiate()
	
	_battle_instance.start_battle(enemy_data)
	
	self.add_child(_battle_instance)
	
	world.hide()
	world.process_mode = Node.PROCESS_MODE_DISABLED

func _on_battle_end() -> void:
	world.show()
	world.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if _battle_instance:
		_battle_instance.queue_free()
		
		_battle_instance = null
	
	state_chart.send_event(&"start_explore")

func _on_battling_state_exited() -> void:
	world.show()
	world.process_mode = Node.PROCESS_MODE_ALWAYS
