class_name JogadorMovimento extends Node3D

enum EstadoMovimento {
	ANDA_COM_ITEM,
	IDLE,
	RUN,
	IDLE_COM_ITEM
}

enum EstadoControleDoJogador {
	CONTROLE_DO_JOGADOR,
	MOVIMENTO_AUTOMATICO_NA_TRANSICAO
}

@export var jogador: Jogador
@export var animationPlayer: AnimationPlayer
@export var no_visual_corpo: Node3D
@export var mao_jogador_direcao: Node3D
@export var deslocamento_horizontal_mao_com_item: float = 0.5
@export var deslocamento_item_na_frente_no_idle_com_item: float = 1.0
@export var velocidade_rotacao_corpo: float = 12.0
@export var multiplicador_velocidade_animacao_movimento: float = 1.2
@export var animation_start_fps: float = 30.0
@export var animation_start_frame: int = 1

## Ative no AnimationPlayer da Cutscene para desativar o controle e a lógica do jogador
@export var em_cutscene: bool = false

var estado_atual: EstadoMovimento = EstadoMovimento.IDLE
var item_visual_na_mao: ItemColetavel
var tipo_item_visual_na_mao: int = -1
var posicao_local_inicial_da_mao: Vector3 = Vector3.ZERO
var cache_nome_animacao_por_estado: Dictionary = {}
var alvo_rotacao_corpo: Node3D
var estado_controle: EstadoControleDoJogador = EstadoControleDoJogador.CONTROLE_DO_JOGADOR
var ultima_direcao_de_movimento: Vector3 = Vector3.FORWARD
var direcao_automatica: Vector3 = Vector3.ZERO
var token_do_movimento_automatico: int = 0

func _ready() -> void:
	garantir_animation_player()
	resolver_no_visual_do_corpo()
	preparar_cache_de_animacoes()
	GlobalGerenciadorDeSinais.velocidade_do_jogador_alterada.connect(reduzir_velocidade)
	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.connect(resetar_velocidade)
	GlobalGerenciadorDeSinais.transicao_de_area_com_camera_iniciada.connect(_on_transicao_de_area_com_camera_iniciada)
	if mao_jogador_direcao != null:
		posicao_local_inicial_da_mao = mao_jogador_direcao.position

func _physics_process(delta: float) -> void:
	# SE ESTIVER EM CUTSCENE: Não aplica física, não lê inputs e não força animações do jogador
	if em_cutscene:
		return

	if not jogador.is_on_floor():
		jogador.velocity += jogador.get_gravity() * delta

	if estado_controle == EstadoControleDoJogador.CONTROLE_DO_JOGADOR and Input.is_action_just_pressed("ui_accept") and jogador.is_on_floor():
		jogador.velocity.y = Jogador.JUMP_VELOCITY

	var input_dir: Vector2 = Vector2.ZERO
	if estado_controle == EstadoControleDoJogador.CONTROLE_DO_JOGADOR:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var reference_node: Node3D = jogador.camera_pivot if jogador.camera_pivot != null else jogador
	var basis := reference_node.global_transform.basis
	var camera_forward := basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var direction: Vector3 = Vector3.ZERO
	if estado_controle == EstadoControleDoJogador.MOVIMENTO_AUTOMATICO_NA_TRANSICAO:
		direction = _obter_direcao_automatica(reference_node)
	else:
		# Input axes are inverted in this setup, so flip both components before applying movement.
		var corrected_input_dir: Vector2 = -input_dir
		direction = (camera_right * corrected_input_dir.x + camera_forward * corrected_input_dir.y).normalized()
		if direction.length_squared() > 0.0001:
			ultima_direcao_de_movimento = direction
	
	atualizar_rotacao_do_corpo(direction, delta)
	if direction:
		jogador.velocity.x = direction.x * jogador.velocidade_atual
		jogador.velocity.z = direction.z * jogador.velocidade_atual
	else:
		jogador.velocity.x = move_toward(jogador.velocity.x, 0, jogador.velocidade_atual)
		jogador.velocity.z = move_toward(jogador.velocity.z, 0, jogador.velocidade_atual)

	jogador.move_and_slide()

	var velocidade_horizontal: Vector2 = Vector2(jogador.velocity.x, jogador.velocity.z)
	var esta_se_movendo: bool = velocidade_horizontal.length() > 0.05
	var esta_com_item: bool = not GlobalItensQueOJogadorCarrega.itens_coletados.is_empty()
	sincronizar_item_visual_na_mao(esta_com_item)
	atualizar_estado_e_animacao(esta_se_movendo, esta_com_item)
	atualizar_deslocamento_da_mao(input_dir, reference_node)
	atualizar_posicao_visual_do_item(reference_node)

