class_name AreasDeAparecimentoDasFolhas
extends Node3D

@export var area_spawn: Area3D
@export var cena_folha: PackedScene 
@export var quantidade_inicial_de_folhas: int = 15
@export var percentual_folhas_no_pre_aviso: float = 0.35
@export var deslocamento_pre_aviso: float = 0.45
@export var deslocamento_rajada: float = 1.2
@export var duracao_movimento_pre_aviso: float = 1.0
@export var duracao_movimento_rajada: float = 0.5
@export var quantidade_estagios_pre_aviso: int = 4
@export var intensidade_inicial_pre_aviso: float = 0.15
@export var expoente_de_intensificacao_pre_aviso: float = 2.2

enum DirecaoDoVento {
	NORTE,
	SUL,
	LESTE,
	OESTE
}

func _ready() -> void:
	spawnar_folhas_na_area(quantidade_inicial_de_folhas)

func spawnar_folhas_na_area(quantidade: int) -> void:
	if not area_spawn or not cena_folha:
		return

	var shape_node: CollisionShape3D = null
	for child in area_spawn.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			shape_node = child
			break

	if not shape_node:
		return

	var box: BoxShape3D = shape_node.shape
	var tamanho_box = box.size 
	var centro_box = shape_node.global_position
	var min_x = centro_box.x - (tamanho_box.x / 2.0)
	var max_x = centro_box.x + (tamanho_box.x / 2.0)
	var min_z = centro_box.z - (tamanho_box.z / 2.0)
	var max_z = centro_box.z + (tamanho_box.z / 2.0)

	for i in range(quantidade):
		var x_rand = randf_range(min_x, max_x)
		var z_rand = randf_range(min_z, max_z)
		var pos_mundo = Vector3(x_rand, centro_box.y, z_rand)

		var folha_instancia = cena_folha.instantiate()
		add_child(folha_instancia)
		folha_instancia.global_position = pos_mundo

func aplicar_pre_aviso_de_vento(direcao: int, duracao_pre_aviso: float) -> void:
	var folhas = _obter_folhas_ativas()
	if folhas.is_empty():
		return

	var quantidade_previa = maxi(1, int(round(float(folhas.size()) * clamp(percentual_folhas_no_pre_aviso, 0.1, 1.0))))
	var folhas_para_mover = _selecionar_folhas_aleatorias(folhas, quantidade_previa)
	_aplicar_pre_aviso_progressivo(folhas_para_mover, direcao, duracao_pre_aviso)

func aplicar_vento(direcao: int) -> void:
	var folhas = _obter_folhas_ativas()
	if folhas.is_empty():
		return
	_mover_folhas_por_vento(folhas, direcao, deslocamento_rajada, duracao_movimento_rajada)

func _obter_folhas_ativas() -> Array[Node3D]:
	var folhas: Array[Node3D] = []
	for child in get_children():
		if child is ItemQueFazBarulho and child is Node3D:
			folhas.append(child as Node3D)
	return folhas

func _selecionar_folhas_aleatorias(folhas: Array[Node3D], quantidade: int) -> Array[Node3D]:
	var copia = folhas.duplicate()
	copia.shuffle()
	return copia.slice(0, mini(quantidade, copia.size()))

func _mover_folhas_por_vento(folhas: Array[Node3D], direcao: int, distancia: float, duracao: float) -> void:
	var vetor_direcao = _direcao_para_vetor(direcao)
	if vetor_direcao == Vector3.ZERO:
		return

	for folha in folhas:
		var variacao = randf_range(0.85, 1.15)
		var deslocamento_final = vetor_direcao * distancia * variacao
		var destino = _limitar_posicao_na_area_spawn(folha.global_position + deslocamento_final)
		var tween = folha.create_tween()
		tween.tween_property(folha, "global_position", destino, max(duracao, 0.05))\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

func _aplicar_pre_aviso_progressivo(folhas: Array[Node3D], direcao: int, duracao_total: float) -> void:
	var vetor_direcao = _direcao_para_vetor(direcao)
	if vetor_direcao == Vector3.ZERO:
		return

	var etapas = maxi(2, quantidade_estagios_pre_aviso)
	var duracao_por_etapa = max(duracao_total / float(etapas), 0.05)
	var intensidade_inicial = clamp(intensidade_inicial_pre_aviso, 0.01, 1.0)
	var expoente = max(expoente_de_intensificacao_pre_aviso, 1.0)

	for folha in folhas:
		var tween = folha.create_tween()
		for etapa in range(etapas):
			var progresso = float(etapa + 1) / float(etapas)
			var progresso_intensificado = pow(progresso, expoente)
			var intensidade_atual = lerp(intensidade_inicial, 1.0, progresso_intensificado)
			var variacao = randf_range(0.9, 1.1)
			var deslocamento_atual = deslocamento_pre_aviso * intensidade_atual * variacao
			var destino = _limitar_posicao_na_area_spawn(folha.global_position + (vetor_direcao * deslocamento_atual))
			tween.tween_property(folha, "global_position", destino, duracao_por_etapa)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)

func _direcao_para_vetor(direcao: int) -> Vector3:
	match direcao:
		DirecaoDoVento.NORTE:
			return Vector3(0.0, 0.0, -1.0)
		DirecaoDoVento.SUL:
			return Vector3(0.0, 0.0, 1.0)
		DirecaoDoVento.LESTE:
			return Vector3(1.0, 0.0, 0.0)
		DirecaoDoVento.OESTE:
			return Vector3(-1.0, 0.0, 0.0)
		_:
			return Vector3.ZERO

func _limitar_posicao_na_area_spawn(posicao: Vector3) -> Vector3:
	if not area_spawn:
		return posicao

	var shape_node = _obter_collision_box_da_area_spawn()
	if not shape_node:
		return posicao

	var box: BoxShape3D = shape_node.shape
	var metade_x = box.size.x * 0.5
	var metade_z = box.size.z * 0.5
	var centro = shape_node.global_position

	return Vector3(
		clamp(posicao.x, centro.x - metade_x, centro.x + metade_x),
		posicao.y,
		clamp(posicao.z, centro.z - metade_z, centro.z + metade_z)
	)

func _obter_collision_box_da_area_spawn() -> CollisionShape3D:
	if not area_spawn:
		return null

	for child in area_spawn.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			return child
	return null