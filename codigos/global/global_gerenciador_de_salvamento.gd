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

enum EstadoDoRegistroDoUrso {
	NAO_REGISTRADO,
	REGISTRADO
}

const CAMINHO_DO_ARQUIVO_DE_SALVAMENTO: String = "user://save_jogo.json"

var estado_do_arquivo_de_salvamento: EstadoDoArquivoDeSalvamento = EstadoDoArquivoDeSalvamento.NAO_CARREGADO
var deve_persistir_posicao_das_folhas: bool = true
var percentual_de_folhas_por_area_no_snapshot: float = 0.35
var quantidade_maxima_de_folhas_por_area_no_snapshot: int = 60
var casas_decimais_das_posicoes_das_folhas_no_snapshot: int = 2
var snapshots_de_folhas_por_cena: Dictionary[StringName, Dictionary] = {}
var registros_do_urso_por_cena: Dictionary[StringName, Dictionary] = {}
var snapshots_da_caverna_por_cena: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	carregar_jogo_do_disco()
	if not get_tree().scene_changed.is_connected(_ao_trocar_de_cena_para_restaurar_urso):
		get_tree().scene_changed.connect(_ao_trocar_de_cena_para_restaurar_urso)
	super._ready()


func salvar_jogo(motivo_do_salvamento: MotivoDeSalvamento) -> void:
	if deve_persistir_posicao_das_folhas:
		_atualizar_snapshot_de_folhas_da_cena_atual()
	_atualizar_registro_do_urso_da_cena_atual()
	_atualizar_snapshot_da_caverna_da_cena_atual()

	var dados_do_salvamento: Dictionary = {
		"versao": 1,
		"motivo_ultimo_salvamento": MotivoDeSalvamento.keys()[motivo_do_salvamento],
		"sequencial_id_item_dropado": sequencial_id_item_dropado,
		"ids_de_itens_coletados": _serializar_ids_de_itens_coletados(),
		"itens_dropados_por_cena": _serializar_itens_dropados_por_cena(),
		"inventario_do_jogador": GlobalItensQueOJogadorCarrega.obter_snapshot_para_salvamento(),
		"estoque": GlobalEstoque.obter_snapshot_para_salvamento(),
		"fase_da_rodada": GlobalGerenciadorDeFase.obter_snapshot_para_salvamento()
	}

	if deve_persistir_posicao_das_folhas:
		dados_do_salvamento["snapshots_de_folhas_por_cena"] = _serializar_snapshots_de_folhas_por_cena()

	dados_do_salvamento["registros_do_urso_por_cena"] = _serializar_registros_do_urso_por_cena()
	dados_do_salvamento["snapshots_da_caverna_por_cena"] = _serializar_snapshots_da_caverna_por_cena()

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
	if deve_persistir_posicao_das_folhas:
		_carregar_snapshots_de_folhas_por_cena(dados_do_salvamento.get("snapshots_de_folhas_por_cena", {}))
	else:
		snapshots_de_folhas_por_cena.clear()
	_carregar_registros_do_urso_por_cena(dados_do_salvamento.get("registros_do_urso_por_cena", {}))
	_carregar_snapshots_da_caverna_por_cena(dados_do_salvamento.get("snapshots_da_caverna_por_cena", {}))
	GlobalItensQueOJogadorCarrega.carregar_snapshot_do_salvamento(dados_do_salvamento.get("inventario_do_jogador", {}))
	GlobalEstoque.carregar_snapshot_do_salvamento(dados_do_salvamento.get("estoque", {}))
	GlobalGerenciadorDeFase.carregar_snapshot_do_salvamento(dados_do_salvamento.get("fase_da_rodada", {}))
	estado_do_arquivo_de_salvamento = EstadoDoArquivoDeSalvamento.CARREGADO
	call_deferred("_aplicar_registro_do_urso_da_cena_atual")
	call_deferred("_aplicar_snapshot_da_caverna_da_cena_atual")


func _ao_trocar_de_cena_para_restaurar_urso() -> void:
	call_deferred("_aplicar_registro_do_urso_da_cena_atual")
	call_deferred("_aplicar_snapshot_da_caverna_da_cena_atual")

