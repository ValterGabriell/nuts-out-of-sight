class_name EntradaDaCena
extends Node3D


func _ready() -> void:
    if GlobalItensQueOJogadorCarrega.itens_coletados.size() > 0:
        GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(GlobalItensQueOJogadorCarrega.itens_coletados.size())