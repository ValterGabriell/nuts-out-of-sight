class_name ItemQueFazBarulho
extends Node3D

enum ItemTipo {
	FOLHA
}

@export var tipoDoItem: ItemTipo
@export var quantidade_de_barulho_em_pixels_em_area_anelar : float = 1.0
@export var cena_onda_de_som: PackedScene

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.adicionar_item_fazendo_barulho(self)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Jogador:
		GlobalGerenciadorDeBarulho.remover_item_fazendo_barulho(self)
		if cena_onda_de_som:
			var onda = cena_onda_de_som.instantiate()
			get_tree().current_scene.add_child(onda)
			
			var pos_ajustada = global_position
			pos_ajustada.y += 0.1
			onda.global_position = pos_ajustada
