class_name Player extends CharacterBody3D

@export var speed: float = 3.0
@export var gravity: float = -9.8
@export var jump_impulse: float = 4.5
@export var rotation_velocity: float = 10.0
@export var sprint_multiplier: float = 1.6
@export var slide_speed_multiplier: float = 2.0
@export var voltereta_pivote_y: float = 0.5

const MAX_SALTOS := 2
const COYOTE_TIME := 0.12
const MAX_BASURA := 12
const RADIO_RECOGIDA := 2.0
const JUMP_GRACE := 0.15
const VOLTERETA_TIME := 0.45
const SLIDE_ACEL := 0.25

var saltos_usados: int = 0
var coyote_timer: float = 0.0
var basura_recogida: int = 0
var deslizando: bool = false
var slide_timer: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO
var slide_start_speed: float = 0.0
var jump_grace_timer: float = 0.0
var _slide_time: float = 0.7
var _voltereta_tween: Tween
var _model_base_position: Vector3

var _skeleton: Skeleton3D
var _hips_idx: int = 0
var _hips_rest: Vector3 = Vector3.ZERO
var _corregir_con_senal: bool = false

signal basura_cambiada(cantidad: int, maximo: int)

@onready var _orbital_camera: Node3D = $OrbitalCamera
@onready var _model: Node3D = $Model
@onready var _anim_tree: AnimationTree = $AnimationTree
var _playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	add_to_group("jugador")
	_model_base_position = _model.position
	_anim_tree.active = true
	_playback = _anim_tree.get("parameters/playback")
	_configurar_slide()

func _configurar_slide() -> void:
	var ap := _anim_tree.get_node_or_null(_anim_tree.anim_player) as AnimationPlayer
	if ap and ap.has_animation(&"Slide"):
		_slide_time = clampf(ap.get_animation(&"Slide").length, 0.4, 1.2)

	_skeleton = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skeleton == null:
		push_warning("No se encontró Skeleton3D dentro de Model")
		return

	_hips_idx = 0
	for i in _skeleton.get_bone_count():
		if _skeleton.get_bone_name(i).to_lower().contains("hip"):
			_hips_idx = i
			break

	_hips_rest = _posicion_cadera_local(true)
	print("Slide: cadera = ", _skeleton.get_bone_name(_hips_idx))

	if _anim_tree.has_signal(&"mixer_applied"):
		_anim_tree.connect(&"mixer_applied", _corregir_deslizamiento)
		_corregir_con_senal = true

func _posicion_cadera_local(usar_rest: bool) -> Vector3:
	var hueso: Transform3D
	if usar_rest:
		hueso = _skeleton.get_bone_global_rest(_hips_idx)
	else:
		hueso = _skeleton.get_bone_global_pose(_hips_idx)
	return _model.global_transform.affine_inverse() * (_skeleton.global_transform * hueso.origin)

func _corregir_deslizamiento() -> void:
	if not deslizando or _skeleton == null:
		return
	var d: Vector3 = _posicion_cadera_local(false) - _hips_rest
	d.y = 0.0
	_model.position = _model_base_position - _model.transform.basis * d

