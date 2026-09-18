class_name AreasDeAparecimentoDasFolhas
extends Node3D

@export var area_spawn: Area3D
@export var cena_folha: PackedScene 
@export var quantidade_inicial_de_folhas: int = 15

func _ready() -> void:
	spawnar_folhas_na_area(quantidade_inicial_de_folhas)

func spawnar_folhas_na_area(quantidade: int) -> void:
	if not area_spawn or not cena_folha:
		return

	var shape_node: CollisionShape3D = null
	for child in area_spawn.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			shape_node = child
			break

	if not shape_node:
		return

	var box: BoxShape3D = shape_node.shape
	var tamanho_box = box.size 
	var centro_box = shape_node.global_position
	var min_x = centro_box.x - (tamanho_box.x / 2.0)
	var max_x = centro_box.x + (tamanho_box.x / 2.0)
	var min_z = centro_box.z - (tamanho_box.z / 2.0)
	var max_z = centro_box.z + (tamanho_box.z / 2.0)

	for i in range(quantidade):
		var x_rand = randf_range(min_x, max_x)
		var z_rand = randf_range(min_z, max_z)
		var pos_mundo = Vector3(x_rand, centro_box.y, z_rand)

		var folha_instancia = cena_folha.instantiate()
		add_child(folha_instancia)
		folha_instancia.global_position = pos_mundo