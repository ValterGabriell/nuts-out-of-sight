extends CanvasLayer


@export var jogador: Jogador

@export var label_velocidade: Label
@export var label_barulho_total_jogador: Label
@export var label_estado_visibilidade_jogador: Label
@export var label_estado_sono_urso: Label

@export var label_debug_estado_do_vento: Label
@export var label_debug_direcao_do_vento: Label
@export var label_debug_tempo_ate_pre_aviso: Label
@export var label_debug_tempo_ate_rajada: Label
@export var label_debug_intervalo_entre_rajadas: Label

func _ready() -> void:
	if not GlobalGerenciadorDeSinais.debug_vento_atualizado.is_connected(_on_debug_vento_atualizado):
		GlobalGerenciadorDeSinais.debug_vento_atualizado.connect(_on_debug_vento_atualizado)

func _process(_delta: float) -> void:
	if jogador and label_velocidade:
		label_velocidade.text = "Velocidade: " + str(jogador.velocidade_atual)
	if jogador and label_estado_visibilidade_jogador:
		var estados_visibilidade: PackedStringArray = Jogador.EstadoVisibilidadeJogador.keys()
		label_estado_visibilidade_jogador.text = "Visibilidade: " + estados_visibilidade[jogador.estado_visibilidade]
	if jogador and label_barulho_total_jogador:
		if GlobalGerenciadorDeBarulho:
			var texto_barulho_total: String = "Barulho Total: " + str(GlobalGerenciadorDeBarulho.atual_quantidade_de_barulho_em_pixels_em_area_anelar)
			if jogador.urso:
				texto_barulho_total += " | Urso: " + str(jogador.urso.obter_nome_estado_sono_atual()) + " (" + str(snappedf(jogador.urso.percentual_barulho_atual, 0.1)) + "%)"
			label_barulho_total_jogador.text = texto_barulho_total
		else:
			label_barulho_total_jogador.text = "Barulho Total: N/A"
	if jogador and jogador.urso and label_estado_sono_urso:
		label_estado_sono_urso.text = "Sono do Urso: " + str(jogador.urso.obter_nome_estado_sono_atual()) + " (" + str(snappedf(jogador.urso.percentual_barulho_atual, 0.1)) + "%)"

func _on_debug_vento_atualizado(dados_debug_vento: Dictionary) -> void:
	if label_debug_estado_do_vento:
		label_debug_estado_do_vento.text = "Vento Estado: " + str(dados_debug_vento.get("estado", "N/A"))
	if label_debug_direcao_do_vento:
		label_debug_direcao_do_vento.text = "Vento Direcao: " + str(dados_debug_vento.get("direcao_atual", "N/A"))
	if label_debug_tempo_ate_pre_aviso:
		label_debug_tempo_ate_pre_aviso.text = "Tempo ate pre-aviso: " + _formatar_tempo(float(dados_debug_vento.get("tempo_ate_pre_aviso", 0.0)))
	if label_debug_tempo_ate_rajada:
		label_debug_tempo_ate_rajada.text = "Tempo ate rajada: " + _formatar_tempo(float(dados_debug_vento.get("tempo_ate_rajada", 0.0)))
	if label_debug_intervalo_entre_rajadas:
		label_debug_intervalo_entre_rajadas.text = "Intervalo entre rajadas: " + _formatar_tempo(float(dados_debug_vento.get("intervalo_entre_rajadas_em_segundos", 0.0)))

func _formatar_tempo(valor: float) -> String:
	return str(snappedf(max(valor, 0.0), 0.01)) + "s"
