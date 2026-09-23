class_name AreasDeAparecimentoDasFolhas
extends Node3D

@export var areas_de_spawn: Array[ConfiguracaoAreaDeSpawnFolhas] = []
@export var cena_da_folha: PackedScene 
@export var duracao_minima_por_estagio_pre_aviso_em_segundos: float = 1.0
@export var duracao_rajada_em_segundos: float = 1
@export var quantidade_de_estagios_pre_aviso: int = 4
@export var expoente_de_intensificacao_pre_aviso: float = 2.2
@export var fator_aleatorio_minimo_pre_aviso: float = 0.9
@export var fator_aleatorio_maximo_pre_aviso: float = 1.6
@export var fator_minimo_forca_frontal_rajada: float = 0.6
@export var fator_maximo_forca_frontal_rajada: float = 2.1
@export var fator_desvio_lateral_rajada: float = 0.35
@export var duracao_cauda_rajada_em_segundos: float = 0.35
@export var percentual_extra_cauda_rajada: float = 0.18

var indice_da_area_por_id_da_folha: Dictionary = {}
var posicao_base_por_id_da_folha: Dictionary = {}
var tween_por_id_da_folha: Dictionary = {}

enum DirecaoDoVento {
	NORTE,
	SUL,
	LESTE,
	OESTE
}

func _ready() -> void:
	add_to_group("persistencia_de_folhas")
	spawnar_folhas_em_todas_as_areas()
	_restaurar_snapshot_de_folhas_da_cena_atual()

func obter_snapshot_para_salvamento() -> Dictionary:
	var folhas_por_area = _obter_folhas_ativas_por_area()
	var snapshot: Dictionary = {
		"folhas_por_area": {}
	}

	var folhas_por_area_serializadas: Dictionary = snapshot["folhas_por_area"]
	for indice_area in folhas_por_area.keys():
		var folhas_da_area: Array[Node3D] = folhas_por_area[indice_area]
		var posicoes_serializadas: Array = []
		for folha in folhas_da_area:
			posicoes_serializadas.append(_serializar_posicao_global(folha.global_position))
		folhas_por_area_serializadas[str(indice_area)] = posicoes_serializadas

	return snapshot

func aplicar_snapshot_do_salvamento(snapshot: Dictionary) -> void:
	var folhas_por_area_ativas = _obter_folhas_ativas_por_area()
	var folhas_por_area_salvas: Dictionary = snapshot.get("folhas_por_area", {}) as Dictionary
	if folhas_por_area_salvas == null:
		return

	for chave_indice_area: Variant in folhas_por_area_salvas.keys():
		var indice_area = int(chave_indice_area)
		if not folhas_por_area_ativas.has(indice_area):
			continue

		var folhas_da_area: Array[Node3D] = folhas_por_area_ativas[indice_area]
		var posicoes_salvas: Array = folhas_por_area_salvas[chave_indice_area] as Array
		if posicoes_salvas == null:
			continue

		var quantidade_para_reposicionar = mini(folhas_da_area.size(), posicoes_salvas.size())
		for indice_folha in range(quantidade_para_reposicionar):
			var folha = folhas_da_area[indice_folha]
			var posicao_restaurada = _desserializar_posicao_global(posicoes_salvas[indice_folha])
			folha.global_position = posicao_restaurada
			posicao_base_por_id_da_folha[folha.get_instance_id()] = posicao_restaurada

func _restaurar_snapshot_de_folhas_da_cena_atual() -> void:
	if not GlobalGerenciadorDeSalvamento:
		return

	var snapshot = GlobalGerenciadorDeSalvamento.obter_snapshot_de_folhas_da_cena_atual_para(self)
	if snapshot.is_empty():
		return
	aplicar_snapshot_do_salvamento(snapshot)

func spawnar_folhas_em_todas_as_areas() -> void:
	if not cena_da_folha:
		return
	for indice_area in range(areas_de_spawn.size()):
		spawnar_folhas_na_area(indice_area)

