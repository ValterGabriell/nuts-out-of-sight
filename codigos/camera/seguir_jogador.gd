class_name SeguirJogador
extends Node3D

@export var jogador: Node3D
@export var camera_pivot: Node3D
@export var velocidade: float = 5.0

const POSICAO_LOCAL_PADRAO_CAMERA: Vector3 = Vector3(0.0, 3.0, 4.0)
const ROTACAO_GRAUS_LOCAL_PADRAO_CAMERA: Vector3 = Vector3(-45.0, 0.0, 0.0)
const OFFSET_FIXO_DO_JOGADOR: Vector3 = Vector3(0.0, 0.5, 0.0)

var _offset_do_jogador: Vector3 = OFFSET_FIXO_DO_JOGADOR

func _ready() -> void:
	if camera_pivot == null:
		camera_pivot = get_parent_node_3d()

	_offset_do_jogador = _obter_offset_arredondado()
	_aplicar_pose_padrao_da_camera()
	_alinhar_camera_no_jogador_imediatamente()

func _physics_process(delta: float) -> void:
	if jogador == null or camera_pivot == null:
		return

	var target_position: Vector3 = jogador.global_position + _offset_do_jogador
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, velocidade * delta)

func configurar_para_jogador(jogador_alvo: Node3D, camera_pivot_alvo: Node3D) -> void:
	jogador = jogador_alvo
	camera_pivot = camera_pivot_alvo
	_offset_do_jogador = _obter_offset_arredondado()
	_aplicar_pose_padrao_da_camera()
	_alinhar_camera_no_jogador_imediatamente()

func _obter_offset_arredondado() -> Vector3:
	var offset_arredondado_y: float = snappedf(OFFSET_FIXO_DO_JOGADOR.y, 0.1)
	return Vector3(0.0, offset_arredondado_y, 0.0)

func _alinhar_camera_no_jogador_imediatamente() -> void:
	if jogador == null:
		return

	if camera_pivot == null:
		return

	camera_pivot.global_position = jogador.global_position + _offset_do_jogador

func _aplicar_pose_padrao_da_camera() -> void:
	if camera_pivot == null:
		return

	if camera_pivot.has_method("configurar_pose_inicial"):
		camera_pivot.call(
			"configurar_pose_inicial",
			POSICAO_LOCAL_PADRAO_CAMERA,
			ROTACAO_GRAUS_LOCAL_PADRAO_CAMERA
		)