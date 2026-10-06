extends Node


enum AreaAtualJogador {
	AREA_PRINCIPAL,
	ESTOQUE,
}

enum ContextoDosCreditos {
	GAME_OVER,
	VITORIA,
}


signal item_adicionado_ao_inventario(quantidadeDeItensNoInventario: int)
signal velocidade_do_jogador_alterada(percentual_de_reducao: float)
signal velocidade_do_jogador_resetada()
signal debug_vento_atualizado(dados_debug_vento: Dictionary)
signal estoque_atingiu_maximo_pra_aquele_dia()
signal tentativa_na_caverna_encerrada()
signal transicao_de_area_com_camera_iniciada(id_area: String, duracao_movimento_automatico_em_segundos: float)
signal transicao_de_area_com_camera_encerrada(id_area: String)
signal area_atual_do_jogador_alterada(nova_area: AreaAtualJogador)
signal jogador_entrou_no_estoque()

var area_atual_do_jogador: AreaAtualJogador = AreaAtualJogador.AREA_PRINCIPAL
var contexto_dos_creditos: ContextoDosCreditos = ContextoDosCreditos.GAME_OVER
var mensagem_de_abertura_dos_creditos: String = ""
var _deve_exibir_botao_tentar_novamente_nos_creditos: bool = true

func iniciar_transicao_de_area_com_camera(id_area: String, duracao_movimento_automatico_em_segundos: float) -> void:
	transicao_de_area_com_camera_iniciada.emit(id_area, max(duracao_movimento_automatico_em_segundos, 0.0))

func encerrar_transicao_de_area_com_camera(id_area: String) -> void:
	transicao_de_area_com_camera_encerrada.emit(id_area)

func atualizar_area_atual_do_jogador(nova_area: AreaAtualJogador) -> void:
	if area_atual_do_jogador == nova_area:
		return

	area_atual_do_jogador = nova_area
	area_atual_do_jogador_alterada.emit(area_atual_do_jogador)

func confirmar_entrada_no_estoque_se_estiver_na_area() -> void:
	print("Confirmando entrada no estoque...")
	if area_atual_do_jogador != AreaAtualJogador.ESTOQUE:
		return
	print("Área atual do jogador: ", area_atual_do_jogador)
	jogador_entrou_no_estoque.emit()

func configurar_contexto_dos_creditos(
	novo_contexto: ContextoDosCreditos,
	nova_mensagem_de_abertura: String = "",
	exibir_botao_tentar_novamente: bool = true
) -> void:
	contexto_dos_creditos = novo_contexto
	mensagem_de_abertura_dos_creditos = nova_mensagem_de_abertura
	_deve_exibir_botao_tentar_novamente_nos_creditos = exibir_botao_tentar_novamente

func obter_contexto_dos_creditos() -> ContextoDosCreditos:
	return contexto_dos_creditos

func obter_mensagem_de_abertura_dos_creditos() -> String:
	return mensagem_de_abertura_dos_creditos

func deve_exibir_botao_tentar_novamente_nos_creditos() -> bool:
	return _deve_exibir_botao_tentar_novamente_nos_creditos
