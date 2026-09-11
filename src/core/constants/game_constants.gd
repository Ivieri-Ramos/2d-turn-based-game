class_name GameConstants extends RefCounted

const MOVE_DURATION: float = 0.30

const GRID_SIZE: int = 32

static var ANIM_MOVE: Dictionary[GameEnums.Direction, StringName] = {
	GameEnums.Direction.UP: &"move_up",
	GameEnums.Direction.LEFT: &"move_left",
	GameEnums.Direction.RIGHT: &"move_right",
	GameEnums.Direction.DOWN: &"move_down",
}

static var ANIM_IDLE: Dictionary[GameEnums.Direction, StringName] = {
	GameEnums.Direction.UP: &"idle_up",
	GameEnums.Direction.LEFT: &"idle_left",
	GameEnums.Direction.RIGHT: &"idle_right",
	GameEnums.Direction.DOWN: &"idle_down",
}

static var DIRECTION_VECTORS: Dictionary[GameEnums.Direction, Vector2] = {
	GameEnums.Direction.UP: Vector2(0, -GRID_SIZE),
	GameEnums.Direction.LEFT: Vector2(-GRID_SIZE, 0),
	GameEnums.Direction.RIGHT: Vector2(GRID_SIZE, 0),
	GameEnums.Direction.DOWN: Vector2(0, GRID_SIZE),
}
