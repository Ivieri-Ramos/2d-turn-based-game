class_name OverworldPlayer extends OverworldEntity

@onready var state_chart: StateChart = $StateChart

@export_group("Components")

@export var input_handler: InputHandler = null

@export var grid_movement: GridMovement = null

@export_group("StateChart References")

@export var idle_state: AtomicState = null

@export var move_state: AtomicState = null

func _ready() -> void:
	super._ready()
	
	idle_state.state_entered.connect(input_handler._on_idle_state_entered)
	idle_state.state_processing.connect(input_handler._on_idle_state_processing)
	
	move_state.state_entered.connect(grid_movement._on_move_state_entered)
