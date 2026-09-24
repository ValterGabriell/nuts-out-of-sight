class_name Jogador extends CharacterBody3D

enum EstadoVisibilidadeJogador {
	VISIVEL,
	ESCONDIDO,
}

enum CenaAtual{
	PRINCIPAL,
	CABANA
}

var velocidade_atual: float = VELOCIDADE_PADRAO
const VELOCIDADE_PADRAO: float = 2
const JUMP_VELOCITY = 4.5

@export var camera_pivot: Node3D
@export var estado_visibilidade: EstadoVisibilidadeJogador = EstadoVisibilidadeJogador.VISIVEL
@export var urso: Urso
@export var cena_atual: CenaAtual = CenaAtual.PRINCIPAL

func _ready() -> void:
	if camera_pivot == null:
		camera_pivot = get_node_or_null("Camera")


func esconder() -> void:
	estado_visibilidade = EstadoVisibilidadeJogador.ESCONDIDO


func revelar() -> void:
	estado_visibilidade = EstadoVisibilidadeJogador.VISIVEL