func _exit_tree() -> void:
	remover_item_visual_na_mao()

func atualizar_estado_e_animacao(esta_se_movendo: bool, esta_com_item: bool) -> void:
	estado_atual = obter_estado_de_movimento(esta_se_movendo, esta_com_item)
	tocar_animacao_do_estado(estado_atual)
	atualizar_velocidade_da_animacao(estado_atual)

func obter_estado_de_movimento(esta_se_movendo: bool, esta_com_item: bool) -> EstadoMovimento:
	if esta_se_movendo and esta_com_item:
		return EstadoMovimento.ANDA_COM_ITEM
	if esta_se_movendo:
		return EstadoMovimento.RUN
	if esta_com_item:
		return EstadoMovimento.IDLE_COM_ITEM
	return EstadoMovimento.IDLE

func tocar_animacao_do_estado(estado: EstadoMovimento) -> void:
	garantir_animation_player()
	if animationPlayer == null:
		return
	var nome_da_animacao: StringName = obter_nome_da_animacao(estado)
	if nome_da_animacao.is_empty():
		return
	if animationPlayer.current_animation != nome_da_animacao or not animationPlayer.is_playing():
		animationPlayer.play(nome_da_animacao)
		animationPlayer.seek(obter_tempo_inicial_da_animacao(), true)

func obter_nome_da_animacao(estado: EstadoMovimento) -> StringName:
	if cache_nome_animacao_por_estado.has(estado):
		return cache_nome_animacao_por_estado[estado]

	match estado:
		EstadoMovimento.RUN:
			return &"run_001"
		EstadoMovimento.ANDA_COM_ITEM:
			return &"run_with_get"
		EstadoMovimento.IDLE_COM_ITEM:
			return &"idle_with_item"
		_:
			return &"idle_without_item_001"

func garantir_animation_player() -> void:
	if animationPlayer != null:
		return
	animationPlayer = jogador.get_node_or_null("AnimationPlayer") if jogador != null else null
	if animationPlayer != null:
		return
	animationPlayer = get_node_or_null("AnimationPlayer")
	if animationPlayer != null:
		return
	animationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer

func preparar_cache_de_animacoes() -> void:
	cache_nome_animacao_por_estado.clear()
	if animationPlayer == null:
		return
	cache_nome_animacao_por_estado[EstadoMovimento.RUN] = resolver_nome_animacao(&"run_001")
	cache_nome_animacao_por_estado[EstadoMovimento.ANDA_COM_ITEM] = resolver_nome_animacao(&"run_with_get")
	cache_nome_animacao_por_estado[EstadoMovimento.IDLE] = resolver_nome_animacao(&"idle_without_item_001")
	cache_nome_animacao_por_estado[EstadoMovimento.IDLE_COM_ITEM] = resolver_nome_animacao(&"idle_with_item")

func obter_tempo_inicial_da_animacao() -> float:
	if animation_start_fps <= 0.0:
		return 0.0
	return max(float(animation_start_frame), 0.0) / animation_start_fps

