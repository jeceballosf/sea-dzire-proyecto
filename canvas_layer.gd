extends CanvasLayer

@onready var label: Label = $ContadorLabel

func _ready() -> void:
	await get_tree().process_frame
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		push_error("No se encontró al jugador en el grupo 'jugador'")
		return
	jugador.basura_cambiada.connect(_actualizar)
	_actualizar(jugador.basura_recogida, jugador.MAX_BASURA)

func _actualizar(cantidad: int, maximo: int) -> void:
	label.text = "Basura: %d / %d" % [cantidad, maximo]
	if cantidad >= maximo:
		label.text += "  ¡LLENO!"
