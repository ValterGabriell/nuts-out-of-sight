class_name Urso
extends CharacterBody3D

@export var jogador: Jogador
@export var animated_sprite: AnimatedSprite3D
@export var velocidade_perseguicao: float = 1.4
@export var velocidade_rotacao: float = 8.0
@export var distancia_minima_do_jogador: float = 0.4
@export var zona_morta_flip_horizontal: float = 0.05
@export var quantidade_de_barulho_para_panico: float = 1.0
@export var percentual_minimo_inquieto: float = 50.0
@export var percentual_minimo_janela_de_panico: float = 100.0

@export var musicaPerseguicao: AudioStreamPlayer
@export var musicaDormindo: AudioStreamPlayer
@export var duracao_transicao_musica: float = 1.2
@export var volume_db_musica_ativa: float = -3.0
@export var volume_db_musica_inativa: float = -40.0

signal estado_alterado(novo_estado: EstadoUrso)
signal estado_sono_alterado(novo_estado_sono: EstadoSonoUrso, percentual_barulho: float)

## Ele vai de dormindo pra em alerta pra cacando, e cacando pra em alerta pra dormindo, sempre assim
enum EstadoUrso {
	DORMINDO,
	EM_ALERTA,
	PERSEGUINDO,
}

enum AcaoDeTransicaoEmAlerta {
	NENHUMA,
	IR_PARA_PERSEGUINDO,
	IR_PARA_DORMINDO,
}

enum EstadoSonoUrso {
	SONO_PROFUNDO,
	INQUIETO,
	JANELA_DE_PANICO,
}

var estado_atual: EstadoUrso = EstadoUrso.DORMINDO
var acao_de_transicao_em_alerta: AcaoDeTransicaoEmAlerta = AcaoDeTransicaoEmAlerta.NENHUMA
var estado_sono_atual: EstadoSonoUrso = EstadoSonoUrso.SONO_PROFUNDO
var percentual_barulho_atual: float = 0.0
var tween_transicao_musica: Tween
var audio_grito_perseguicao: AudioStreamPlayer


enum ModoTransicaoMusica {
	INSTANTE,
	SUAVE,
}

const CAMINHO_AUDIO_GRITO_PERSEGUICAO: String = "res://arte/audio/sfx/urso_gritando.mp3"


func _ready() -> void:
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D

	if animated_sprite != null and not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	add_to_group("urso")
	_inicializar_estado_das_musicas()
	_inicializar_audio_grito_perseguicao()

	_definir_estado(EstadoUrso.DORMINDO)
	_sincronizar_musica_com_estado(ModoTransicaoMusica.INSTANTE)


func _physics_process(delta: float) -> void:
	match estado_atual:
		EstadoUrso.PERSEGUINDO:
			_perseguir_jogador(delta)
		_:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()


func entrar_em_alerta() -> void:
	if estado_sono_atual != EstadoSonoUrso.JANELA_DE_PANICO:
		return

	if estado_atual != EstadoUrso.DORMINDO:
		return

	_entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_PERSEGUINDO)


func tentar_entrar_em_alerta_por_barulho() -> void:
	registrar_disparo_de_barulho_detectado()


func registrar_disparo_de_barulho_detectado() -> void:
	_definir_percentual_de_barulho_atual(100.0)
	entrar_em_alerta()


func _iniciar_retorno_para_dormindo() -> void:
	_entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO)


func _entrar_em_alerta_com_transicao(acao: AcaoDeTransicaoEmAlerta) -> void:
	acao_de_transicao_em_alerta = acao
	_definir_estado(EstadoUrso.EM_ALERTA)
	if acao == AcaoDeTransicaoEmAlerta.IR_PARA_PERSEGUINDO:
		_tocar_grito_perseguicao()

	if estado_atual == EstadoUrso.EM_ALERTA and acao == AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO:
		_finalizar_transicao_em_alerta()
		return

	if animated_sprite == null:
		_finalizar_transicao_em_alerta()