func spawnar_folhas_na_area(indice_area: int) -> void:
	if indice_area < 0 or indice_area >= areas_de_spawn.size() or not cena_da_folha:
		return

	var area = _obter_area_por_indice(indice_area)
	if not area:
		return

	var quantidade = max(0, area.quantidade_inicial_de_folhas)

	var shape_node: CollisionShape3D = null
	for child in area.get_children():
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
	var quantidade_de_celulas = max(quantidade, 1)
	var colunas = maxi(1, int(ceil(sqrt(float(quantidade_de_celulas)))))
	var linhas = maxi(1, int(ceil(float(quantidade_de_celulas) / float(colunas))))

	var indices_de_celulas: Array[int] = []
	for indice_celula in range(colunas * linhas):
		indices_de_celulas.append(indice_celula)
	indices_de_celulas.shuffle()

	for i in range(quantidade):
		var indice_celula = indices_de_celulas[i % indices_de_celulas.size()]
		var coluna = indice_celula % colunas
		var linha = int(indice_celula / colunas)

		var passo_x = (max_x - min_x) / float(colunas)
		var passo_z = (max_z - min_z) / float(linhas)
		var x_min_celula = min_x + (passo_x * float(coluna))
		var x_max_celula = x_min_celula + passo_x
		var z_min_celula = min_z + (passo_z * float(linha))
		var z_max_celula = z_min_celula + passo_z

		var x_rand = randf_range(x_min_celula, x_max_celula)
		var z_rand = randf_range(z_min_celula, z_max_celula)
		var pos_mundo = Vector3(x_rand, centro_box.y, z_rand)

		var folha_instancia = cena_da_folha.instantiate()
		add_child(folha_instancia)
		folha_instancia.global_position = pos_mundo
		var id_folha = folha_instancia.get_instance_id()
		indice_da_area_por_id_da_folha[id_folha] = indice_area
		posicao_base_por_id_da_folha[id_folha] = pos_mundo

func aplicar_pre_aviso_de_vento(direcao: int, duracao_pre_aviso: float) -> void:
	var folhas_por_area = _obter_folhas_ativas_por_area()
	for indice_area in folhas_por_area.keys():
		var area = _obter_area_por_indice(indice_area)
		if not area:
			continue
		var folhas: Array[Node3D] = folhas_por_area[indice_area]
		if folhas.is_empty():
			continue
		var quantidade_previa = maxi(1, int(round(float(folhas.size()) * clamp(area.percentual_de_folhas_no_pre_aviso, 0.1, 1.0))))
		var folhas_para_mover = _selecionar_folhas_aleatorias(folhas, quantidade_previa)
		_aplicar_pre_aviso_progressivo(folhas_para_mover, direcao, duracao_pre_aviso, indice_area)

func registrar_posicoes_base_das_folhas_ativas() -> void:
	for folha in _obter_folhas_ativas():
		posicao_base_por_id_da_folha[folha.get_instance_id()] = folha.global_position

func aplicar_vento(direcao: int) -> void:
	# Garante que a rajada parta sempre da posicao atual, sem "puxar" para tras.
	registrar_posicoes_base_das_folhas_ativas()

	var folhas_por_area = _obter_folhas_ativas_por_area()
	for indice_area in folhas_por_area.keys():
		var area = _obter_area_por_indice(indice_area)
		if not area:
			continue
		var folhas: Array[Node3D] = folhas_por_area[indice_area]
		if folhas.is_empty():
			continue
		_mover_folhas_por_vento(folhas, direcao, area.deslocamento_base_rajada_em_metros, duracao_rajada_em_segundos, indice_area)

func _obter_folhas_ativas() -> Array[Node3D]:
	var folhas: Array[Node3D] = []
	for child in get_children():
		if child is ItemQueFazBarulho and child is Node3D:
			folhas.append(child as Node3D)
	return folhas

func _obter_folhas_ativas_por_area() -> Dictionary:
	var folhas_por_area: Dictionary = {}
	for indice_area in range(areas_de_spawn.size()):
		folhas_por_area[indice_area] = [] as Array[Node3D]

	for folha in _obter_folhas_ativas():
		var indice_area = _obter_indice_da_area_da_folha(folha)
		if not folhas_por_area.has(indice_area):
			folhas_por_area[indice_area] = [] as Array[Node3D]
		(folhas_por_area[indice_area] as Array[Node3D]).append(folha)

	return folhas_por_area

func _obter_indice_da_area_da_folha(folha: Node3D) -> int:
	var id_folha = folha.get_instance_id()
	if indice_da_area_por_id_da_folha.has(id_folha):
		return int(indice_da_area_por_id_da_folha[id_folha])
	return 0

func _selecionar_folhas_aleatorias(folhas: Array[Node3D], quantidade: int) -> Array[Node3D]:
	var copia = folhas.duplicate()
	copia.shuffle()
	return copia.slice(0, mini(quantidade, copia.size()))

