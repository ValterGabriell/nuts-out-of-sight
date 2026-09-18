extends Node


enum AreasDeFolhas {
	PRINCIPAL
}

var quantidade_de_folhas_por_area : Dictionary[AreasDeFolhas, int] = {
	AreasDeFolhas.PRINCIPAL: 250
}

func _ready() -> void:
	GlobalGerenciadorDeSinais.estoque_atingiu_maximo_pra_aquele_dia.connect(atualizar_folhas)

func atualizar_folhas() -> void:
	aumentar_quantidade_de_folhas(AreasDeFolhas.PRINCIPAL, 75)

func aumentar_quantidade_de_folhas(area: AreasDeFolhas, quantidade: int) -> void:
	if quantidade_de_folhas_por_area.has(area):
		quantidade_de_folhas_por_area[area] += quantidade
	else:
		quantidade_de_folhas_por_area[area] = quantidade

func diminuir_quantidade_de_folhas(area: AreasDeFolhas, quantidade: int) -> void:
	if quantidade_de_folhas_por_area.has(area):
		quantidade_de_folhas_por_area[area] = max(quantidade_de_folhas_por_area[area] - quantidade, 0)