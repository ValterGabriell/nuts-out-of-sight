class_name PortaEntrada 
extends Area3D

enum NomeDaAreaDeSpawn {
	PRINCIPAL,
	CABANA
}

@export var nome_da_area_pra_spawnar: NomeDaAreaDeSpawn
@export_file("*.tscn") var caminho_da_cena_para_abrir: String = ""

func _on_body_entered(body: Node3D) -> void:
	print("Body entered: ", body)
	if body is Jogador:
		var cena_de_destino: PackedScene = _obter_cena_para_transicao()
		GlobalTransicaoDeCena.trocar_cena_com_fade(cena_de_destino, _obter_nome_da_area())

func _obter_nome_da_area() -> String:
	return NomeDaAreaDeSpawn.keys()[nome_da_area_pra_spawnar]

func _obter_cena_para_transicao() -> PackedScene:
	if caminho_da_cena_para_abrir == "":
		return null

	var recurso_carregado: Resource = load(caminho_da_cena_para_abrir)
	if recurso_carregado is PackedScene:
		return recurso_carregado as PackedScene

	return null
