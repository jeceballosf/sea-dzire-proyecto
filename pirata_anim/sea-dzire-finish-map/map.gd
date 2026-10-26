@tool
extends Node3D

@export_group("Pack Kenney - Asigna tus escenas")
@export var block_grass_scene: PackedScene
@export var block_snow_scene: PackedScene
@export var tree_green_scene: PackedScene
@export var tree_snow_scene: PackedScene
@export var barrel_scene: PackedScene
@export var fence_scene: PackedScene
@export var ladder_scene: PackedScene
@export var bridge_scene: PackedScene

@export_group("Config")
@export var block_size: float = 2.0
@export var clear_before: bool = true
@export_tool_button("🐟 GENERAR MAPA ISLA", "Callable") var gen_btn = generar_mapa

var container: Node3D

func generar_mapa():
	print("🐟 Generando mapa Isla Pez - Solo geometría")
	if clear_before:
		for c in get_children():
			c.queue_free()
		await get_tree().process_frame
	
	container = Node3D.new()
	container.name = "Mapa_Isla_Pez"
	add_child(container)
	container.owner = get_tree().edited_scene_root
	
	_crear_cuerpo_pez()
	_crear_montana_central()
	_crear_cola_triple()
	_crear_muelle()
	_crear_bosque()
	_crear_escaleras()
	
	print("✅ Mapa generado - Sin basuras ni dispensador")

func spawn(scn: PackedScene, pos: Vector3, rot: float = 0.0) -> Node3D:
	if not scn: return null
	var n = scn.instantiate()
	n.position = pos
	n.rotation_degrees.y = rot
	container.add_child(n)
	n.owner = get_tree().edited_scene_root
	return n

func bloque(pos: Vector3i, es_nieve: bool = false):
	var scn = block_snow_scene if es_nieve else block_grass_scene
	spawn(scn, Vector3(pos.x * block_size, pos.y * block_size, pos.z * block_size))

func _crear_cuerpo_pez():
	# Cuerpo ovalado del pez - todo pasto
	# Coordenadas ajustadas a tu boceto pero sin markers
	var body_coords = [
		# Fila por fila del pez
		Vector2i(-4, -2), Vector2i(-4, -1), Vector2i(-4, 0), Vector2i(-4, 1), Vector2i(-4, 2),
		Vector2i(-3, -3), Vector2i(-3, -2), Vector2i(-3, -1), Vector2i(-3, 0), Vector2i(-3, 1), Vector2i(-3, 2), Vector2i(-3, 3),
		Vector2i(-2, -4), Vector2i(-2, -3), Vector2i(-2, -2), Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-2, 1), Vector2i(-2, 2), Vector2i(-2, 3),
		Vector2i(-1, -4), Vector2i(-1, -3), Vector2i(-1, -2), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(-1, 2), Vector2i(-1, 3), Vector2i(-1, 4),
		Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, -4), Vector2i(1, -3), Vector2i(1, -2), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4),
		Vector2i(2, -3), Vector2i(2, -2), Vector2i(2, -1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3),
		Vector2i(3, -2), Vector2i(3, -1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2),
		Vector2i(4, -1), Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2),
		Vector2i(5, 0), Vector2i(5, 1), Vector2i(5, 2),
	]
	for c in body_coords:
		bloque(Vector3i(c.x, 0, c.y), false)

func _crear_montana_central():
	# Lomo del pez - montaña nevada escalonada (4 pisos)
	var center = Vector3i(0, 0, 0)
	# Piso 0 ya está en cuerpo, ahora pisos 1-3
	for x in range(-2, 3):
		for z in range(-2, 3):
			if abs(x) + abs(z) <= 3:
				bloque(Vector3i(center.x + x, 1, center.z + z), true)
	for x in range(-1, 2):
		for z in range(-1, 2):
			bloque(Vector3i(center.x + x, 2, center.z + z), true)
	bloque(Vector3i(center.x, 3, center.z), true)

func _crear_cola_triple():
	# Cola triple a la izquierda (como en tu boceto)
	var cola_base_x = -7
	# Aleta superior
	bloque(Vector3i(cola_base_x, 0, -3))
	bloque(Vector3i(cola_base_x-1, 0, -4))
	bloque(Vector3i(cola_base_x-2, 0, -5))
	# Aleta media
	bloque(Vector3i(cola_base_x, 0, 0))
	bloque(Vector3i(cola_base_x-1, 0, 0))
	bloque(Vector3i(cola_base_x-2, 0, 0))
	# Aleta inferior
	bloque(Vector3i(cola_base_x, 0, 3))
	bloque(Vector3i(cola_base_x-1, 0, 4))
	bloque(Vector3i(cola_base_x-2, 0, 5))

func _crear_muelle():
	# Muelle sureste - 3x4 de madera
	# Usamos bloques normales pero más bajos visualmente
	var origin = Vector3i(4, 0, 5)
	for x in range(3):
		for z in range(3):
			var b = spawn(block_grass_scene, Vector3((origin.x + x)*block_size, -0.8, (origin.z + z)*block_size))
			if b: b.scale.y = 0.6 # más bajo para simular muelle
	# Barriles decorativos del muelle
	spawn(barrel_scene, Vector3(4.5*block_size, 0, 5.5*block_size))
	spawn(barrel_scene, Vector3(5.0*block_size, 0, 5.5*block_size))

func _crear_bosque():
	# Bosque oeste
	var arboles = [
		Vector3(-6,0,2), Vector3(-5,0,1), Vector3(-6,0,-1),
		Vector3(-4,0,2), Vector3(-5,0,-2), Vector3(-4,0,-1),
		Vector3(-3,0,1.5), Vector3(-3,0,-0.5)
	]
	for p in arboles:
		spawn(tree_green_scene, p*block_size + Vector3(0, block_size, 0), randf()*360)
		if randf() > 0.5:
			spawn(tree_snow_scene, (p + Vector3(0.4,0,0.4))*block_size + Vector3(0, block_size, 0), randf()*360)
	
	# Cercas alrededor
	for i in range(6):
		spawn(fence_scene, Vector3((-6 + i)*block_size, 0, 2.5*block_size), 0)
	for i in range(4):
		spawn(fence_scene, Vector3(-6*block_size, 0, (2.5 - i)*block_size), 90)

func _crear_escaleras():
	# Escaleras subiendo la montaña nevada
	var escaleras = [
		Vector3(1.2, 0, 1.2), Vector3(0.8, 1, 0.5),
		Vector3(0, 2, -1), Vector3(-0.8, 1, -0.5),
		Vector3(3, 0, 2), Vector3(3, 0, 4) # hacia el muelle
	]
	for p in escaleras:
		spawn(ladder_scene, p*block_size)
