extends Area3D

@export var valor: int = 1

func _ready():
	# Esto conecta la señal automáticamente cuando el juego empieza, sin usar el menú de Godot
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Si lo que toca el residuo es el jugador
	if body.name == "Player" or body.is_in_group("Player"):
		if body.has_method("sumar_residuo"):
			body.sumar_residuo(valor)
		
		# Borra el objeto del mapa
		queue_free()
