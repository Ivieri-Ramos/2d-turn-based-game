class_name GridMovement extends Node

@onready var entity: OverworldPlayer = owner


func _on_move_state_entered() -> void:
	entity.animation_player.play(GameConstants.ANIM_MOVE[entity.direction])

	var destiny: Vector2 = entity.global_position + entity.ray_cast.target_position

	var tween: Tween = create_tween()
	tween.tween_property(entity, "global_position", destiny, GameConstants.MOVE_DURATION)

	tween.finished.connect(_on_move_state_finished)


func _on_move_state_finished() -> void:
	entity.state_chart.send_event(&"stop_move")
