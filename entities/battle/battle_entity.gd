class_name BattleEntity extends Node2D

@export var stats: EntityStats = null


func _ready() -> void:
	if stats:
		stats = stats.duplicate()
