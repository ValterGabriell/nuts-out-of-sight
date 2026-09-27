class_name Caverna
extends StaticBody3D


func registrar_disparo_de_barulho_detectado() -> void:
	_definir_percentual_de_barulho_atual(100.0)

func _definir_percentual_de_barulho_atual(percentual: float) -> void:
	print("Percentual de barulho atual: ", percentual)