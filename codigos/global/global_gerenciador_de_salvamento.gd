extends BaseRegistroGlobalItensDropados


enum MotivoDeSalvamento {
	CARREGAMENTO_INICIAL,
	TROCA_DE_CENA,
	GUARDAR_NO_ESTOQUE
}

enum EstadoDoArquivoDeSalvamento {
	NAO_CARREGADO,
	CARREGADO
}

const CAMINHO_DO_ARQUIVO_DE_SALVAMENTO: String = "user://save_jogo.json"

var estado_do_arquivo_de_salvamento: EstadoDoArquivoDeSalvamento = EstadoDoArquivoDeSalvamento.NAO_CARREGADO


func _ready() -> void:
	carregar_jogo_do_disco()
	super._ready()


func salvar_jogo(motivo_do_salvamento: MotivoDeSalvamento) -> void:
	var dados_do_salvamento: Dictionary = {
		"versao": 1,
		"motivo_ultimo_salvamento": MotivoDeSalvamento.keys()[motivo_do_salvamento],
		"sequencial_id_item_dropado": sequencial_id_item_dropado,
		"ids_de_itens_coletados": _serializar_ids_de_itens_coletados(),
		"itens_dropados_por_cena": _serializar_itens_dropados_por_cena(),
		"inventario_do_jogador": GlobalItensQueOJogadorCarrega.obter_snapshot_para_salvamento(),
		"estoque": GlobalEstoque.obter_snapshot_para_salvamento()
	}

	var arquivo_de_salvamento: FileAccess = FileAccess.open(CAMINHO_DO_ARQUIVO_DE_SALVAMENTO, FileAccess.WRITE)
	if arquivo_de_salvamento == null:
		push_warning("Nao foi possivel abrir o arquivo de salvamento para escrita: %s" % CAMINHO_DO_ARQUIVO_DE_SALVAMENTO)
		return

	arquivo_de_salvamento.store_string(JSON.stringify(dados_do_salvamento, "\t"))
	arquivo_de_salvamento.close()


func carregar_jogo_do_disco() -> void:
	if not FileAccess.file_exists(CAMINHO_DO_ARQUIVO_DE_SALVAMENTO):
		estado_do_arquivo_de_salvamento = EstadoDoArquivoDeSalvamento.CARREGADO
		return

	var arquivo_de_salvamento: FileAccess = FileAccess.open(CAMINHO_DO_ARQUIVO_DE_SALVAMENTO, FileAccess.READ)
	if arquivo_de_salvamento == null:
		push_warning("Nao foi possivel abrir o arquivo de salvamento para leitura: %s" % CAMINHO_DO_ARQUIVO_DE_SALVAMENTO)
		return

	var conteudo_do_salvamento: String = arquivo_de_salvamento.get_as_text()
	arquivo_de_salvamento.close()
	if conteudo_do_salvamento == "":
		estado_do_arquivo_de_salvamento = EstadoDoArquivoDeSalvamento.CARREGADO
		return

	var json_do_salvamento: JSON = JSON.new()
	var resultado_do_parse: Error = json_do_salvamento.parse(conteudo_do_salvamento)
	if resultado_do_parse != OK:
		push_warning("Falha ao parsear o arquivo de salvamento")
		return

	var dados_do_salvamento: Dictionary = json_do_salvamento.data as Dictionary
	if dados_do_salvamento == null:
		estado_do_arquivo_de_salvamento = EstadoDoArquivoDeSalvamento.CARREGADO
		return

	sequencial_id_item_dropado = int(dados_do_salvamento.get("sequencial_id_item_dropado", 0))
	_carregar_ids_de_itens_coletados(dados_do_salvamento.get("ids_de_itens_coletados", []))
	_carregar_itens_dropados_por_cena(dados_do_salvamento.get("itens_dropados_por_cena", {}))
	GlobalItensQueOJogadorCarrega.carregar_snapshot_do_salvamento(dados_do_salvamento.get("inventario_do_jogador", {}))
	GlobalEstoque.carregar_snapshot_do_salvamento(dados_do_salvamento.get("estoque", {}))
	estado_do_arquivo_de_salvamento = EstadoDoArquivoDeSalvamento.CARREGADO

func _serializar_posicao_global_para_registro(posicao_global: Vector3) -> Variant:
	return {
		"x": posicao_global.x,
		"y": posicao_global.y,
		"z": posicao_global.z
	}


func _desserializar_posicao_global_do_registro(posicao_serializada: Variant) -> Vector3:
	if posicao_serializada is Dictionary:
		return _desserializar_posicao_global(posicao_serializada as Dictionary)
	return super._desserializar_posicao_global_do_registro(posicao_serializada)


func _deve_marcar_item_spawnado_via_drop_persistido() -> bool:
	return true


func _serializar_ids_de_itens_coletados() -> Array[String]:
	var ids_serializados: Array[String] = []
	for id_do_item: StringName in ids_de_itens_coletados.keys():
		ids_serializados.append(String(id_do_item))
	return ids_serializados


func _serializar_itens_dropados_por_cena() -> Dictionary:
	var dados_serializados: Dictionary = {}
	for id_da_cena: StringName in itens_dropados_por_cena.keys():
		var itens_da_cena: Dictionary = itens_dropados_por_cena[id_da_cena]
		var itens_serializados: Dictionary = {}
		for id_item_dropado: StringName in itens_da_cena.keys():
			itens_serializados[String(id_item_dropado)] = itens_da_cena[id_item_dropado]
		dados_serializados[String(id_da_cena)] = itens_serializados
	return dados_serializados


func _carregar_ids_de_itens_coletados(ids_serializados: Array) -> void:
	ids_de_itens_coletados.clear()
	for id_serializado: Variant in ids_serializados:
		var id_do_item: StringName = StringName(String(id_serializado))
		if id_do_item == StringName():
			continue
		ids_de_itens_coletados[id_do_item] = EstadoDoItemNoRegistro.COLETADO


func _carregar_itens_dropados_por_cena(dados_serializados: Dictionary) -> void:
	itens_dropados_por_cena.clear()
	for id_da_cena_serializado: Variant in dados_serializados.keys():
		var id_da_cena: StringName = StringName(String(id_da_cena_serializado))
		var itens_da_cena_serializados: Dictionary = dados_serializados[id_da_cena_serializado] as Dictionary
		if itens_da_cena_serializados == null:
			continue

		var itens_da_cena_tipados: Dictionary = {}
		for id_item_dropado_serializado: Variant in itens_da_cena_serializados.keys():
			var dados_do_item_dropado: Dictionary = itens_da_cena_serializados[id_item_dropado_serializado] as Dictionary
			if dados_do_item_dropado == null:
				continue
			itens_da_cena_tipados[StringName(String(id_item_dropado_serializado))] = dados_do_item_dropado
		itens_dropados_por_cena[id_da_cena] = itens_da_cena_tipados


func _desserializar_posicao_global(posicao_serializada: Dictionary) -> Vector3:
	return Vector3(
		float(posicao_serializada.get("x", 0.0)),
		float(posicao_serializada.get("y", 0.0)),
		float(posicao_serializada.get("z", 0.0))
	)