func _finalizar_transicao_em_alerta() -> void:
	if estado_atual != EstadoUrso.EM_ALERTA:
		acao_de_transicao_em_alerta = AcaoDeTransicaoEmAlerta.NENHUMA
		return

	match acao_de_transicao_em_alerta:
		AcaoDeTransicaoEmAlerta.IR_PARA_PERSEGUINDO:
			_iniciar_perseguicao()
		AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO:
			_definir_percentual_de_barulho_atual(0.0)
			_definir_estado(EstadoUrso.DORMINDO)
		AcaoDeTransicaoEmAlerta.NENHUMA:
			pass

	acao_de_transicao_em_alerta = AcaoDeTransicaoEmAlerta.NENHUMA


func _iniciar_perseguicao() -> void:
	if estado_sono_atual != EstadoSonoUrso.JANELA_DE_PANICO:
		_entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO)
		return

	if _obter_estado_visibilidade_do_jogador() == Jogador.EstadoVisibilidadeJogador.ESCONDIDO:
		_entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO)
		return

	_parar_grito_perseguicao()
	_definir_estado(EstadoUrso.PERSEGUINDO)


func _perseguir_jogador(delta: float) -> void:
	if jogador == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if _obter_estado_visibilidade_do_jogador() == Jogador.EstadoVisibilidadeJogador.ESCONDIDO:
		_iniciar_retorno_para_dormindo()
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var direcao_ate_jogador: Vector3 = jogador.global_position - global_position
	direcao_ate_jogador.y = 0.0

	if direcao_ate_jogador.length() <= distancia_minima_do_jogador:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var direcao_normalizada: Vector3 = direcao_ate_jogador.normalized()
	_rotacionar_para_direcao(direcao_normalizada, delta)
	_atualizar_flip_horizontal_por_jogador()

	velocity.x = direcao_normalizada.x * velocidade_perseguicao
	velocity.z = direcao_normalizada.z * velocidade_perseguicao


func _rotacionar_para_direcao(direcao_normalizada: Vector3, delta: float) -> void:
	var angulo_alvo: float = atan2(direcao_normalizada.x, direcao_normalizada.z)
	rotation.y = lerp_angle(rotation.y, angulo_alvo, velocidade_rotacao * delta)


func _obter_estado_visibilidade_do_jogador() -> Jogador.EstadoVisibilidadeJogador:
	if jogador == null:
		return Jogador.EstadoVisibilidadeJogador.ESCONDIDO
	return jogador.estado_visibilidade


func _atualizar_flip_horizontal_por_jogador() -> void:
	if animated_sprite == null or jogador == null:
		return

	var posicao_jogador_local: Vector3 = to_local(jogador.global_position)
	if abs(posicao_jogador_local.x) <= zona_morta_flip_horizontal:
		return

	animated_sprite.flip_h = posicao_jogador_local.x < 0.0


func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite == null:
		return

	if estado_atual != EstadoUrso.EM_ALERTA:
		return

	var nome_animacao_em_alerta: StringName = _obter_nome_animacao_por_estado(EstadoUrso.EM_ALERTA)
	if animated_sprite.animation != nome_animacao_em_alerta:
		return

	_finalizar_transicao_em_alerta()


func _obter_nome_animacao_por_estado(estado: EstadoUrso) -> StringName:
	var chaves_do_enum: PackedStringArray = EstadoUrso.keys()
	return StringName(chaves_do_enum[estado])


func _definir_percentual_de_barulho_atual(percentual: float) -> void:
	percentual_barulho_atual = clampf(percentual, 0.0, 100.0)
	var novo_estado_sono: EstadoSonoUrso = _obter_estado_sono_por_percentual(percentual_barulho_atual)
	_definir_estado_sono(novo_estado_sono)


