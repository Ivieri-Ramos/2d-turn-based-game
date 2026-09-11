class_name TransitionZone extends Area2D

signal transition_triggered(new_map: String, off_set: Vector2)

enum TipoTransicao {
	CONTIGUA,
	DISCRETA
}

@export_file("*.tscn") var cena_destino: String = ""

@export var tipo_transicao: TipoTransicao = TipoTransicao.CONTIGUA

@export_group("Discreta")
@export var spawn_point_id: String 

@export_group("Contigua")
@export var offset_matematico: Vector2 = Vector2.ZERO

func _ready() -> void:
	area_entered.connect(_ao_encostar_no_portal)
	

func _ao_encostar_no_portal(area: Area2D) -> void:
	
	if cena_destino:
		transition_triggered.emit(cena_destino, offset_matematico)
	