func _atualizar_snapshot_de_folhas_da_cena_atual() -> void:
	if not deve_persistir_posicao_das_folhas:
		return

	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return

	var id_da_cena_atual = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return

	var snapshots_da_cena: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistencia_de_folhas"):
		if not (node is AreasDeAparecimentoDasFolhas):
			continue
		if not cena_atual.is_ancestor_of(node):
			continue

		var areas_de_folhas = node as AreasDeAparecimentoDasFolhas
		var caminho_relativo = StringName(String(cena_atual.get_path_to(areas_de_folhas)))
		var snapshot_bruto = areas_de_folhas.obter_snapshot_para_salvamento()
		snapshots_da_cena[caminho_relativo] = _otimizar_snapshot_de_folhas(snapshot_bruto)

	snapshots_de_folhas_por_cena[id_da_cena_atual] = snapshots_da_cena

func obter_snapshot_de_folhas_da_cena_atual_para(areas_de_folhas: AreasDeAparecimentoDasFolhas) -> Dictionary:
	if not deve_persistir_posicao_das_folhas:
		return {}

	if areas_de_folhas == null:
		return {}

	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return {}

	var id_da_cena_atual = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return {}
	if not snapshots_de_folhas_por_cena.has(id_da_cena_atual):
		return {}

	var snapshots_da_cena = snapshots_de_folhas_por_cena[id_da_cena_atual] as Dictionary
	if snapshots_da_cena == null:
		return {}

	var caminho_relativo = StringName(String(cena_atual.get_path_to(areas_de_folhas)))
	if not snapshots_da_cena.has(caminho_relativo):
		return {}

	var snapshot = snapshots_da_cena[caminho_relativo] as Dictionary
	if snapshot == null:
		return {}
	return snapshot

func _atualizar_snapshot_da_caverna_da_cena_atual() -> void:
	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return

	var id_da_cena_atual = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return

	var snapshots_da_cena: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistencia_da_caverna"):
		if not (node is Caverna):
			continue
		if not cena_atual.is_ancestor_of(node):
			continue

		var caverna = node as Caverna
		var caminho_relativo = StringName(String(cena_atual.get_path_to(caverna)))
		snapshots_da_cena[caminho_relativo] = caverna.obter_snapshot_para_salvamento()

	snapshots_da_caverna_por_cena[id_da_cena_atual] = snapshots_da_cena

func obter_snapshot_da_caverna_da_cena_atual_para(caverna: Caverna) -> Dictionary:
	if caverna == null:
		return {}

	var cena_atual = get_tree().current_scene
	if cena_atual == null:
		return {}

	var id_da_cena_atual = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return {}
	if not snapshots_da_caverna_por_cena.has(id_da_cena_atual):
		return {}

	var snapshots_da_cena = snapshots_da_caverna_por_cena[id_da_cena_atual] as Dictionary
	if snapshots_da_cena == null:
		return {}

	var caminho_relativo = StringName(String(cena_atual.get_path_to(caverna)))
	if not snapshots_da_cena.has(caminho_relativo):
		return {}

	var snapshot = snapshots_da_cena[caminho_relativo] as Dictionary
	if snapshot == null:
		return {}
	return snapshot

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

func _serializar_snapshots_de_folhas_por_cena() -> Dictionary:
	var dados_serializados: Dictionary = {}
	for id_da_cena: StringName in snapshots_de_folhas_por_cena.keys():
		var snapshots_da_cena: Dictionary = snapshots_de_folhas_por_cena[id_da_cena]
		var snapshots_serializados: Dictionary = {}
		for caminho_do_no: StringName in snapshots_da_cena.keys():
			snapshots_serializados[String(caminho_do_no)] = snapshots_da_cena[caminho_do_no]
		dados_serializados[String(id_da_cena)] = snapshots_serializados
	return dados_serializados


func _serializar_registros_do_urso_por_cena() -> Dictionary:
	var dados_serializados: Dictionary = {}
	for id_da_cena: StringName in registros_do_urso_por_cena.keys():
		dados_serializados[String(id_da_cena)] = registros_do_urso_por_cena[id_da_cena]
	return dados_serializados

func _serializar_snapshots_da_caverna_por_cena() -> Dictionary:
	var dados_serializados: Dictionary = {}
	for id_da_cena: StringName in snapshots_da_caverna_por_cena.keys():
		var snapshots_da_cena: Dictionary = snapshots_da_caverna_por_cena[id_da_cena]
		var snapshots_serializados: Dictionary = {}
		for caminho_do_no: StringName in snapshots_da_cena.keys():
			snapshots_serializados[String(caminho_do_no)] = snapshots_da_cena[caminho_do_no]
		dados_serializados[String(id_da_cena)] = snapshots_serializados
	return dados_serializados

