class_name UIHud extends CanvasLayer

@export var label_quantidade_de_itens_no_inventario: Label

func _ready() -> void:
	GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.connect(_on_item_adicionado_ao_inventario)

func _on_item_adicionado_ao_inventario(quantidadeDeItensNoInventario: int) -> void:
	label_quantidade_de_itens_no_inventario.text = str(quantidadeDeItensNoInventario)