func _velocidad_slide() -> float:
	var t: float = 1.0 - clampf(slide_timer / _slide_time, 0.0, 1.0)
	var pico: float = slide_start_speed * slide_speed_multiplier
	if t < SLIDE_ACEL:
		var u: float = t / SLIDE_ACEL
		return lerpf(slide_start_speed, pico, 1.0 - pow(1.0 - u, 2.0))
	var u2: float = (t - SLIDE_ACEL) / (1.0 - SLIDE_ACEL)
	return lerpf(pico, slide_start_speed, smoothstep(0.0, 1.0, u2))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor():
		saltos_usados = 0
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if jump_grace_timer > 0.0:
		jump_grace_timer -= delta

	if Input.is_action_just_pressed(&"Jump"):
		if coyote_timer > 0.0:
			velocity.y = jump_impulse
			coyote_timer = 0.0
			saltos_usados = 1
			deslizando = false
			jump_grace_timer = JUMP_GRACE
			_cancelar_voltereta()
			_playback.start(&"Jump")
		elif saltos_usados < MAX_SALTOS:
			velocity.y = jump_impulse
			saltos_usados += 1
			deslizando = false
			jump_grace_timer = JUMP_GRACE
			_playback.start(&"Fall")
			_voltereta()

	var corriendo: bool = Input.is_action_pressed(&"Sprint")
	var current_speed: float = speed * (sprint_multiplier if corriendo else 1.0)

	var directional_input: Vector2 = Input.get_vector(&"Left", &"Right", &"Up", &"Down")

	if Input.is_action_just_pressed(&"Slide") and is_on_floor() and directional_input != Vector2.ZERO and not deslizando:
		var dir_slide: Vector3 = _orbital_camera.global_transform.basis.z * directional_input.y + _orbital_camera.global_transform.basis.x * directional_input.x
		deslizando = true
		slide_timer = _slide_time
		slide_start_speed = current_speed
		slide_direction = dir_slide.normalized()
		_model.rotation.y = atan2(slide_direction.x, slide_direction.z)
		_model.position = _model_base_position
		_playback.start(&"Slide")

	if deslizando:
		slide_timer -= delta
		var slide_speed: float = _velocidad_slide()
		velocity.x = slide_direction.x * slide_speed
		velocity.z = slide_direction.z * slide_speed
		if slide_timer <= 0.0 or not is_on_floor():
			deslizando = false
			_restaurar_modelo()
	elif directional_input:
		var movement_direction: Vector3 = _orbital_camera.global_transform.basis.z * directional_input.y + _orbital_camera.global_transform.basis.x * directional_input.x
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(movement_direction.x, movement_direction.z), rotation_velocity * delta)

		velocity.x = movement_direction.x * current_speed
		velocity.z = movement_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	if Input.is_action_just_pressed(&"recoger"):
		_intentar_recoger()

	_actualizar_animacion()

	if not _corregir_con_senal:
		_corregir_deslizamiento()

func _voltereta() -> void:
	_cancelar_voltereta()
	_voltereta_tween = create_tween()
	_voltereta_tween.tween_method(_aplicar_voltereta, 0.0, TAU, VOLTERETA_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_voltereta_tween.tween_callback(_restaurar_modelo)

func _aplicar_voltereta(angulo: float) -> void:
	_model.rotation.x = angulo
	var desplazamiento := Vector3(
		0.0,
		voltereta_pivote_y - voltereta_pivote_y * cos(angulo),
		-voltereta_pivote_y * sin(angulo)
	)
	_model.position = _model_base_position + Basis(Vector3.UP, _model.rotation.y) * desplazamiento

func _restaurar_modelo() -> void:
	_model.rotation.x = 0.0
	_model.position = _model_base_position

func _cancelar_voltereta() -> void:
	if _voltereta_tween and _voltereta_tween.is_valid():
		_voltereta_tween.kill()
	_restaurar_modelo()

func _actualizar_animacion() -> void:
	if deslizando or jump_grace_timer > 0.0:
		return

	var actual: StringName = _playback.get_current_node()
	var en_aire: bool = not is_on_floor() and coyote_timer <= 0.0
	var estado: StringName

	if en_aire:
		estado = &"Fall"
	elif Vector2(velocity.x, velocity.z).length() > 0.1:
		estado = &"Run" if Input.is_action_pressed(&"Sprint") else &"Walk"
	else:
		estado = &"Idle"

	if actual == estado:
		return

	if actual == &"Jump" or actual == &"Slide":
		_playback.start(estado)
	else:
		_playback.travel(estado)

func puede_recoger() -> bool:
	return basura_recogida < MAX_BASURA

func recoger_basura() -> void:
	basura_recogida += 1
	basura_cambiada.emit(basura_recogida, MAX_BASURA)
	print("Basura: ", basura_recogida, "/", MAX_BASURA)

func _intentar_recoger() -> void:
	if not puede_recoger():
		return
	for basura in get_tree().get_nodes_in_group("basura"):
		if global_position.distance_to(basura.global_position) <= RADIO_RECOGIDA:
			recoger_basura()
			basura.queue_free()
			return
