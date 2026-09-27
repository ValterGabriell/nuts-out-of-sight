class_name AreaQueDetectaUrsoPraAcordar
extends Area3D

enum EstadoRastreamento {
	DESATIVADO,
	ATIVADO,
}

const BARULHO_POR_VEZ :float= 5.0

@export var estado_rastreamento_inicial: EstadoRastreamento = EstadoRastreamento.DESATIVADO

var urso: Urso
var estado_rastreamento_atual: EstadoRastreamento = EstadoRastreamento.DESATIVADO
var ja_disparou_neste_ciclo_de_rastreamento: bool = false


func _ready() -> void:
	estado_rastreamento_atual = estado_rastreamento_inicial
	ja_disparou_neste_ciclo_de_rastreamento = false


func ativar_rastreamento() -> void:
	estado_rastreamento_atual = EstadoRastreamento.ATIVADO
	ja_disparou_neste_ciclo_de_rastreamento = false


func desativar_rastreamento() -> void:
	estado_rastreamento_atual = EstadoRastreamento.DESATIVADO
	ja_disparou_neste_ciclo_de_rastreamento = false


func _on_body_entered(body: Node3D) -> void:
	if estado_rastreamento_atual != EstadoRastreamento.ATIVADO:
		return

	if ja_disparou_neste_ciclo_de_rastreamento:
		return

	if body is Caverna and body.has_method("registrar_disparo_de_barulho_detectado"):
		body.registrar_disparo_de_barulho_detectado(BARULHO_POR_VEZ)
		ja_disparou_neste_ciclo_de_rastreamento = true
