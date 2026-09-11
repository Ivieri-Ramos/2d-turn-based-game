class_name OverworldEnemy extends OverworldEntity

func start_battle() -> void:
	EventBus.battle_requested.emit(battle_stats, self)
