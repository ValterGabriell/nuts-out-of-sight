extends Node3D

var area_ativa_id: String = ""
var tween_ativo: Tween

func aplicar_novo_pivot(id_area: String, novo_transform: Transform3D, res: AreaQueAlteraOMovimentoCameraRecurso) -> void:
	area_ativa_id = id_area
	
	if tween_ativo and tween_ativo.is_running():
		tween_ativo.kill()

	var tempo = res.tempo_de_transicao if res else 1.0
	var trans = res.tipo_transicao if res else Tween.TRANS_SINE
	var ease_type = res.tipo_easing if res else Tween.EASE_OUT

	tween_ativo = create_tween().set_trans(trans).set_ease(ease_type)
	tween_ativo.tween_property(self, "global_transform", novo_transform, tempo)