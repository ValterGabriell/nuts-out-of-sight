extends Node

enum FasesRodada {
	PRIMEIRA,
	SEGUNDA,
	TERCEIRA
}

var fase_atual: FasesRodada = FasesRodada.PRIMEIRA

func _ready() -> void:
	GlobalGerenciadorDeSinais.estoque_atingiu_maximo_pra_aquele_dia.connect(atualizar_fase)

func atualizar_fase() -> void:
	if fase_atual == FasesRodada.PRIMEIRA:
		fase_atual = FasesRodada.SEGUNDA
	elif fase_atual == FasesRodada.SEGUNDA:
		fase_atual = FasesRodada.TERCEIRA

func obter_snapshot_para_salvamento() -> Dictionary:
	return {
		"fase_atual": int(fase_atual)
	}

func carregar_snapshot_do_salvamento(snapshot_da_fase: Dictionary) -> void:
	if snapshot_da_fase.is_empty():
		return

	var fase_salva = int(snapshot_da_fase.get("fase_atual", int(FasesRodada.PRIMEIRA)))
	fase_atual = _obter_fase_valida(fase_salva)

func _obter_fase_valida(fase: int) -> FasesRodada:
	if fase < int(FasesRodada.PRIMEIRA):
		return FasesRodada.PRIMEIRA
	if fase > int(FasesRodada.TERCEIRA):
		return FasesRodada.TERCEIRA
	return fase as FasesRodada
