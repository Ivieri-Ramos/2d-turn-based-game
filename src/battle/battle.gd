class_name Battle extends CanvasLayer

signal attack_pressed
signal special_pressed

var _is_acting: bool = false

var _playing: bool = false

@export_group("Systems")

@export var battler_containers: Node2D = null

@export_group("Spawns")

@export var player_spawn: Marker2D = null

@export var enemy_spawn: Marker2D = null

@export var state_chart: StateChart = null

@export_group("States")

@export var player_turn: AtomicState = null

@export var enemy_turn: AtomicState = null

@export_group("Data")

@export var player_data: EntityData = null

var _enemy_instance: BattleEntity = null
var _player_instance: BattleEntity = null

func start_battle(enemy_data: EnemyData) -> void:
	_enemy_instance = enemy_data.battle_scene.instantiate()
	_player_instance = player_data.battle_scene.instantiate()
	
	_player_instance.global_position = player_spawn.global_position
	_enemy_instance.global_position = enemy_spawn.global_position
	
	battler_containers.add_child(_player_instance)
	battler_containers.add_child(_enemy_instance)
	
	_enemy_instance.initialize(enemy_data)
	_player_instance.initialize(player_data)
	
	player_turn.state_entered.connect(_on_player_turn_entered)
	player_turn.state_processing.connect(_on_player_turn_processing)
	player_turn.state_exited.connect(_on_player_turn_exited)
	
	enemy_turn.state_entered.connect(_on_enemy_turn_entered)
	enemy_turn.state_exited.connect(_on_enemy_turn_exited)
	
	_player_instance.scale = Vector2(3, 3)
	_enemy_instance.scale = Vector2(3, 3)
	
	_playing = true

func _on_player_turn_entered() -> void:
	if _player_instance.battle_stats.current_life == 0 and _playing:
		get_tree().quit()
	
	_player_instance.animation_player.play(&"idle")

func _on_player_turn_processing(_delta: float) -> void:
	_is_acting = false
	
	if Input.is_action_just_pressed("attack"):
		_is_acting = true
		
		_player_instance.animation_player.play(&"attack")
		
		await _player_instance.animation_player.animation_finished
		
		state_chart.send_event(&"start_enemy")
	
	elif Input.is_action_just_pressed(&"special"):
		_is_acting = true
		
		_player_instance.animation_player.play(&"attack_run")
		
		await _player_instance.animation_player.animation_finished
		
		state_chart.send_event(&"start_enemy")


func _on_player_turn_exited() -> void:
	_player_instance.animation_player.play(&"idle")
	
	_enemy_instance.battle_stats.take_damage(_player_instance.battle_stats.attack_points)

func _on_enemy_turn_entered() -> void:
	_enemy_instance.animation_player.play(&"hurt")
	
	if _enemy_instance.battle_stats.current_life == 0 and _playing:
		_enemy_instance.animation_player.play(&"death")
		
		await _enemy_instance.animation_player.animation_finished
		
		EventBus.end_battle.emit()
	
	await _enemy_instance.animation_player.animation_finished
	
	_enemy_instance.animation_player.play(&"attack_left")
	
	await _enemy_instance.animation_player.animation_finished
	
	_player_instance.animation_player.play(&"hurt")
	
	await _player_instance.animation_player.animation_finished
	
	state_chart.send_event(&"start_player")

func _on_enemy_turn_exited() -> void:
	_player_instance.battle_stats.take_damage(_enemy_instance.battle_stats.attack_points)
	
	_enemy_instance.animation_player.play(&"idle")
