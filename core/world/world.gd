class_name WorldManager extends Node2D

@export var initial_map: PackedScene = null

@export var initial_position: Vector2 = Vector2.ZERO

@export var overworld_player: PackedScene = null

@onready var map_container: Node2D = $MapContainer

@onready var entities_container: Node2D = $EntitiesContainer

var _current_map: BaseMap = null

var _player_instance: OverworldPlayer = null

func start_game() -> void:
	_change_current_map(initial_map)
	
	_load_player()

func _change_current_map(new_map: PackedScene) -> void:
	if _current_map:
		_current_map.queue_free()
		
		_current_map = null
	
	_current_map = new_map.instantiate()
	
	_current_map.transit_map.connect(_transit_map)
	
	map_container.add_child(_current_map)

func _load_player() -> void:
	_player_instance = overworld_player.instantiate()
	
	_player_instance.global_position = initial_position
	
	entities_container.add_child(_player_instance)

func _transit_map(map_name: String, offset: Vector2) -> void:
	
	var new_map_scene: PackedScene = load(map_name)
	
	if _player_instance:
		
		await EventBus.stop_movement
		
		_player_instance.global_position += offset
	
	_change_current_map.call_deferred(new_map_scene)
