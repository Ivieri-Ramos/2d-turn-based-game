class_name EntityStats extends Resource

@export var max_life: int = 0
var current_life: int = max_life

@export var attack_points: int = 0

@export var defense_points: int = 0


func take_damage(amount: int) -> void:
	var new_life: int = current_life - amount

	current_life = clampi(new_life, 0, max_life)
