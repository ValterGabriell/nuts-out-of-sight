class_name AreaQueDetectaUrsoPraAcordar
extends Area3D

enum EstadoRastreamento {
	DESATIVADO,
	ATIVADO,
}

@export var estado_rastreamento_inicial: EstadoRastreamento = EstadoRastreamento.DESATIVADO

var urso: Urso
var estado_rastreamento_atual: EstadoRastreamento = EstadoRastreamento.DESATIVADO


func _ready() -> void:
	estado_rastreamento_atual = estado_rastreamento_inicial


func ativar_rastreamento() -> void:
	estado_rastreamento_atual = EstadoRastreamento.ATIVADO


func desativar_rastreamento() -> void:
	estado_rastreamento_atual = EstadoRastreamento.DESATIVADO


func _on_body_entered(body: Node3D) -> void:
	if estado_rastreamento_atual != EstadoRastreamento.ATIVADO:
		return
	if body is Urso and body.has_method("registrar_disparo_de_barulho_detectado"):
		if body.estado_atual == Urso.EstadoUrso.PERSEGUINDO:
			desativar_rastreamento()
			return
		body.registrar_disparo_de_barulho_detectado()
		urso = body




