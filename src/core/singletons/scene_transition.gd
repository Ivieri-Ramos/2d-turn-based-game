extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func change_scene(target_scene_path: String) -> void:
	# 1. Toca a animação para escurecer a tela (Fade Out)
	animation_player.play("fade")
	await animation_player.animation_finished
	
	# 2. Troca para a nova cena de mapa
	get_tree().change_scene_to_file(target_scene_path)
	
	# 3. Toca a animação ao contrário para clarear a tela (Fade In)
	animation_player.play_backwards("fade")
	await animation_player.animation_finished
