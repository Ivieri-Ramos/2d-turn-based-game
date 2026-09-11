class_name BattleEntity extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var battle_stats: EntityData = null

func initialize(data: EntityData) -> void:
	battle_stats = data.duplicate()
	
	battle_stats.current_life = battle_stats.max_life

func _ready() -> void:
	if battle_stats:
		battle_stats = battle_stats.duplicate()
