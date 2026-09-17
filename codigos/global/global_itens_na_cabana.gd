extends Node

enum EstadoDoItemNoRegistro {
	NAO_COLETADO,
	COLETADO
}

var _ids_de_itens_coletados: Dictionary[StringName, EstadoDoItemNoRegistro] = {}

func registrar_item_coletado(id_unico_do_item_no_mapa: StringName) -> void:
	if id_unico_do_item_no_mapa == StringName():
		return
	_ids_de_itens_coletados[id_unico_do_item_no_mapa] = EstadoDoItemNoRegistro.COLETADO

func obter_estado_do_item_no_registro(id_unico_do_item_no_mapa: StringName) -> EstadoDoItemNoRegistro:
	if id_unico_do_item_no_mapa == StringName():
		return EstadoDoItemNoRegistro.NAO_COLETADO
	if not _ids_de_itens_coletados.has(id_unico_do_item_no_mapa):
		return EstadoDoItemNoRegistro.NAO_COLETADO
	return EstadoDoItemNoRegistro.COLETADO

func limpar_registro_de_itens_coletados() -> void:
	_ids_de_itens_coletados.clear()