func resolver_nome_animacao(nome_esperado: StringName) -> StringName:
	if animationPlayer == null:
		return &""
	if animationPlayer.has_animation(nome_esperado):
		return nome_esperado

	var nome_esperado_texto: String = String(nome_esperado)
	for nome_disponivel in animationPlayer.get_animation_list():
		var nome_disponivel_texto: String = String(nome_disponivel)
		if nome_disponivel_texto.ends_with(nome_esperado_texto):
			return StringName(nome_disponivel_texto)

	push_warning("Animation not found in AnimationPlayer: " + nome_esperado_texto)
	return &""

func atualizar_velocidade_da_animacao(estado: EstadoMovimento) -> void:
	garantir_animation_player()
	if animationPlayer == null:
		return
	if estado == EstadoMovimento.RUN or estado == EstadoMovimento.ANDA_COM_ITEM:
		var escala_base: float = jogador.velocidade_atual / jogador.VELOCIDADE_PADRAO
		animationPlayer.speed_scale = escala_base * max(multiplicador_velocidade_animacao_movimento, 0.0)
		return
	animationPlayer.speed_scale = 1.0

func atualizar_rotacao_do_corpo(direcao: Vector3, delta: float) -> void:
	if alvo_rotacao_corpo == null:
		resolver_no_visual_do_corpo()
	if alvo_rotacao_corpo == null:
		return
	if direcao.length_squared() <= 0.0001:
		return

	# The visual model forward is flipped relative to movement, so apply a 180-degree yaw offset.
	var angulo_alvo: float = atan2(direcao.x, direcao.z) + PI
	alvo_rotacao_corpo.rotation.y = lerp_angle(alvo_rotacao_corpo.rotation.y, angulo_alvo, velocidade_rotacao_corpo * delta)

func resolver_no_visual_do_corpo() -> void:
	if no_visual_corpo != null:
		alvo_rotacao_corpo = no_visual_corpo
		return
	if animationPlayer != null and animationPlayer.get_parent() is Node3D:
		alvo_rotacao_corpo = animationPlayer.get_parent() as Node3D
		return
	alvo_rotacao_corpo = jogador

func atualizar_deslocamento_da_mao(input_dir: Vector2, reference_node: Node3D) -> void:
	if mao_jogador_direcao == null:
		return

	if estado_atual != EstadoMovimento.ANDA_COM_ITEM:
		mao_jogador_direcao.position = posicao_local_inicial_da_mao
		return

	var direcao_horizontal: float = input_dir.x
	if abs(direcao_horizontal) <= 0.05:
		var velocidade_local: Vector3 = reference_node.global_transform.basis.inverse() * jogador.velocity
		direcao_horizontal = velocidade_local.x

	if abs(direcao_horizontal) <= 0.05:
		return

	var direcao_do_deslocamento: float = sign(direcao_horizontal)
	mao_jogador_direcao.position = Vector3(
		posicao_local_inicial_da_mao.x + (deslocamento_horizontal_mao_com_item * direcao_do_deslocamento),
		posicao_local_inicial_da_mao.y,
		posicao_local_inicial_da_mao.z
	)

func atualizar_posicao_visual_do_item(reference_node: Node3D) -> void:
	if item_visual_na_mao == null:
		return

	if estado_atual != EstadoMovimento.IDLE_COM_ITEM and estado_atual != EstadoMovimento.ANDA_COM_ITEM:
		item_visual_na_mao.position = Vector3.ZERO
		return

	if mao_jogador_direcao == null:
		return

	var origem_vertical: Vector3 = jogador.global_position if jogador != null else mao_jogador_direcao.global_position
	item_visual_na_mao.global_position = origem_vertical + Vector3.UP * deslocamento_item_na_frente_no_idle_com_item

func sincronizar_item_visual_na_mao(esta_com_item: bool) -> void:
	if not esta_com_item:
		remover_item_visual_na_mao()
		return

	if GlobalItensQueOJogadorCarrega.itens_coletados.is_empty():
		remover_item_visual_na_mao()
		return

	var tipo_item_atual: int = GlobalItensQueOJogadorCarrega.itens_coletados[0]
	if item_visual_na_mao != null and tipo_item_visual_na_mao == tipo_item_atual:
		return

	criar_item_visual_na_mao(tipo_item_atual)

