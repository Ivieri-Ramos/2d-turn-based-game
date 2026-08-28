class_name OverworldEntity extends Area2D

enum Direction {
	NORTH,
	WEST,
	EAST,
	SOUTH,
}

#@export var stats: EntityStats = null

@export var initial_direction: Direction = Direction.SOUTH

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var ray_cast: RayCast2D = $RayCast2D

const GRID_SIZE: int = 32


func _ready() -> void:
	change_direction(initial_direction)


func change_direction(new_direction: Direction) -> void:
	var vector_vision: Vector2 = Vector2.ZERO

	match new_direction:
		Direction.NORTH:
			animation_player.play(&"idle_north")
			vector_vision = Vector2(0, -GRID_SIZE)
		Direction.WEST:
			animation_player.play(&"idle_west")
			vector_vision = Vector2(-GRID_SIZE, 0)
		Direction.EAST:
			animation_player.play(&"idle_east")
			vector_vision = Vector2(GRID_SIZE, 0)
		Direction.SOUTH:
			animation_player.play(&"idle_south")
			vector_vision = Vector2(0, GRID_SIZE)

	ray_cast.target_position = vector_vision
	ray_cast.force_raycast_update()
