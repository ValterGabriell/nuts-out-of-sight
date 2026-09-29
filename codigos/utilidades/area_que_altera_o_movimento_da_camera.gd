extends Area3D

enum EstadoArea {
	NAO_PASSOU,
	PASSOU_PRA_OUTRA_AREA
}

## Identificador único desta área (ex: "Entrada_Estoque", "Corredor_Caminho")
@export var id_area: String = "Area_01"

## Estado atual da transição desta área
var estado_atual: EstadoArea = EstadoArea.NAO_PASSOU

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
	camera_pivot.aplicar_novo_pivot(id_area, nova_posicao_pivot_camera.global_transform, configuracao)
	estado_atual = EstadoArea.PASSOU_PRA_OUTRA_AREA

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Jogador") or camera_pivot == null:
		return
	if estado_atual != EstadoArea.PASSOU_PRA_OUTRA_AREA:
		return
	if not has_previous_pivot_transform:
		return

	camera_pivot.aplicar_novo_pivot(id_area, transform_pivot_anterior, configuracao)
	estado_atual = EstadoArea.NAO_PASSOU
