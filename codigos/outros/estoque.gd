class_name Estoque
extends Area3D

enum EstadoEstoque {
	PODE_INSERIR,
	CHEIO
}

@export var itens_no_estoque_label: Label3D = null

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
		GlobalEstoque.guardar_itens(GlobalItensQueOJogadorCarrega.itens_coletados)
		GlobalItensQueOJogadorCarrega.remover_todos_itens_do_inventario()
		GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(0)
		GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.emit()

func _atualizar_label_itens_no_estoque(quantidade_total_de_itens: int) -> void:
	if itens_no_estoque_label == null:
		return

	itens_no_estoque_label.text = str(quantidade_total_de_itens)
