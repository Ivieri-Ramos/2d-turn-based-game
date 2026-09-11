class_name Interactor extends Node

@onready var entity: OverworldPlayer = owner


func _on_interact_state_entered() -> void:
	if entity.ray_cast.is_colliding():
		var target: Object = entity.ray_cast.get_collider()
		
		if target is OverworldEnemy:
			target.start_battle()
			print("foi")
	
	entity.state_chart.send_event(&"stop_interact")
