extends Node

signal estoque_atualizado(quantidade_total_de_itens: int)

var itens_por_tipo: Dictionary = {
	ItemColetavel.TipoItem.COLETAVEL_NOZ: 0,
	ItemColetavel.TipoItem.COLETAVEL_NOZ_PESADA: 0
}

var quantidade_total_de_itens: int = 0

const MAX_QUANTIDADE_DE_ITENS: int = 4

func _ready() -> void:
	quantidade_total_de_itens = obter_quantidade_total_de_itens()
	estoque_atualizado.emit(quantidade_total_de_itens)

func guardar_itens(itens_para_guardar: Array[int]) -> Array[int]:
	var itens_guardados: Array[int] = []
	var espaco_disponivel: int = MAX_QUANTIDADE_DE_ITENS - quantidade_total_de_itens
	if espaco_disponivel <= 0:
		return itens_guardados

	for tipo_item: int in itens_para_guardar:
		if itens_guardados.size() >= espaco_disponivel:
			break
		if not itens_por_tipo.has(tipo_item):
			itens_por_tipo[tipo_item] = 0
		itens_por_tipo[tipo_item] += 1
		itens_guardados.append(tipo_item)

	if itens_guardados.is_empty():
		return itens_guardados

	quantidade_total_de_itens = obter_quantidade_total_de_itens()
	print("Itens guardados. Quantidade total de itens: %d" % quantidade_total_de_itens)
	estoque_atualizado.emit(quantidade_total_de_itens)
	if quantidade_total_de_itens >= MAX_QUANTIDADE_DE_ITENS:
		GlobalGerenciadorDeSinais.estoque_atingiu_maximo_pra_aquele_dia.emit()
	return itens_guardados

func guardar_item(tipo_item: int) -> bool:
	if quantidade_total_de_itens >= MAX_QUANTIDADE_DE_ITENS:
		return false
	if not itens_por_tipo.has(tipo_item):
		itens_por_tipo[tipo_item] = 0
	itens_por_tipo[tipo_item] += 1
	quantidade_total_de_itens = obter_quantidade_total_de_itens()
	estoque_atualizado.emit(quantidade_total_de_itens)
	return true

func obter_quantidade_total_de_itens() -> int:
	var quantidade_total: int = 0
	for quantidade: int in itens_por_tipo.values():
		quantidade_total += quantidade
	return quantidade_total

func obter_quantidade_por_tipo(tipo_item: int) -> int:
	if not itens_por_tipo.has(tipo_item):
		return 0
	return int(itens_por_tipo[tipo_item])

func limpar_estoque() -> void:
	itens_por_tipo = {
		ItemColetavel.TipoItem.COLETAVEL_NOZ: 0,
		ItemColetavel.TipoItem.COLETAVEL_NOZ_PESADA: 0
	}
	quantidade_total_de_itens = 0
	estoque_atualizado.emit(quantidade_total_de_itens)

func retornar_itens_guardados() -> Array[int]:
	var itens: Array[int] = []
	for tipo_item: int in itens_por_tipo.keys():
		for i in range(itens_por_tipo[tipo_item]):
			itens.append(tipo_item)
	return itens

func obter_snapshot_para_salvamento() -> Dictionary:
	var itens_por_tipo_serializados: Dictionary = {}
	for tipo_item: int in itens_por_tipo.keys():
		itens_por_tipo_serializados[str(tipo_item)] = int(itens_por_tipo[tipo_item])

	return {
		"itens_por_tipo": itens_por_tipo_serializados,
		"quantidade_total_de_itens": quantidade_total_de_itens
	}

func carregar_snapshot_do_salvamento(snapshot_do_estoque: Dictionary) -> void:
	if snapshot_do_estoque.is_empty():
		return

	var itens_por_tipo_do_salvamento: Dictionary = snapshot_do_estoque.get("itens_por_tipo", {}) as Dictionary
	if itens_por_tipo_do_salvamento == null:
		itens_por_tipo_do_salvamento = {}

	itens_por_tipo.clear()
	for tipo_item_serializado: Variant in itens_por_tipo_do_salvamento.keys():
		var tipo_item: int = int(String(tipo_item_serializado))
		itens_por_tipo[tipo_item] = int(itens_por_tipo_do_salvamento[tipo_item_serializado])

	quantidade_total_de_itens = obter_quantidade_total_de_itens()
	estoque_atualizado.emit(quantidade_total_de_itens)