func criar_item_visual_na_mao(tipo_item: int) -> void:
	remover_item_visual_na_mao()
	var novo_item_visual: ItemColetavel = GlobalItensQueOJogadorCarrega.criar_item_por_tipo(tipo_item)
	if novo_item_visual == null:
		return

	var no_da_mao: Node3D = mao_jogador_direcao if mao_jogador_direcao != null else jogador
	if no_da_mao == null:
		novo_item_visual.queue_free()
		return

	no_da_mao.add_child(novo_item_visual)
	novo_item_visual.position = Vector3.ZERO
	novo_item_visual.rotation = Vector3.ZERO
	novo_item_visual.monitoring = false
	novo_item_visual.monitorable = false
	novo_item_visual.collision_layer = 0
	novo_item_visual.collision_mask = 0
	novo_item_visual.set_process_unhandled_input(false)
	if novo_item_visual.label_acao != null:
		novo_item_visual.label_acao.visible = false

	item_visual_na_mao = novo_item_visual
	tipo_item_visual_na_mao = tipo_item

func remover_item_visual_na_mao() -> void:
	if item_visual_na_mao != null:
		item_visual_na_mao.queue_free()
		item_visual_na_mao = null
	tipo_item_visual_na_mao = -1

func reduzir_velocidade(percentual: float) -> void:
	jogador.velocidade_atual *= (1.0 - percentual / 100.0)

func resetar_velocidade() -> void:
	jogador.velocidade_atual = jogador.VELOCIDADE_PADRAO

func _on_transicao_de_area_com_camera_iniciada(_id_area: String, duracao_movimento_automatico_em_segundos: float) -> void:
	estado_controle = EstadoControleDoJogador.MOVIMENTO_AUTOMATICO_NA_TRANSICAO
	direcao_automatica = _obter_direcao_automatica_inicial()
 
	token_do_movimento_automatico += 1
	var token_atual: int = token_do_movimento_automatico
	var duracao_final: float = max(duracao_movimento_automatico_em_segundos, 0.0)
	if duracao_final <= 0.0:
		encerrar_movimento_automatico_e_restaurar_controle(token_atual)
		return

	encerrar_movimento_automatico_e_restaurar_controle_apos_duracao(token_atual, duracao_final)

func encerrar_movimento_automatico_e_restaurar_controle_apos_duracao(token: int, duracao_em_segundos: float) -> void:
	await get_tree().create_timer(duracao_em_segundos).timeout
	encerrar_movimento_automatico_e_restaurar_controle(token)

func encerrar_movimento_automatico_e_restaurar_controle(token: int) -> void:
	if token != token_do_movimento_automatico:
		return

	estado_controle = EstadoControleDoJogador.CONTROLE_DO_JOGADOR
	direcao_automatica = Vector3.ZERO
	GlobalGerenciadorDeSinais.confirmar_entrada_no_estoque_se_estiver_na_area()

func _obter_direcao_automatica(reference_node: Node3D) -> Vector3:
	if direcao_automatica.length_squared() > 0.0001:
		return direcao_automatica

	var direcao_base: Vector3 = _obter_direcao_automatica_inicial()
	if direcao_base.length_squared() <= 0.0001 and reference_node != null:
		direcao_base = -reference_node.global_transform.basis.z

	direcao_base.y = 0.0
	direcao_automatica = direcao_base.normalized()
	return direcao_automatica

func _obter_direcao_automatica_inicial() -> Vector3:
	var direcao_pela_velocidade: Vector3 = Vector3(jogador.velocity.x, 0.0, jogador.velocity.z)
	if direcao_pela_velocidade.length_squared() > 0.0001:
		return direcao_pela_velocidade.normalized()

	if ultima_direcao_de_movimento.length_squared() > 0.0001:
		return ultima_direcao_de_movimento.normalized()

	return Vector3.ZERO