func _otimizar_snapshot_de_folhas(snapshot_bruto: Dictionary) -> Dictionary:
	if snapshot_bruto == null or snapshot_bruto.is_empty():
		return {}

	var folhas_por_area_bruto: Dictionary = snapshot_bruto.get("folhas_por_area", {}) as Dictionary
	if folhas_por_area_bruto == null:
		return {}

	var snapshot_otimizado: Dictionary = {
		"folhas_por_area": {}
	}
	var folhas_por_area_otimizado: Dictionary = snapshot_otimizado["folhas_por_area"]
	var percentual = clamp(percentual_de_folhas_por_area_no_snapshot, 0.01, 1.0)
	var limite_por_area = maxi(1, quantidade_maxima_de_folhas_por_area_no_snapshot)

	for chave_area: Variant in folhas_por_area_bruto.keys():
		var posicoes_da_area: Array = folhas_por_area_bruto[chave_area] as Array
		if posicoes_da_area == null or posicoes_da_area.is_empty():
			folhas_por_area_otimizado[chave_area] = []
			continue

		var quantidade_total_da_area = posicoes_da_area.size()
		var quantidade_por_percentual = maxi(1, int(round(float(quantidade_total_da_area) * percentual)))
		var quantidade_alvo = mini(quantidade_total_da_area, mini(quantidade_por_percentual, limite_por_area))
		var subconjunto = _selecionar_subconjunto_uniforme(posicoes_da_area, quantidade_alvo)
		var posicoes_compactadas: Array = []

		for posicao_serializada: Variant in subconjunto:
			posicoes_compactadas.append(_compactar_posicao_serializada(posicao_serializada))

		folhas_por_area_otimizado[chave_area] = posicoes_compactadas

	return snapshot_otimizado

func _selecionar_subconjunto_uniforme(valores: Array, quantidade_alvo: int) -> Array:
	if quantidade_alvo >= valores.size():
		return valores.duplicate()

	var resultado: Array = []
	var ultimo_indice = max(valores.size() - 1, 1)
	for i in range(quantidade_alvo):
		var indice = int(round((float(i) / float(max(quantidade_alvo - 1, 1))) * float(ultimo_indice)))
		resultado.append(valores[indice])
	return resultado

func _compactar_posicao_serializada(posicao_serializada: Variant) -> Dictionary:
	var posicao = _desserializar_posicao_global(posicao_serializada)
	return {
		"x": _arredondar_para_casas_decimais(posicao.x, casas_decimais_das_posicoes_das_folhas_no_snapshot),
		"y": _arredondar_para_casas_decimais(posicao.y, casas_decimais_das_posicoes_das_folhas_no_snapshot),
		"z": _arredondar_para_casas_decimais(posicao.z, casas_decimais_das_posicoes_das_folhas_no_snapshot)
	}

func _arredondar_para_casas_decimais(valor: float, casas_decimais: int) -> float:
	var casas = maxi(0, casas_decimais)
	var fator = pow(10.0, casas)
	if fator <= 0.0:
		return valor
	return round(valor * fator) / fator


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

func _carregar_snapshots_de_folhas_por_cena(dados_serializados: Dictionary) -> void:
	snapshots_de_folhas_por_cena.clear()
	for id_da_cena_serializado: Variant in dados_serializados.keys():
		var id_da_cena: StringName = StringName(String(id_da_cena_serializado))
		var snapshots_da_cena_serializados: Dictionary = dados_serializados[id_da_cena_serializado] as Dictionary
		if snapshots_da_cena_serializados == null:
			continue

		var snapshots_tipados: Dictionary = {}
		for caminho_do_no_serializado: Variant in snapshots_da_cena_serializados.keys():
			var snapshot_do_no: Dictionary = snapshots_da_cena_serializados[caminho_do_no_serializado] as Dictionary
			if snapshot_do_no == null:
				continue
			snapshots_tipados[StringName(String(caminho_do_no_serializado))] = snapshot_do_no
		snapshots_de_folhas_por_cena[id_da_cena] = snapshots_tipados


