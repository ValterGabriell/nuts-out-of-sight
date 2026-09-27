extends Node3D

@export_category("Movimento Suave")
@export var limite_deslocamento: float = 3.0
@export var velocidade_suavizacao: float = 5.0
@export var sensibilidade_mouse_offset: float = 0.002

@export_category("Rotação em Graus")
@export var angulo_rotacao_graus: float = 45.0
@export var velocidade_transicao_rotacao: float = 8.0

@export_category("Zoom")
@export var velocidade_do_zoom: float = 2.0
@export var zoom_min: float = 5.0
@export var zoom_max: float = 30.0

@export var camera: Camera3D

enum EstadoDoTremor {
	PARADO,
	EM_ANDAMENTO
}

var _offset_alvo: Vector3 = Vector3.ZERO
var _offset_atual: Vector3 = Vector3.ZERO
var _angulo_y_alvo: float = 0.0
var _posicao_acumulada: Vector2 = Vector2.ZERO
var _posicao_inicial_camera: Vector3 = Vector3.ZERO
var _zoom_atual_z: float = 0.0
var _estado_do_tremor: EstadoDoTremor = EstadoDoTremor.PARADO

func _ready() -> void:
	_posicao_inicial_camera = camera.position
	_zoom_atual_z = _posicao_inicial_camera.z
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func configurar_pose_inicial(posicao_local: Vector3, rotacao_graus_local: Vector3) -> void:
	camera.position = posicao_local
	camera.rotation_degrees = rotacao_graus_local
	_posicao_inicial_camera = camera.position
	_zoom_atual_z = _posicao_inicial_camera.z
	_offset_alvo = Vector3.ZERO
	_offset_atual = Vector3.ZERO
	_posicao_acumulada = Vector2.ZERO

func _process(delta: float) -> void:
	_atualizar_deslocamento_camera(delta)
	_atualizar_rotacao_suave(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_posicao_acumulada.x += event.relative.x * sensibilidade_mouse_offset
		_posicao_acumulada.y += event.relative.y * sensibilidade_mouse_offset
		_posicao_acumulada = _posicao_acumulada.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))

	if event.is_action_pressed("rotacionar_camera_esquerda"):
		_angulo_y_alvo += deg_to_rad(angulo_rotacao_graus)

	if event.is_action_pressed("rotacionar_camera_direita"):
		_angulo_y_alvo -= deg_to_rad(angulo_rotacao_graus)

	if event.is_action_pressed("zoom_aproximar"):
		_aplicar_zoom(-velocidade_do_zoom)

	if event.is_action_pressed("zoom_afastar"):
		_aplicar_zoom(velocidade_do_zoom)

func _atualizar_deslocamento_camera(delta: float) -> void:
	var input_analogico := Input.get_vector(
		"mover_camera_esquerda",
		"mover_camera_direita",
		"mover_camera_frente",
		"mover_camera_tras"
	)

	if input_analogico.length() > 0.0:
		_posicao_acumulada.x += input_analogico.x * delta * 2.0
		_posicao_acumulada.y += input_analogico.y * delta * 2.0
		_posicao_acumulada = _posicao_acumulada.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))

	_offset_alvo = Vector3(_posicao_acumulada.x, 0.0, _posicao_acumulada.y) * limite_deslocamento
	_offset_atual = _offset_atual.lerp(_offset_alvo, velocidade_suavizacao * delta)

	camera.position.x = _posicao_inicial_camera.x + _offset_atual.x
	camera.position.z = _zoom_atual_z + _offset_atual.z

func _atualizar_rotacao_suave(delta: float) -> void:
	camera.rotation.y = lerp_angle(camera.rotation.y, _angulo_y_alvo, velocidade_transicao_rotacao * delta)

func _aplicar_zoom(valor: float) -> void:
	_zoom_atual_z = clamp(
		_zoom_atual_z + valor,
		zoom_min,
		zoom_max
	)

func executar_tremor(duracao_em_segundos: float, intensidade: float) -> void:
	if camera == null:
		return

	if duracao_em_segundos <= 0.0 or intensidade <= 0.0:
		return

	_estado_do_tremor = EstadoDoTremor.EM_ANDAMENTO
	var duracao_limitada: float = max(duracao_em_segundos, 0.01)
	var tempo_decorrido: float = 0.0

	while tempo_decorrido < duracao_limitada:
		var progresso: float = clampf(tempo_decorrido / duracao_limitada, 0.0, 1.0)
		var intensidade_atual: float = lerpf(intensidade, 0.0, progresso)
		camera.h_offset = randf_range(-intensidade_atual, intensidade_atual)
		camera.v_offset = randf_range(-intensidade_atual, intensidade_atual)
		await get_tree().process_frame
		tempo_decorrido += get_process_delta_time()

	camera.h_offset = 0.0
	camera.v_offset = 0.0
	_estado_do_tremor = EstadoDoTremor.PARADO
