class_name AreaParaGuardarOsItens
extends Area3D

@export var espacamento_entre_itens: float = 0.6
@export var altura_do_spawn: float = 0.1

var _proximo_indice_de_spawn: int = 0
var _cache_colunas: int = -1
var _cache_linhas: int = -1
var _ordem_slots_cache: Array[Vector2i] = []

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	_spawnar_itens_ja_guardados_no_estoque()


func spawnar_itens(tipos_itens: Array[int]) -> void:
	for tipo_item: int in tipos_itens:
		_spawnar_item_no_proximo_slot(tipo_item)


func _on_area_entered(area: Area3D) -> void:
	var item: ItemColetavel = area as ItemColetavel
	if item == null:
		return
	if item.has_meta("spawnado_pelo_estoque"):
		return
	if not GlobalEstoque.guardar_item(item.tipo_item):
		return
	if item.has_meta("id_item_dropado_no_mundo"):
		GlobalGerenciadorDeSalvamento.remover_item_dropado_da_cena_atual(StringName(item.get_meta("id_item_dropado_no_mundo")))

	item.set_meta("spawnado_pelo_estoque", true)
	GlobalGerenciadorDeSalvamento.salvar_jogo(GlobalGerenciadorDeSalvamento.MotivoDeSalvamento.GUARDAR_NO_ESTOQUE)


func _spawnar_itens_ja_guardados_no_estoque() -> void:
	_limpar_visuais_atuais_do_estoque()
	_proximo_indice_de_spawn = 0
	var tipos_itens_guardados: Array[int] = GlobalEstoque.retornar_itens_guardados()
	if tipos_itens_guardados.is_empty():
		return
	call_deferred("spawnar_itens", tipos_itens_guardados)


func _limpar_visuais_atuais_do_estoque() -> void:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	for no_filho: Node in cena_atual.get_children():
		var item_coletavel: ItemColetavel = no_filho as ItemColetavel
		if item_coletavel == null:
			continue
		if not item_coletavel.has_meta("spawnado_pelo_estoque"):
			continue
		item_coletavel.queue_free()


func _spawnar_item_no_proximo_slot(tipo_item: int) -> void:
	var item_instanciado: ItemColetavel = GlobalItensQueOJogadorCarrega.criar_item_por_tipo(tipo_item)
	if item_instanciado == null:
		return

	item_instanciado.set_meta("spawnado_pelo_estoque", true)
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	var posicao_do_spawn: Vector3 = _obter_posicao_do_proximo_slot()
	cena_atual.call_deferred("add_child", item_instanciado)
	item_instanciado.call_deferred("largar_na_posicao", posicao_do_spawn)


func _obter_posicao_do_proximo_slot() -> Vector3:
	if _collision_shape == null:
		return global_position

	var box_shape: BoxShape3D = _collision_shape.shape as BoxShape3D
	if box_shape == null:
		return global_position

	var local_extents: Vector3 = box_shape.size * 0.5
	local_extents *= _collision_shape.transform.basis.get_scale().abs()

	var largura: float = local_extents.x * 2.0
	var profundidade: float = local_extents.z * 2.0
	var colunas: int = maxi(int(floor(largura / espacamento_entre_itens)) + 1, 1)
	var linhas: int = maxi(int(floor(profundidade / espacamento_entre_itens)) + 1, 1)
	var ordem_slots: Array[Vector2i] = _obter_ordem_de_slots_centro_para_extremos(colunas, linhas)
	var quantidade_slots_por_camada: int = max(colunas * linhas, 1)

	var indice_atual: int = _proximo_indice_de_spawn
	_proximo_indice_de_spawn += 1

	var indice_na_camada: int = indice_atual % quantidade_slots_por_camada
	var camada_vertical: int = int(floor(float(indice_atual) / float(quantidade_slots_por_camada)))
	var slot: Vector2i = ordem_slots[indice_na_camada]
	var indice_coluna: int = slot.x
	var indice_linha: int = slot.y

	var deslocamento_x: float = -local_extents.x + (float(indice_coluna) * espacamento_entre_itens)
	var deslocamento_z: float = -local_extents.z + (float(indice_linha) * espacamento_entre_itens)
	var deslocamento_y: float = local_extents.y + altura_do_spawn + (float(camada_vertical) * 0.08)

	var centro_local_da_area: Vector3 = _collision_shape.transform.origin
	var ponto_local: Vector3 = centro_local_da_area + Vector3(deslocamento_x, deslocamento_y, deslocamento_z)
	return to_global(ponto_local)


func _obter_ordem_de_slots_centro_para_extremos(colunas: int, linhas: int) -> Array[Vector2i]:
	if _cache_colunas == colunas and _cache_linhas == linhas and not _ordem_slots_cache.is_empty():
		return _ordem_slots_cache

	var centro_coluna: float = (float(colunas) - 1.0) * 0.5
	var centro_linha: float = (float(linhas) - 1.0) * 0.5
	var slots_com_distancia: Array[Dictionary] = []

	for linha: int in range(linhas):
		for coluna: int in range(colunas):
			var delta_coluna: float = float(coluna) - centro_coluna
			var delta_linha: float = float(linha) - centro_linha
			slots_com_distancia.append({
				"slot": Vector2i(coluna, linha),
				"distancia2": (delta_coluna * delta_coluna) + (delta_linha * delta_linha),
				"linha": linha,
				"coluna": coluna
			})

	slots_com_distancia.sort_custom(_comparar_slots_por_centro)

	var ordem_slots: Array[Vector2i] = []
	for info_slot: Dictionary in slots_com_distancia:
		ordem_slots.append(info_slot["slot"])

	_cache_colunas = colunas
	_cache_linhas = linhas
	_ordem_slots_cache = ordem_slots
	return _ordem_slots_cache


func _comparar_slots_por_centro(a: Dictionary, b: Dictionary) -> bool:
	var distancia_a: float = a["distancia2"]
	var distancia_b: float = b["distancia2"]
	if distancia_a == distancia_b:
		var linha_a: int = a["linha"]
		var linha_b: int = b["linha"]
		if linha_a == linha_b:
			return a["coluna"] < b["coluna"]
		return linha_a < linha_b
	return distancia_a < distancia_b


