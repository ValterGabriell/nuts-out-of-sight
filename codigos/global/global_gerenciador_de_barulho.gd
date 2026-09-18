extends Node


var atual_quantidade_de_barulho_em_pixels_em_area_anelar : float = 0.0
var itens_atuais_fazendo_barulho : Array[ItemQueFazBarulho] = []

func adicionar_item_fazendo_barulho(item: ItemQueFazBarulho) -> void:
	itens_atuais_fazendo_barulho.append(item)
	atual_quantidade_de_barulho_em_pixels_em_area_anelar += item.quantidade_de_barulho_em_pixels_em_area_anelar
	
func remover_item_fazendo_barulho(item: ItemQueFazBarulho) -> void:
	if itens_atuais_fazendo_barulho.has(item):
		itens_atuais_fazendo_barulho.erase(item)
		atual_quantidade_de_barulho_em_pixels_em_area_anelar = max(atual_quantidade_de_barulho_em_pixels_em_area_anelar - item.quantidade_de_barulho_em_pixels_em_area_anelar, 0.0)