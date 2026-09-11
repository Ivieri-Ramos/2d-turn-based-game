class_name BaseMap extends Node2D

signal transit_map(target_map_path: String, offset: Vector2)

func _ready() -> void:
	var zones: Array[Node] = find_children("*", "TransitionZone", true, false)
	
	for zone: TransitionZone in zones:
		zone.transition_triggered.connect(_on_transition_triggered)

func _on_transition_triggered(target_map_path: String, offset: Vector2) -> void:
	transit_map.emit(target_map_path, offset)
