extends Node

var itens_na_cabana: Array[ItemColetavel] = []

func adicionar_item(item: ItemColetavel) -> void:
	itens_na_cabana.append(item)

func remover_item(item: ItemColetavel) -> void:
	itens_na_cabana.erase(item)