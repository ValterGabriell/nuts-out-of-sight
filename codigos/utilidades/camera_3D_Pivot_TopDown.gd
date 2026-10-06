extends Node3D

@export var jogador_movimento: JogadorMovimento

var area_ativa_id: String = ""
var tween_ativo: Tween

func area_ativa_corresponde(id_area: String) -> bool:
	return area_ativa_id == id_area

func aplicar_novo_pivot(id_area: String, novo_transform: Transform3D, res: AreaQueAlteraOMovimentoCameraRecurso) -> void:
	# Se o jogador estiver em cutscene, cancela a alteração de câmera da área
	if jogador_movimento != null and jogador_movimento.em_cutscene:
		print("Alteração de câmera cancelada devido a cutscene.")
		return

	area_ativa_id = id_area
	
	if tween_ativo and tween_ativo.is_running():
		tween_ativo.kill()

	var tempo = res.tempo_de_transicao if res else 1.0
	var trans = res.tipo_transicao if res else Tween.TRANS_SINE
	var ease_type = res.tipo_easing if res else Tween.EASE_OUT

	tween_ativo = create_tween().set_trans(trans).set_ease(ease_type)
	tween_ativo.tween_property(self, "global_transform", novo_transform, tempo)