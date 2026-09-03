class_name InputHandler extends Node

@onready var entity: OverworldPlayer = owner

func _on_idle_state_entered() -> void:
	entity.animation_player.play(GameConstants.ANIM_IDLE[entity.direction])

func _on_idle_state_processing(_delta: float) -> void:
	var new_direction: GameEnums.Direction = entity.direction
	var try_move: bool = false

	if Input.is_action_pressed(&"move_up"):
		try_move = true
		new_direction = GameEnums.Direction.UP
	elif Input.is_action_pressed(&"move_left"):
		try_move = true
		new_direction = GameEnums.Direction.LEFT
	elif Input.is_action_pressed(&"move_right"):
		try_move = true
		new_direction = GameEnums.Direction.RIGHT
	elif Input.is_action_pressed(&"move_down"):
		try_move = true
		new_direction = GameEnums.Direction.DOWN

	if try_move:
		var turned_around: bool = (new_direction != entity.direction)
		
		if turned_around:
			entity.change_direction(new_direction)
			
			entity.animation_player.play(GameConstants.ANIM_IDLE[new_direction])

		if not entity.ray_cast.is_colliding():
			entity.state_chart.send_event(&"start_move")
