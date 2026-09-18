class_name BaseRegistroGlobalItensDropados
extends Node

enum EstadoDoItemNoRegistro {
	NAO_COLETADO,
	COLETADO
}

var ids_de_itens_coletados: Dictionary[StringName, EstadoDoItemNoRegistro] = {}
var itens_dropados_por_cena: Dictionary[StringName, Dictionary] = {}
var sequencial_id_item_dropado: int = 0


func _ready() -> void:
	if not get_tree().scene_changed.is_connected(_ao_trocar_de_cena):
		get_tree().scene_changed.connect(_ao_trocar_de_cena)
	call_deferred("_spawnar_itens_dropados_da_cena_atual")


func registrar_item_coletado(id_unico_do_item_no_mapa: StringName) -> void:
	if id_unico_do_item_no_mapa == StringName():
		return
	ids_de_itens_coletados[id_unico_do_item_no_mapa] = EstadoDoItemNoRegistro.COLETADO


func remover_item_do_registro_de_coletados(id_unico_do_item_no_mapa: StringName) -> void:
	if id_unico_do_item_no_mapa == StringName():
		return
	ids_de_itens_coletados.erase(id_unico_do_item_no_mapa)


func obter_estado_do_item_no_registro(id_unico_do_item_no_mapa: StringName) -> EstadoDoItemNoRegistro:
	if id_unico_do_item_no_mapa == StringName():
		return EstadoDoItemNoRegistro.NAO_COLETADO
	if not ids_de_itens_coletados.has(id_unico_do_item_no_mapa):
		return EstadoDoItemNoRegistro.NAO_COLETADO
	return EstadoDoItemNoRegistro.COLETADO


func registrar_item_dropado_na_cena_atual(tipo_item: int, id_unico_do_item_no_mapa: StringName, posicao_global: Vector3) -> StringName:
	var id_da_cena_atual: StringName = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return StringName()

	if not itens_dropados_por_cena.has(id_da_cena_atual):
		itens_dropados_por_cena[id_da_cena_atual] = {}

	sequencial_id_item_dropado += 1
	var id_item_dropado: StringName = StringName("drop_%s_%d" % [id_da_cena_atual, sequencial_id_item_dropado])
	var itens_da_cena_atual: Dictionary = itens_dropados_por_cena[id_da_cena_atual]
	itens_da_cena_atual[id_item_dropado] = {
		"tipo_item": tipo_item,
		"id_unico_do_item_no_mapa": String(id_unico_do_item_no_mapa),
		"posicao_global": _serializar_posicao_global_para_registro(posicao_global)
	}
	itens_dropados_por_cena[id_da_cena_atual] = itens_da_cena_atual
	return id_item_dropado


func remover_item_dropado_da_cena_atual(id_item_dropado: StringName) -> void:
	if id_item_dropado == StringName():
		return

	var id_da_cena_atual: StringName = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return
	if not itens_dropados_por_cena.has(id_da_cena_atual):
		return

	var itens_da_cena_atual: Dictionary = itens_dropados_por_cena[id_da_cena_atual]
	itens_da_cena_atual.erase(id_item_dropado)
	itens_dropados_por_cena[id_da_cena_atual] = itens_da_cena_atual


func _ao_trocar_de_cena() -> void:
	call_deferred("_spawnar_itens_dropados_da_cena_atual")


func _spawnar_itens_dropados_da_cena_atual() -> void:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	var id_da_cena_atual: StringName = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return
	if not itens_dropados_por_cena.has(id_da_cena_atual):
		return

	var itens_da_cena_atual: Dictionary = itens_dropados_por_cena[id_da_cena_atual]
	for id_item_dropado: StringName in itens_da_cena_atual.keys():
		var dados_do_item_dropado: Dictionary = itens_da_cena_atual[id_item_dropado]
		var tipo_item: int = int(dados_do_item_dropado.get("tipo_item", -1))
		var item_instanciado: ItemColetavel = GlobalItensQueOJogadorCarrega.criar_item_por_tipo(tipo_item)
		if item_instanciado == null:
			continue

		item_instanciado.id_unico_do_item_no_mapa = StringName(String(dados_do_item_dropado.get("id_unico_do_item_no_mapa", "")))
		if _deve_marcar_item_spawnado_via_drop_persistido():
			item_instanciado.set_meta("item_spawnado_via_drop_persistido", true)
		item_instanciado.set_meta("id_item_dropado_no_mundo", id_item_dropado)
		cena_atual.add_child(item_instanciado)
		item_instanciado.largar_na_posicao(_desserializar_posicao_global_do_registro(dados_do_item_dropado.get("posicao_global", {})))


func _obter_id_da_cena_atual() -> StringName:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return StringName()

	var caminho_da_cena_atual: String = cena_atual.scene_file_path
	if caminho_da_cena_atual == "":
		return StringName(cena_atual.name)
	return StringName(caminho_da_cena_atual)


func _serializar_posicao_global_para_registro(posicao_global: Vector3) -> Variant:
	return posicao_global


func _desserializar_posicao_global_do_registro(posicao_serializada: Variant) -> Vector3:
	if posicao_serializada is Vector3:
		return posicao_serializada as Vector3
	if posicao_serializada is Dictionary:
		var posicao_dicionario: Dictionary = posicao_serializada as Dictionary
		return Vector3(
			float(posicao_dicionario.get("x", 0.0)),
			float(posicao_dicionario.get("y", 0.0)),
			float(posicao_dicionario.get("z", 0.0))
		)
	return Vector3.ZERO


func _deve_marcar_item_spawnado_via_drop_persistido() -> bool:
	return false
