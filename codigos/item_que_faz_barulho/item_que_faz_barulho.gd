class_name ItemQueFazBarulho
extends Node3D

enum ItemTipo {
	FOLHA
}

enum TipoDeAreaDePropagacaoDoSom {
	CILINDRICA
}

enum EstadoShaderOndaDeSom {
	DISPARAR,
	BLOQUEAR,
}

@export var tipoDoItem: ItemTipo = ItemTipo.FOLHA
@export var tipoDeAreaDePropagacaoDoSom: TipoDeAreaDePropagacaoDoSom = TipoDeAreaDePropagacaoDoSom.CILINDRICA
@export var quantidade_de_barulho_em_pixels_em_area_anelar: float = 3.0
@export var cena_onda_de_som: PackedScene
@export var area_de_propagacao_do_som: Area3D
@export var area_que_detecta_urso_pra_acordar: AreaQueDetectaUrsoPraAcordar
@export var raio_maximo_propagacao: float = 5.0
@export var multiplicador_raio_colisao_som: float = 3.0
@export var duracao_propagacao: float = 0.6
@export var raio_minimo_propagacao: float = 0.1
@export var duracao_minima_propagacao: float = 0.05

var collision_shape_propagacao: CollisionShape3D
var tween_propagacao: Tween
var urso_referencia: Urso

func _ready() -> void:
	urso_referencia = _obter_urso_referencia()

	if area_de_propagacao_do_som:
		for child in area_de_propagacao_do_som.get_children():
			if child is CollisionShape3D:
				collision_shape_propagacao = child
				if collision_shape_propagacao.shape:
					collision_shape_propagacao.shape = collision_shape_propagacao.shape.duplicate()
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
	var estado_shader_onda_de_som_atual = _obter_estado_shader_onda_de_som()

	if estado_shader_onda_de_som_atual == EstadoShaderOndaDeSom.DISPARAR and cena_atual and cena_onda_de_som:
		var onda = cena_onda_de_som.instantiate()
		if onda:
			if onda.has_method("configurar_propagacao_por_barulho"):
				onda.configurar_propagacao_por_barulho(quantidade_de_barulho_em_pixels_em_area_anelar, raio_propagacao_atual, duracao_propagacao_atual)
			cena_atual.add_child(onda)
			if onda is Node3D:
				var pos_ajustada = posicao_item
				pos_ajustada.y += 0.1
				(onda as Node3D).global_position = pos_ajustada
	
	if estado_shader_onda_de_som_atual == EstadoShaderOndaDeSom.BLOQUEAR:
		if area_de_propagacao_do_som and area_de_propagacao_do_som.has_method("desativar_rastreamento"):
			area_de_propagacao_do_som.desativar_rastreamento()
		return

	iniciar_propagacao_fisica(raio_propagacao_atual, duracao_propagacao_atual)

func iniciar_propagacao_fisica(raio_alvo: float, duracao_alvo: float) -> void:
	if area_de_propagacao_do_som == null:
		return

	if _obter_estado_shader_onda_de_som() == EstadoShaderOndaDeSom.BLOQUEAR:
		if area_de_propagacao_do_som.has_method("desativar_rastreamento"):
			area_de_propagacao_do_som.desativar_rastreamento()
		return

	if area_de_propagacao_do_som.has_method("ativar_rastreamento"):
		area_de_propagacao_do_som.ativar_rastreamento()

	if collision_shape_propagacao == null:
		return

	var shape_propagacao := collision_shape_propagacao.shape as CylinderShape3D
	if shape_propagacao == null:
		return

	var raio_original = shape_propagacao.radius
	shape_propagacao.radius = raio_minimo_propagacao
	if tween_propagacao and tween_propagacao.is_running():
		tween_propagacao.kill()

	tween_propagacao = create_tween()
	tween_propagacao.tween_method(_atualizar_raio_area_temporaria.bind(shape_propagacao), raio_minimo_propagacao, raio_alvo, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween_propagacao.tween_method(_atualizar_raio_area_temporaria.bind(shape_propagacao), raio_alvo, raio_original, duracao_alvo * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween_propagacao.finished.connect(_on_tween_propagacao_finalizado, CONNECT_ONE_SHOT)

func _obter_raio_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	var raio_base: float = max(raio_maximo_propagacao * fator_barulho, raio_minimo_propagacao)
	return raio_base * max(multiplicador_raio_colisao_som, 1.0)

func _obter_duracao_propagacao_atual() -> float:
	var fator_barulho = max(quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)
	return max(duracao_propagacao * fator_barulho, duracao_minima_propagacao)

func _obter_estado_shader_onda_de_som() -> EstadoShaderOndaDeSom:
	urso_referencia = _obter_urso_referencia()
	if urso_referencia == null:
		return EstadoShaderOndaDeSom.DISPARAR

	match urso_referencia.estado_atual:
		Urso.EstadoUrso.PERSEGUINDO:
			return EstadoShaderOndaDeSom.BLOQUEAR
		Urso.EstadoUrso.DORMINDO, Urso.EstadoUrso.EM_ALERTA:
			return EstadoShaderOndaDeSom.DISPARAR

	return EstadoShaderOndaDeSom.DISPARAR


func _obter_urso_referencia() -> Urso:
	if area_que_detecta_urso_pra_acordar != null and area_que_detecta_urso_pra_acordar.urso != null:
		return area_que_detecta_urso_pra_acordar.urso

	if urso_referencia != null and is_instance_valid(urso_referencia):
		return urso_referencia

	var primeiro_urso_no_grupo: Node = get_tree().get_first_node_in_group("urso")
	if primeiro_urso_no_grupo is Urso:
		return primeiro_urso_no_grupo

	return null

func _atualizar_raio_area_temporaria(raio_atual: float, shape: CylinderShape3D) -> void:
	if shape == null:
		return

	match tipoDeAreaDePropagacaoDoSom:
		TipoDeAreaDePropagacaoDoSom.CILINDRICA:
			shape.radius = raio_atual


func _on_tween_propagacao_finalizado() -> void:
	if area_de_propagacao_do_som and area_de_propagacao_do_som.has_method("desativar_rastreamento"):
		area_de_propagacao_do_som.desativar_rastreamento()