func _mover_folhas_por_vento(folhas: Array[Node3D], direcao: int, distancia: float, duracao: float, indice_area: int) -> void:
	var vetor_direcao = _direcao_para_vetor(direcao)
	if vetor_direcao == Vector3.ZERO:
		return
	var min_forca = min(fator_minimo_forca_frontal_rajada, fator_maximo_forca_frontal_rajada)
	var max_forca = max(fator_minimo_forca_frontal_rajada, fator_maximo_forca_frontal_rajada)
	var duracao_principal = max(duracao, 0.05)
	var duracao_cauda = max(duracao_cauda_rajada_em_segundos, 0.05)
	var percentual_cauda = max(percentual_extra_cauda_rajada, 0.0)

	for folha in folhas:
		var posicao_base = _obter_posicao_base_da_folha(folha)
		var forca_frontal = randf_range(min_forca, max_forca)
		var deslocamento_frontal = vetor_direcao * distancia * forca_frontal
		var destino_principal = _limitar_posicao_na_area_spawn(posicao_base + deslocamento_frontal, indice_area)
		var destino_cauda = _limitar_posicao_na_area_spawn(destino_principal + (vetor_direcao * distancia * forca_frontal * percentual_cauda), indice_area)
		var tween = _criar_tween_da_folha(folha)
		tween.tween_property(folha, "global_position", destino_principal, duracao_principal)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(folha, "global_position", destino_cauda, duracao_cauda)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

func _aplicar_pre_aviso_progressivo(folhas: Array[Node3D], direcao: int, duracao_total: float, indice_area: int) -> void:
	var vetor_direcao = _direcao_para_vetor(direcao)
	if vetor_direcao == Vector3.ZERO:
		return
	var area = _obter_area_por_indice(indice_area)
	if not area:
		return

	var etapas = maxi(2, quantidade_de_estagios_pre_aviso)
	var duracao_minima = max(duracao_minima_por_estagio_pre_aviso_em_segundos, 0.05)
	if (duracao_total / float(etapas)) < duracao_minima:
		etapas = maxi(1, int(floor(duracao_total / duracao_minima)))
	var duracao_por_etapa = max(duracao_total / float(etapas), 0.05)
	var intensidade_inicial = clamp(area.percentual_inicial_de_intensidade_pre_aviso, 0.01, 1.0)
	var expoente = max(expoente_de_intensificacao_pre_aviso, 1.0)
	var min_aleatorio = min(fator_aleatorio_minimo_pre_aviso, fator_aleatorio_maximo_pre_aviso)
	var max_aleatorio = max(fator_aleatorio_minimo_pre_aviso, fator_aleatorio_maximo_pre_aviso)

	for folha in folhas:
		var posicao_base = _obter_posicao_base_da_folha(folha)
		var variacao = randf_range(min_aleatorio, max_aleatorio)
		var tween = _criar_tween_da_folha(folha)

		for etapa in range(etapas):
			var progresso = float(etapa + 1) / float(etapas)
			var progresso_intensificado = pow(progresso, expoente)
			var intensidade_atual = lerp(intensidade_inicial, 1.0, progresso_intensificado)
			var deslocamento_atual = area.deslocamento_pre_aviso_em_metros * intensidade_atual * variacao
			var destino = _limitar_posicao_na_area_spawn(posicao_base + (vetor_direcao * deslocamento_atual), indice_area)
			tween.tween_property(folha, "global_position", destino, duracao_por_etapa)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN)

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

func _limitar_posicao_na_area_spawn(posicao: Vector3, indice_area: int) -> Vector3:
	var shape_node = _obter_collision_box_da_area_spawn(indice_area)
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

func _obter_collision_box_da_area_spawn(indice_area: int) -> CollisionShape3D:
	var area = _obter_area_por_indice(indice_area)
	if not area:
		return null

	for child in area.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			return child
	return null

func _obter_area_por_indice(indice_area: int) -> ConfiguracaoAreaDeSpawnFolhas:
	if indice_area < 0 or indice_area >= areas_de_spawn.size():
		return null
	return areas_de_spawn[indice_area]

func _obter_posicao_base_da_folha(folha: Node3D) -> Vector3:
	var id_folha = folha.get_instance_id()
	if posicao_base_por_id_da_folha.has(id_folha):
		return posicao_base_por_id_da_folha[id_folha] as Vector3
	posicao_base_por_id_da_folha[id_folha] = folha.global_position
	return folha.global_position

func _criar_tween_da_folha(folha: Node3D) -> Tween:
	var id_folha = folha.get_instance_id()
	if tween_por_id_da_folha.has(id_folha):
		var tween_anterior = tween_por_id_da_folha[id_folha] as Tween
		if tween_anterior and tween_anterior.is_running():
			tween_anterior.kill()

	var tween_novo = folha.create_tween()
	tween_por_id_da_folha[id_folha] = tween_novo
	return tween_novo

func _serializar_posicao_global(posicao: Vector3) -> Dictionary:
	return {
		"x": posicao.x,
		"y": posicao.y,
		"z": posicao.z
	}

func _desserializar_posicao_global(posicao_serializada: Variant) -> Vector3:
	if posicao_serializada is Dictionary:
		var dados: Dictionary = posicao_serializada as Dictionary
		return Vector3(
			float(dados.get("x", 0.0)),
			float(dados.get("y", 0.0)),
			float(dados.get("z", 0.0))
		)
	if posicao_serializada is Vector3:
		return posicao_serializada as Vector3
	return Vector3.ZERO