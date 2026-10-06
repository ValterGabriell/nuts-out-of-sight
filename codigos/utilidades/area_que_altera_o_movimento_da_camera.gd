extends Area3D

enum EstadoArea {
	NAO_PASSOU,
	PASSOU_PRA_OUTRA_AREA
}

## Identificador único desta área (ex: "Entrada_Estoque", "Corredor_Caminho")
@export var id_area: String = "Area_01"

## Estado atual da transição desta área
var estado_atual: EstadoArea = EstadoArea.NAO_PASSOU

@export var area_do_jogador_ao_entrar: GlobalGerenciadorDeSinais.AreaAtualJogador = GlobalGerenciadorDeSinais.AreaAtualJogador.AREA_PRINCIPAL
@export var area_do_jogador_ao_sair: GlobalGerenciadorDeSinais.AreaAtualJogador = GlobalGerenciadorDeSinais.AreaAtualJogador.AREA_PRINCIPAL
@export var duracao_do_movimento_automatico_em_segundos: float = 1.85

@export var configuracao: AreaQueAlteraOMovimentoCameraRecurso

## O Node3D da cena que define a posição/rotação do novo pivot (Área Y)
@export var nova_posicao_pivot_camera: Node3D 

## O Pivot real da câmera
@export var camera_pivot: Node3D 

# Guarda o transform anterior especificamente para esta área
var transform_pivot_anterior: Transform3D
var has_previous_pivot_transform: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	await get_tree().physics_frame
	for overlapping_body in get_overlapping_bodies():
		_on_body_entered(overlapping_body)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Jogador") or camera_pivot == null or nova_posicao_pivot_camera == null:
		return
	if estado_atual == EstadoArea.PASSOU_PRA_OUTRA_AREA:
		return

	# Cache current pivot transform before entering this area.
	transform_pivot_anterior = camera_pivot.global_transform
	has_previous_pivot_transform = true
	GlobalGerenciadorDeSinais.iniciar_transicao_de_area_com_camera(id_area, duracao_do_movimento_automatico_em_segundos)
	camera_pivot.aplicar_novo_pivot(id_area, nova_posicao_pivot_camera.global_transform, configuracao)
	GlobalGerenciadorDeSinais.atualizar_area_atual_do_jogador(area_do_jogador_ao_entrar)
	estado_atual = EstadoArea.PASSOU_PRA_OUTRA_AREA

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Jogador") or camera_pivot == null:
		return
	if estado_atual != EstadoArea.PASSOU_PRA_OUTRA_AREA:
		return
	if not has_previous_pivot_transform:
		return

	# O controle deve voltar assim que o jogador sair desta Area3D.
	GlobalGerenciadorDeSinais.encerrar_transicao_de_area_com_camera(id_area)
	estado_atual = EstadoArea.NAO_PASSOU

	if camera_pivot.has_method("area_ativa_corresponde"):
		var esta_area_ainda_ativa: bool = camera_pivot.call("area_ativa_corresponde", id_area)
		if not esta_area_ainda_ativa:
			return

	camera_pivot.aplicar_novo_pivot(id_area, transform_pivot_anterior, configuracao)
	GlobalGerenciadorDeSinais.atualizar_area_atual_do_jogador(area_do_jogador_ao_sair)
