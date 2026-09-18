extends Node3D

@export var jogador: Jogador
@export var distancia_minima_do_drop: float = 1.0
@export var distancia_maxima_do_drop: float = 1.8


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("largar_itens"):
		return
	if jogador == null:
		return

	if GlobalItensQueOJogadorCarrega.itens_coletados.is_empty():
		return

	var itens_para_largar: Array[int] = GlobalItensQueOJogadorCarrega.itens_coletados.duplicate()
	var ids_dos_itens_para_largar: Array[StringName] = GlobalItensQueOJogadorCarrega.ids_dos_itens_no_inventario.duplicate()
	GlobalItensQueOJogadorCarrega.itens_coletados.clear()
	GlobalItensQueOJogadorCarrega.ids_dos_itens_no_inventario.clear()
	GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(0)

	var quantidade_de_itens: int = itens_para_largar.size()
	for i in quantidade_de_itens:
		var tipo_item: int = itens_para_largar[i]
		var id_do_item_no_mapa: StringName = StringName()
		if i < ids_dos_itens_para_largar.size():
			id_do_item_no_mapa = ids_dos_itens_para_largar[i]
		var item_instanciado: ItemColetavel = GlobalItensQueOJogadorCarrega.criar_item_por_tipo(tipo_item)
		if item_instanciado == null:
			continue

		item_instanciado.id_unico_do_item_no_mapa = id_do_item_no_mapa
		item_instanciado.set_meta("item_spawnado_via_drop_persistido", true)

		var angulo: float = (TAU * float(i)) / max(float(quantidade_de_itens), 1.0)
		var distancia_do_drop: float = randf_range(distancia_minima_do_drop, distancia_maxima_do_drop)
		var deslocamento: Vector3 = Vector3(cos(angulo), 0.0, sin(angulo)) * distancia_do_drop
		var posicao_drop: Vector3 = jogador.global_position + deslocamento
		var id_item_dropado_no_mundo: StringName = GlobalGerenciadorDeSalvamento.registrar_item_dropado_na_cena_atual(tipo_item, id_do_item_no_mapa, posicao_drop)

		get_tree().current_scene.add_child(item_instanciado)
		item_instanciado.set_meta("id_item_dropado_no_mundo", id_item_dropado_no_mundo)
		item_instanciado.largar_na_posicao(posicao_drop)
	
	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.emit()

