class_name GameButton extends TextureButton

@onready var label: Label = $Label

@export var button_text: String = "":
	set(value):
		button_text = value
		if is_node_ready():
			label.text = value

func _ready() -> void:
	label.text = button_text
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	pass

func _on_pressed() -> void:
	pass