func _obter_estado_sono_por_percentual(percentual: float) -> EstadoSonoUrso:
	if percentual >= percentual_minimo_janela_de_panico:
		return EstadoSonoUrso.JANELA_DE_PANICO
	if percentual >= percentual_minimo_inquieto:
		return EstadoSonoUrso.INQUIETO
	return EstadoSonoUrso.SONO_PROFUNDO


func _definir_estado_sono(novo_estado_sono: EstadoSonoUrso) -> void:
	if estado_sono_atual == novo_estado_sono:
		return

	estado_sono_atual = novo_estado_sono
	estado_sono_alterado.emit(estado_sono_atual, percentual_barulho_atual)


func obter_nome_estado_sono_atual() -> StringName:
	var chaves_do_enum: PackedStringArray = EstadoSonoUrso.keys()
	return StringName(chaves_do_enum[estado_sono_atual])


func resetar_para_dormindo() -> void:
	acao_de_transicao_em_alerta = AcaoDeTransicaoEmAlerta.NENHUMA
	_definir_percentual_de_barulho_atual(0.0)
	_definir_estado(EstadoUrso.DORMINDO)


func _definir_estado(novo_estado: EstadoUrso) -> void:
	if estado_atual == novo_estado:
		return

	estado_atual = novo_estado
	estado_alterado.emit(estado_atual)
	_sincronizar_musica_com_estado(ModoTransicaoMusica.SUAVE)


func _inicializar_estado_das_musicas() -> void:
	if musicaDormindo != null:
		musicaDormindo.volume_db = volume_db_musica_inativa

	if musicaPerseguicao != null:
		musicaPerseguicao.volume_db = volume_db_musica_inativa


func _sincronizar_musica_com_estado(modo: ModoTransicaoMusica) -> void:
	if musicaDormindo == null or musicaPerseguicao == null:
		return
	_assegurar_tocando_musicas_base()

	if estado_atual == EstadoUrso.PERSEGUINDO:
		_aplicar_volumes_musica(modo, volume_db_musica_inativa, volume_db_musica_ativa)
		return

	_aplicar_volumes_musica(modo, volume_db_musica_ativa, volume_db_musica_inativa)


func _assegurar_tocando_musicas_base() -> void:
	if not musicaDormindo.playing:
		musicaDormindo.play()

	if not musicaPerseguicao.playing:
		musicaPerseguicao.play()


func _aplicar_volumes_musica(modo: ModoTransicaoMusica, volume_dormindo: float, volume_perseguicao: float) -> void:
	if tween_transicao_musica != null and tween_transicao_musica.is_running():
		tween_transicao_musica.kill()

	match modo:
		ModoTransicaoMusica.INSTANTE:
			musicaDormindo.volume_db = volume_dormindo
			musicaPerseguicao.volume_db = volume_perseguicao
		ModoTransicaoMusica.SUAVE:
			tween_transicao_musica = create_tween()
			tween_transicao_musica.set_parallel(true)
			tween_transicao_musica.tween_property(musicaDormindo, "volume_db", volume_dormindo, duracao_transicao_musica)
			tween_transicao_musica.tween_property(musicaPerseguicao, "volume_db", volume_perseguicao, duracao_transicao_musica)


func _inicializar_audio_grito_perseguicao() -> void:
	audio_grito_perseguicao = AudioStreamPlayer.new()
	audio_grito_perseguicao.name = "AudioGritoPerseguicao"
	var stream_grito: AudioStream = load(CAMINHO_AUDIO_GRITO_PERSEGUICAO) as AudioStream
	audio_grito_perseguicao.stream = stream_grito
	add_child(audio_grito_perseguicao)


func _tocar_grito_perseguicao() -> void:
	if audio_grito_perseguicao == null:
		return

	if audio_grito_perseguicao.stream == null:
		return

	if audio_grito_perseguicao.playing:
		audio_grito_perseguicao.stop()

	audio_grito_perseguicao.play()


func _parar_grito_perseguicao() -> void:
	if audio_grito_perseguicao != null and audio_grito_perseguicao.playing:
		audio_grito_perseguicao.stop()