extends Node

const CENA_NOZ: PackedScene = preload("res://cenas/items/noz.tscn")
const CENA_NOZ_PESADA: PackedScene = preload("res://cenas/items/noz_pesada.tscn")

var itens_coletados: Array[int] = []
var ids_dos_itens_no_inventario: Array[StringName] = []


func obter_snapshot_para_salvamento() -> Dictionary:
	var ids_serializados: Array[String] = []
	for id_do_item: StringName in ids_dos_itens_no_inventario:
		ids_serializados.append(String(id_do_item))

	return {
		"tipos_itens": itens_coletados.duplicate(),
		"ids_dos_itens_no_inventario": ids_serializados
	}

func carregar_snapshot_do_salvamento(snapshot_do_inventario: Dictionary) -> void:
	itens_coletados.clear()
	ids_dos_itens_no_inventario.clear()

	var tipos_itens_serializados: Array = snapshot_do_inventario.get("tipos_itens", [])
	for tipo_item_serializado: Variant in tipos_itens_serializados:
		itens_coletados.append(int(tipo_item_serializado))

	var ids_serializados: Array = snapshot_do_inventario.get("ids_dos_itens_no_inventario", [])
	for i in itens_coletados.size():
		if i < ids_serializados.size():
			ids_dos_itens_no_inventario.append(StringName(String(ids_serializados[i])))
		else:
			ids_dos_itens_no_inventario.append(StringName())

func adicionar_item_ao_inventario(item: ItemColetavel) -> bool:
	if itens_coletados.size() >= 1:
		return false
	itens_coletados.append(item.tipo_item)
	ids_dos_itens_no_inventario.append(item.id_unico_do_item_no_mapa)
	return true

func remover_item_do_inventario(item: ItemColetavel) -> void:
	remover_primeiro_item_do_inventario_por_tipo(item.tipo_item)

func remover_primeiro_item_do_inventario_por_tipo(tipo_item: int) -> StringName:
	var indice_do_item: int = itens_coletados.find(tipo_item)
	if indice_do_item == -1:
		return StringName()

	itens_coletados.remove_at(indice_do_item)
	var id_do_item_no_mapa: StringName = StringName()
	if indice_do_item < ids_dos_itens_no_inventario.size():
		id_do_item_no_mapa = ids_dos_itens_no_inventario[indice_do_item]
		ids_dos_itens_no_inventario.remove_at(indice_do_item)
	return id_do_item_no_mapa

func remover_todos_itens_do_inventario() -> void:
	itens_coletados.clear()
	ids_dos_itens_no_inventario.clear()

func criar_item_por_tipo(tipo_item: int) -> ItemColetavel:
	match tipo_item:
		ItemColetavel.TipoItem.COLETAVEL_NOZ:
			return CENA_NOZ.instantiate() as ItemColetavel
		ItemColetavel.TipoItem.COLETAVEL_NOZ_PESADA:
			return CENA_NOZ_PESADA.instantiate() as ItemColetavel
		_:
			return null



