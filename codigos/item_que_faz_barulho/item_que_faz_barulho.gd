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
@export var quantidade_de_barulho_em_pixels_em_area_anelar: float = 1.0
@export var cena_onda_de_som: PackedScene
@export var area_de_propagacao_do_som: Area3D

@export var raio_maximo_propagacao: float = 5.0
@export var duracao_propagacao: float = 0.6
@export var raio_minimo_propagacao: float = 0.1
@export var duracao_minima_propagacao: float = 0.05

var collision_shape_propagacao: CollisionShape3D
var altura_shape_propagacao: float = 1.0
var tween_propagacao: Tween

func _ready() -> void:
	if area_de_propagacao_do_som:
		for child in area_de_propagacao_do_som.get_children():
			if child is CollisionShape3D:
				collision_shape_propagacao = child
				if collision_shape_propagacao.shape is CylinderShape3D:
					altura_shape_propagacao = (collision_shape_propagacao.shape as CylinderShape3D).height
				break

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.adicionar_item_fazendo_barulho(self)
		_disparar_onda_de_som_e_propagacao()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.remover_item_fazendo_barulho(self)

func _disparar_onda_de_som_e_propagacao() -> void:
	if not is_inside_tree():
		return

	var posicao_item = global_position
	var raio_propagacao_atual = _obter_raio_propagacao_atual()
	var duracao_propagacao_atual = _obter_duracao_propagacao_atual()
	var cena_atual = get_tree().current_scene

	if cena_atual and cena_onda_de_som:
		var onda = cena_onda_de_som.instantiate()
		if onda:
			if onda.has_method("configurar_propagacao_por_barulho"):
				onda.configurar_propagacao_por_barulho(quantidade_de_barulho_em_pixels_em_area_anelar, raio_propagacao_atual, duracao_propagacao_atual)
			cena_atual.add_child(onda)
			if onda is Node3D:
				var pos_ajustada = posicao_item
				pos_ajustada.y += 0.1
				(onda as Node3D).global_position = pos_ajustada

	iniciar_propagacao_fisica(raio_propagacao_atual, duracao_propagacao_atual, posicao_item)

func iniciar_propagacao_fisica(raio_alvo: float, duracao_alvo: float, posicao_origem: Vector3) -> void:
	if area_de_propagacao_do_som == null:
		return

	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return

	var area_temporaria = Area3D.new()
	area_temporaria.monitoring = true
	area_temporaria.monitorable = true
	area_temporaria.collision_layer = area_de_propagacao_do_som.collision_layer
	area_temporaria.collision_mask = area_de_propagacao_do_som.collision_mask

	var collision_shape_temporario = CollisionShape3D.new()
	var shape_temporario = CylinderShape3D.new()
	shape_temporario.radius = raio_minimo_propagacao
	shape_temporario.height = altura_shape_propagacao
	collision_shape_temporario.shape = shape_temporario
	area_temporaria.add_child(collision_shape_temporario)

	var pos_ajustada = posicao_origem
	pos_ajustada.y += 0.1
	cena_atual.add_child(area_temporaria)
	area_temporaria.global_position = pos_ajustada

	if tween_propagacao and tween_propagacao.is_running():
		tween_propagacao.kill()

	tween_propagacao = area_temporaria.create_tween()
	tween_propagacao.tween_method(_atualizar_raio_area_temporaria.bind(shape_temporario), raio_minimo_propagacao, raio_alvo, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween_propagacao.tween_method(_atualizar_raio_area_temporaria.bind(shape_temporario), raio_alvo, 0.0, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween_propagacao.tween_callback(area_temporaria.queue_free)

func _obter_raio_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	return max(raio_maximo_propagacao * fator_barulho, raio_minimo_propagacao)

func _obter_duracao_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	return max(duracao_propagacao * fator_barulho, duracao_minima_propagacao)

func _atualizar_raio_area_temporaria(raio_atual: float, shape: CylinderShape3D) -> void:
	if shape == null:
		return

	match tipoDeAreaDePropagacaoDoSom:
		TipoDeAreaDePropagacaoDoSom.CILINDRICA:
			shape.radius = raio_atual
