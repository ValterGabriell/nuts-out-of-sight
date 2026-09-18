class_name UIHud extends CanvasLayer

@export var label_quantidade_de_itens_no_inventario: Label

func _ready() -> void:
	if not GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.is_connected(_on_item_adicionado_ao_inventario):
		GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.connect(_on_item_adicionado_ao_inventario)
	_on_item_adicionado_ao_inventario(GlobalItensQueOJogadorCarrega.itens_coletados.size())

func _on_item_adicionado_ao_inventario(quantidadeDeItensNoInventario: int) -> void:
	label_quantidade_de_itens_no_inventario.text = str(quantidadeDeItensNoInventario)