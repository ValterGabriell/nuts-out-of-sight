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

	var itens_para_largar: Array[ItemColetavel] = GlobalItensQueOJogadorCarrega.itens_coletados.duplicate()
	GlobalItensQueOJogadorCarrega.itens_coletados.clear()
	GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(0)

	var quantidade_de_itens: int = itens_para_largar.size()
	for i in quantidade_de_itens:
		var item_salvo: ItemColetavel = itens_para_largar[i]
		if item_salvo == null or not is_instance_valid(item_salvo):
			continue

		var angulo: float = (TAU * float(i)) / max(float(quantidade_de_itens), 1.0)
		var distancia_do_drop: float = randf_range(distancia_minima_do_drop, distancia_maxima_do_drop)
		var deslocamento: Vector3 = Vector3(cos(angulo), 0.0, sin(angulo)) * distancia_do_drop
		var posicao_drop: Vector3 = jogador.global_position + deslocamento

		if item_salvo.get_parent() != null:
			item_salvo.get_parent().remove_child(item_salvo)

		get_tree().current_scene.add_child(item_salvo)
		item_salvo.largar_na_posicao(posicao_drop)
	
	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.emit()

