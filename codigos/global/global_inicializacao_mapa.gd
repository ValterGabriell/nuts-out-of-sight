extends Node3D

const CENA_ONDA_SOM = preload("res://cenas/outros/onda_de_som.tscn")

func _ready() -> void:
	pre_carregar_shader_onda()

func pre_carregar_shader_onda() -> void:
	var onda_temp = CENA_ONDA_SOM.instantiate()
	
	onda_temp.position = Vector3(0, -9999, 0)
	add_child(onda_temp)
	
	await get_tree().process_frame
	
	onda_temp.queue_free()