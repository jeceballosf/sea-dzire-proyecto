extends Control

const RANGO := 30.0  # metros que cubre el mini mapa

var jugador: Player

func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -220.0
	offset_right = -20.0
	offset_top = 20.0
	offset_bottom = 220.0
	await get_tree().process_frame
	jugador = get_tree().get_first_node_in_group("jugador")

func _process(_delta: float) -> void:
	queue_redraw()

func _proyectar(v: Vector3, cam_basis: Basis) -> Vector2:
	return Vector2(
		v.x * cam_basis.x.x + v.z * cam_basis.x.z,
		v.x * cam_basis.z.x + v.z * cam_basis.z.z
	)

func _draw() -> void:
	var centro := size / 2.0
	var radio := minf(size.x, size.y) / 2.0

	draw_circle(centro, radio, Color(0, 0, 0, 0.5))
	draw_arc(centro, radio, 0.0, TAU, 48, Color.WHITE, 2.0)

	if jugador == null:
		return

	var cam_basis: Basis = jugador._orbital_camera.global_transform.basis

	# Jugador: flecha que apunta hacia donde mira el personaje
	var frente: Vector2 = _proyectar(jugador._model.global_transform.basis.z, cam_basis)
	if frente.length() < 0.001:
		frente = Vector2(0.0, -1.0)
	frente = frente.normalized()
	var lado: Vector2 = frente.orthogonal()
	var flecha := PackedVector2Array([
		centro + frente * 12.0,
		centro - frente * 7.0 + lado * 7.0,
		centro - frente * 7.0 - lado * 7.0
	])
	draw_colored_polygon(flecha, Color.WHITE)

	# Basura
	for basura in get_tree().get_nodes_in_group("basura"):
		if not is_instance_valid(basura) or not (basura is Node3D):
			continue
		var d: Vector3 = basura.global_position - jugador.global_position
		var p: Vector2 = _proyectar(d, cam_basis)
		p = p / RANGO * radio
		if p.length() > radio - 4.0:
			p = p.normalized() * (radio - 4.0)
		draw_circle(centro + p, 4.0, Color.YELLOW)
