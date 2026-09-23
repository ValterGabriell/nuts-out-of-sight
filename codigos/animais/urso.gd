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

enum EstadoDisparoDaJanelaDePanico {
    NAO_DISPARADO,
    DISPARADO,
}

var estado_atual: EstadoUrso = EstadoUrso.DORMINDO
var acao_de_transicao_em_alerta: AcaoDeTransicaoEmAlerta = AcaoDeTransicaoEmAlerta.NENHUMA
var estado_sono_atual: EstadoSonoUrso = EstadoSonoUrso.SONO_PROFUNDO
var percentual_barulho_atual: float = 0.0
var estado_disparo_da_janela_de_panico: EstadoDisparoDaJanelaDePanico = EstadoDisparoDaJanelaDePanico.NAO_DISPARADO


func _ready() -> void:
    if animated_sprite == null:
        animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D

    if animated_sprite != null and not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
        animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

    add_to_group("urso")

    _definir_estado(EstadoUrso.DORMINDO)


func _physics_process(delta: float) -> void:
    _atualizar_estado_de_sono_por_barulho_global()

    match estado_atual:
        EstadoUrso.PERSEGUINDO:
            _perseguir_jogador(delta)
        _:
            velocity.x = 0.0
            velocity.z = 0.0

    move_and_slide()


func entrar_em_alerta() -> void:
    _entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_PERSEGUINDO)


func tentar_entrar_em_alerta_por_barulho() -> void:
    if estado_sono_atual != EstadoSonoUrso.JANELA_DE_PANICO:
        return

    if estado_atual != EstadoUrso.DORMINDO:
        return

    _registrar_disparo_da_janela_de_panico()
    entrar_em_alerta()


func _iniciar_retorno_para_dormindo() -> void:
    _entrar_em_alerta_com_transicao(AcaoDeTransicaoEmAlerta.IR_PARA_DORMINDO)


func _entrar_em_alerta_com_transicao(acao: AcaoDeTransicaoEmAlerta) -> void:
    acao_de_transicao_em_alerta = acao
    _definir_estado(EstadoUrso.EM_ALERTA)

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
            _definir_estado(EstadoUrso.DORMINDO)
        AcaoDeTransicaoEmAlerta.NENHUMA:
            pass

    acao_de_transicao_em_alerta = AcaoDeTransicaoEmAlerta.NENHUMA


func _iniciar_perseguicao() -> void:
    if estado_sono_atual != EstadoSonoUrso.JANELA_DE_PANICO:
        _definir_estado(EstadoUrso.DORMINDO)
        return

    if _obter_estado_visibilidade_do_jogador() == Jogador.EstadoVisibilidadeJogador.ESCONDIDO:
        _definir_estado(EstadoUrso.DORMINDO)
        return

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


func _atualizar_estado_de_sono_por_barulho_global() -> void:
    percentual_barulho_atual = _obter_percentual_barulho_global()

    var novo_estado_sono: EstadoSonoUrso = _obter_estado_sono_por_percentual(percentual_barulho_atual)
    _definir_estado_sono(novo_estado_sono)

    if estado_sono_atual == EstadoSonoUrso.JANELA_DE_PANICO:
        if estado_disparo_da_janela_de_panico == EstadoDisparoDaJanelaDePanico.NAO_DISPARADO and estado_atual == EstadoUrso.DORMINDO:
            _registrar_disparo_da_janela_de_panico()
            entrar_em_alerta()
    else:
        estado_disparo_da_janela_de_panico = EstadoDisparoDaJanelaDePanico.NAO_DISPARADO


func _obter_percentual_barulho_global() -> float:
    if quantidade_de_barulho_para_panico <= 0.0:
        return 0.0

    var barulho_global_atual: float = GlobalGerenciadorDeBarulho.atual_quantidade_de_barulho_em_pixels_em_area_anelar
    var percentual: float = (barulho_global_atual / quantidade_de_barulho_para_panico) * 100.0
    return clampf(percentual, 0.0, 100.0)


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


func _registrar_disparo_da_janela_de_panico() -> void:
    estado_disparo_da_janela_de_panico = EstadoDisparoDaJanelaDePanico.DISPARADO


func obter_nome_estado_sono_atual() -> StringName:
    var chaves_do_enum: PackedStringArray = EstadoSonoUrso.keys()
    return StringName(chaves_do_enum[estado_sono_atual])


func _definir_estado(novo_estado: EstadoUrso) -> void:
    if estado_atual == novo_estado:
        return

    estado_atual = novo_estado
    estado_alterado.emit(estado_atual)