extends Node

var itens_coletados: Array[ItemColetavel] = []

func adicionar_item_ao_inventario(item: ItemColetavel) -> void:
	itens_coletados.append(item)

func remover_item_do_inventario(item: ItemColetavel) -> void:
	itens_coletados.erase(item)



