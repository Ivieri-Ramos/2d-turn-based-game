extends CanvasLayer

signal attack_pressed
signal special_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_attack_button_pressed() -> void:
	attack_pressed.emit()
	
func _on_especial_button_pressed() -> void:
	special_pressed.emit()
	