func _carregar_registros_do_urso_por_cena(dados_serializados: Dictionary) -> void:
	registros_do_urso_por_cena.clear()
	for id_da_cena_serializado: Variant in dados_serializados.keys():
		var id_da_cena: StringName = StringName(String(id_da_cena_serializado))
		var registro_serializado: Dictionary = dados_serializados[id_da_cena_serializado] as Dictionary
		if registro_serializado == null:
			continue
		registros_do_urso_por_cena[id_da_cena] = registro_serializado

func _carregar_snapshots_da_caverna_por_cena(dados_serializados: Dictionary) -> void:
	snapshots_da_caverna_por_cena.clear()
	for id_da_cena_serializado: Variant in dados_serializados.keys():
		var id_da_cena: StringName = StringName(String(id_da_cena_serializado))
		var snapshots_da_cena_serializados: Dictionary = dados_serializados[id_da_cena_serializado] as Dictionary
		if snapshots_da_cena_serializados == null:
			continue

		var snapshots_tipados: Dictionary = {}
		for caminho_do_no_serializado: Variant in snapshots_da_cena_serializados.keys():
			var snapshot_do_no: Dictionary = snapshots_da_cena_serializados[caminho_do_no_serializado] as Dictionary
			if snapshot_do_no == null:
				continue
			snapshots_tipados[StringName(String(caminho_do_no_serializado))] = snapshot_do_no
		snapshots_da_caverna_por_cena[id_da_cena] = snapshots_tipados


func _atualizar_registro_do_urso_da_cena_atual() -> void:
	var id_da_cena_atual: StringName = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return

	var urso_da_cena: Urso = _obter_urso_da_cena_atual()
	if urso_da_cena == null:
		registros_do_urso_por_cena.erase(id_da_cena_atual)
		return

	registros_do_urso_por_cena[id_da_cena_atual] = {
		"posicao_global": _serializar_posicao_global_para_registro(urso_da_cena.global_position),
		"rotacao_global": _serializar_posicao_global_para_registro(urso_da_cena.global_rotation)
	}


func _aplicar_registro_do_urso_da_cena_atual() -> void:
	var urso_da_cena: Urso = _obter_urso_da_cena_atual()
	if urso_da_cena == null:
		return

	urso_da_cena.resetar_para_dormindo()

	var id_da_cena_atual: StringName = _obter_id_da_cena_atual()
	if id_da_cena_atual == StringName():
		return

	if _obter_estado_do_registro_do_urso_na_cena(id_da_cena_atual) != EstadoDoRegistroDoUrso.REGISTRADO:
		return

	var registro_do_urso: Dictionary = registros_do_urso_por_cena[id_da_cena_atual] as Dictionary
	if registro_do_urso == null:
		return

	urso_da_cena.global_position = _desserializar_posicao_global_do_registro(registro_do_urso.get("posicao_global", {}))
	urso_da_cena.global_rotation = _desserializar_posicao_global_do_registro(registro_do_urso.get("rotacao_global", {}))

func _aplicar_snapshot_da_caverna_da_cena_atual() -> void:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	for node in get_tree().get_nodes_in_group("persistencia_da_caverna"):
		if not (node is Caverna):
			continue
		if not cena_atual.is_ancestor_of(node):
			continue

		var caverna = node as Caverna
		var snapshot = obter_snapshot_da_caverna_da_cena_atual_para(caverna)
		if snapshot.is_empty():
			continue
		caverna.aplicar_snapshot_do_salvamento(snapshot)


func _obter_estado_do_registro_do_urso_na_cena(id_da_cena: StringName) -> EstadoDoRegistroDoUrso:
	if not registros_do_urso_por_cena.has(id_da_cena):
		return EstadoDoRegistroDoUrso.NAO_REGISTRADO
	return EstadoDoRegistroDoUrso.REGISTRADO


func _obter_urso_da_cena_atual() -> Urso:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return null

	var urso_por_no: Urso = cena_atual.get_node_or_null("Urso") as Urso
	if urso_por_no != null:
		return urso_por_no

	var urso_por_grupo: Node = get_tree().get_first_node_in_group("urso")
	if urso_por_grupo is Urso and cena_atual.is_ancestor_of(urso_por_grupo):
		return urso_por_grupo as Urso

	return null


func _desserializar_posicao_global(posicao_serializada: Dictionary) -> Vector3:
	return Vector3(
		float(posicao_serializada.get("x", 0.0)),
		float(posicao_serializada.get("y", 0.0)),
		float(posicao_serializada.get("z", 0.0))
	)
