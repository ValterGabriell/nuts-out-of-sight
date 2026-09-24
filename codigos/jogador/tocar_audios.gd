class_name TocarAudios
extends Node3D

enum TipoDePasso {
	SEM_PASSO,
	AREIA,
	MADEIRA,
}




@export var jogador: Jogador
@export var audioPassosNaFolha: AudioStreamPlayer
@export var audioPassosNaAreia: AudioStreamPlayer
@export var audioPassosNaMadeira: AudioStreamPlayer
@export var intervalo_base_passo_areia: float = 0.32
@export var intervalo_minimo_passo_areia: float = 0.16
@export var intervalo_maximo_passo_areia: float = 0.70
@export var intervalo_passo_folha: float = 0.34
@export var velocidade_minima_para_passo: float = 0.1
@export var maximo_polifonia_folha: int = 6

var tempo_desde_ultimo_passo: float = 0.0
var quantidade_itens_folha_anterior: int = 0


func _ready() -> void:
	if audioPassosNaFolha != null:
		audioPassosNaFolha.max_polyphony = max(maximo_polifonia_folha, 1)



func _physics_process(delta: float) -> void:
	if jogador == null:
		return

	var quantidade_itens_folha_atual: int = _obter_quantidade_itens_folha_ativos()
	if _jogador_pode_gerar_passos():
		_tocar_audios_extras_de_folha(quantidade_itens_folha_atual)

	var tipo_de_passo_atual: TipoDePasso = _obter_tipo_de_passo_atual()
	if tipo_de_passo_atual == TipoDePasso.SEM_PASSO:
		tempo_desde_ultimo_passo = 0.0
		quantidade_itens_folha_anterior = quantidade_itens_folha_atual
		return

	tempo_desde_ultimo_passo += delta
	var intervalo_passo: float = _obter_intervalo_do_passo(tipo_de_passo_atual)
	if tempo_desde_ultimo_passo < intervalo_passo:
		quantidade_itens_folha_anterior = quantidade_itens_folha_atual
		return

	tempo_desde_ultimo_passo = 0.0
	match tipo_de_passo_atual:
		TipoDePasso.AREIA:
			_tocar_audio_de_passo(audioPassosNaAreia)
		TipoDePasso.MADEIRA:
			_tocar_audio_de_passo(audioPassosNaMadeira)

	quantidade_itens_folha_anterior = quantidade_itens_folha_atual


func _obter_tipo_de_passo_atual() -> TipoDePasso:
	if not _jogador_pode_gerar_passos():
		return TipoDePasso.SEM_PASSO

	if jogador.cena_atual == jogador.CenaAtual.PRINCIPAL:
		return TipoDePasso.AREIA
	elif jogador.cena_atual == jogador.CenaAtual.CABANA:
		return TipoDePasso.MADEIRA

	return TipoDePasso.SEM_PASSO


func _obter_intervalo_do_passo(tipo_de_passo: TipoDePasso) -> float:
	match tipo_de_passo:
		TipoDePasso.AREIA:
			var velocidade_referencia: float = max(jogador.VELOCIDADE_PADRAO, 0.01)
			var velocidade_atual: float = max(jogador.velocidade_atual, 0.01)
			var fator_velocidade: float = velocidade_referencia / velocidade_atual
			var intervalo_calculado: float = intervalo_base_passo_areia * fator_velocidade
			return clampf(intervalo_calculado, intervalo_minimo_passo_areia, intervalo_maximo_passo_areia)
		TipoDePasso.MADEIRA:
			return intervalo_passo_folha

	return intervalo_maximo_passo_areia


func _jogador_pode_gerar_passos() -> bool:
	if not jogador.is_on_floor():
		return false

	var velocidade_horizontal: float = Vector2(jogador.velocity.x, jogador.velocity.z).length()
	return velocidade_horizontal >= velocidade_minima_para_passo


func _obter_quantidade_itens_folha_ativos() -> int:
	if GlobalGerenciadorDeBarulho == null:
		return 0

	return GlobalGerenciadorDeBarulho.itens_atuais_fazendo_barulho.size()


func _tocar_audios_extras_de_folha(quantidade_itens_folha_atual: int) -> void:
	var novas_folhas_ativadas: int = max(quantidade_itens_folha_atual - quantidade_itens_folha_anterior, 0)
	if novas_folhas_ativadas <= 0:
		return

	tempo_desde_ultimo_passo = 0.0
	for _i in novas_folhas_ativadas:
		_tocar_audio_de_passo(audioPassosNaFolha, true)


func _tocar_audio_de_passo(audio: AudioStreamPlayer, permitir_sobreposicao: bool = false) -> void:
	if audio == null:
		return

	if not permitir_sobreposicao and audio.has_method("stop") and audio.has_method("is_playing") and audio.is_playing():
		audio.stop()
	audio.play()

