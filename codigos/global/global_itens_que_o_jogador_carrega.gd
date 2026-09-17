extends Node

const CENA_NOZ: PackedScene = preload("res://cenas/items/noz.tscn")
const CENA_NOZ_PESADA: PackedScene = preload("res://cenas/items/noz_pesada.tscn")

var itens_coletados: Array[int] = []

func adicionar_item_ao_inventario(item: ItemColetavel) -> void:
	itens_coletados.append(item.tipo_item)

func remover_item_do_inventario(item: ItemColetavel) -> void:
	itens_coletados.erase(item.tipo_item)

func remover_todos_itens_do_inventario() -> void:
	itens_coletados.clear()

func criar_item_por_tipo(tipo_item: int) -> ItemColetavel:
	match tipo_item:
		ItemColetavel.TipoItem.COLETAVEL_NOZ:
			return CENA_NOZ.instantiate() as ItemColetavel
		ItemColetavel.TipoItem.COLETAVEL_NOZ_PESADA:
			return CENA_NOZ_PESADA.instantiate() as ItemColetavel
		_:
			return null



