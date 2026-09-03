class_name OverworldEntity extends Area2D

#@export var stats: EntityStats = null

@export var direction: GameEnums.Direction = GameEnums.Direction.DOWN

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var ray_cast: RayCast2D = $RayCast2D


func _ready() -> void:
	change_direction(direction)
	
	animation_player.play(GameConstants.ANIM_IDLE[direction])


func change_direction(new_direction: GameEnums.Direction) -> void:
	direction = new_direction
	
	var vector_vision: Vector2 = GameConstants.DIRECTION_VECTORS[direction]
	
	ray_cast.target_position = vector_vision
	ray_cast.force_raycast_update()
