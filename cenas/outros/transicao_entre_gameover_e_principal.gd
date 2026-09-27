class_name TransicaoEntreGameoverEPrincipal
extends Node2D

const CENA_CABANA: PackedScene = preload("res://cenas/areas_do_jogo/cabana.tscn")

@export var tempo_antes_de_ir_para_cabana_em_segundos: float = 1.2
@export var nome_da_area_de_spawn_na_cabana: String = "CABANA"
@export var texto_da_transicao: String = "O rugido ecoa... voce recua para a cabana."

@onready var label_de_transicao: Label = get_node_or_null("CanvasLayer/CenterContainer/RichTextLabel") as Label

func _ready() -> void:
	if label_de_transicao != null:
		label_de_transicao.text = texto_da_transicao

	_iniciar_fluxo_da_transicao()

func _iniciar_fluxo_da_transicao() -> void:
	var espera = max(tempo_antes_de_ir_para_cabana_em_segundos, 0.0)
	if espera > 0.0:
		await get_tree().create_timer(espera).timeout

	if GlobalTransicaoDeCena != null and CENA_CABANA != null:
		GlobalTransicaoDeCena.trocar_cena_com_fade(CENA_CABANA, nome_da_area_de_spawn_na_cabana)
		return

	if CENA_CABANA != null:
		get_tree().change_scene_to_packed(CENA_CABANA)


