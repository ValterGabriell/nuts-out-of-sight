class_name Estoque
extends Area3D

enum EstadoEstoque {
	PODE_INSERIR,
	CHEIO
}

@export var itens_no_estoque_label: Label3D = null
@export var area_que_os_itens_guardados_spawnam: AreaParaGuardarOsItens = null

var _jogador: Jogador = null
var _estado_estoque: EstadoEstoque = EstadoEstoque.PODE_INSERIR

func _ready() -> void:
	_atualizar_label_itens_no_estoque(GlobalEstoque.quantidade_total_de_itens)
	if not GlobalEstoque.estoque_atualizado.is_connected(_atualizar_label_itens_no_estoque):
		GlobalEstoque.estoque_atualizado.connect(_atualizar_label_itens_no_estoque)

func _on_body_entered(body: Node3D) -> void:
	_jogador = body as Jogador

func _on_body_exited(_body: Node3D) -> void:
	_jogador = null

func _unhandled_input(event: InputEvent) -> void:
	if _jogador and _estado_estoque == EstadoEstoque.PODE_INSERIR and event.is_action_pressed("interagir"):
		if GlobalItensQueOJogadorCarrega.itens_coletados.is_empty():
			return
		var itens_para_guardar: Array[int] = GlobalItensQueOJogadorCarrega.itens_coletados.duplicate()
		var itens_guardados: Array[int] = GlobalEstoque.guardar_itens(itens_para_guardar)
		if itens_guardados.is_empty():
			return

		for tipo_item_guardado: int in itens_guardados:
			GlobalItensQueOJogadorCarrega.remover_primeiro_item_do_inventario_por_tipo(tipo_item_guardado)

		GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(GlobalItensQueOJogadorCarrega.itens_coletados.size())
		if GlobalItensQueOJogadorCarrega.itens_coletados.is_empty():
			GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.emit()
		spawnar_itens_guardados(itens_guardados)
		GlobalGerenciadorDeSalvamento.salvar_jogo(GlobalGerenciadorDeSalvamento.MotivoDeSalvamento.GUARDAR_NO_ESTOQUE)

func _atualizar_label_itens_no_estoque(quantidade_total_de_itens: int) -> void:
	if itens_no_estoque_label == null:
		return
	itens_no_estoque_label.text = str(quantidade_total_de_itens)

func spawnar_itens_guardados(tipos_itens: Array[int]) -> void:
	if area_que_os_itens_guardados_spawnam:
		area_que_os_itens_guardados_spawnam.call_deferred("spawnar_itens", tipos_itens)
