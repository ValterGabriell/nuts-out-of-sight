class_name ItemQueFazBarulho
extends Node3D

enum ItemTipo {
	FOLHA
}

enum TipoDeAreaDePropagacaoDoSom {
	CILINDRICA
}

@export var tipoDoItem: ItemTipo = ItemTipo.FOLHA
@export var tipoDeAreaDePropagacaoDoSom: TipoDeAreaDePropagacaoDoSom = TipoDeAreaDePropagacaoDoSom.CILINDRICA
@export var quantidade_de_barulho_em_pixels_em_area_anelar : float = 1.0
@export var cena_onda_de_som: PackedScene
@export var area_de_propagacao_do_som: Area3D

@export var raio_maximo_propagacao: float = 5.0
@export var duracao_propagacao: float = 0.6
@export var raio_minimo_propagacao: float = 0.1
@export var duracao_minima_propagacao: float = 0.05

var collision_shape_propagacao: CollisionShape3D
var tween_propagacao: Tween

func _ready() -> void:
	if area_de_propagacao_do_som:
		for child in area_de_propagacao_do_som.get_children():
			if child is CollisionShape3D:
				collision_shape_propagacao = child
				break

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.adicionar_item_fazendo_barulho(self)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.remover_item_fazendo_barulho(self)
		var raio_propagacao_atual = _obter_raio_propagacao_atual()
		var duracao_propagacao_atual = _obter_duracao_propagacao_atual()
		var onda = cena_onda_de_som.instantiate()
		get_tree().current_scene.add_child(onda)
		if onda and onda.has_method("configurar_propagacao_por_barulho"):
			onda.configurar_propagacao_por_barulho(quantidade_de_barulho_em_pixels_em_area_anelar, raio_propagacao_atual, duracao_propagacao_atual)
		var pos_ajustada = global_position
		pos_ajustada.y += 0.1
		onda.global_position = pos_ajustada
		iniciar_propagacao_fisica(raio_propagacao_atual, duracao_propagacao_atual)

func iniciar_propagacao_fisica(raio_alvo: float, duracao_alvo: float) -> void:
	collision_shape_propagacao.shape = collision_shape_propagacao.shape.duplicate()
	if tween_propagacao and tween_propagacao.is_running():
		tween_propagacao.kill()

	tween_propagacao = create_tween()
	tween_propagacao.tween_method(_atualizar_raio_area, raio_minimo_propagacao, raio_alvo, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	tween_propagacao.tween_method(_atualizar_raio_area, raio_alvo, 0.0, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _obter_raio_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	return max(raio_maximo_propagacao * fator_barulho, raio_minimo_propagacao)

func _obter_duracao_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	return max(duracao_propagacao * fator_barulho, duracao_minima_propagacao)

func _atualizar_raio_area(raio_atual: float) -> void:
	match tipoDeAreaDePropagacaoDoSom:
		TipoDeAreaDePropagacaoDoSom.CILINDRICA:
			if collision_shape_propagacao.shape is CylinderShape3D:
				(collision_shape_propagacao.shape as CylinderShape3D).radius = raio_atual