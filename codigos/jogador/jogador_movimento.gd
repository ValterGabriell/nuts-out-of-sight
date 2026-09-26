class_name JogadorMovimento extends Node3D

enum EstadoMovimento {
	ANDA_COM_ITEM,
	IDLE,
	RUN,
	IDLE_COM_ITEM
}

@export var jogador: Jogador
@export var animatedSprite: AnimatedSprite3D
@export var mao_jogador_direcao: Node3D
@export var deslocamento_horizontal_mao_com_item: float = 0.5
@export var deslocamento_item_na_frente_no_idle_com_item: float = 1


var estado_atual: EstadoMovimento = EstadoMovimento.IDLE
var item_visual_na_mao: ItemColetavel
var tipo_item_visual_na_mao: int = -1
var posicao_local_inicial_da_mao: Vector3 = Vector3.ZERO

func _ready() -> void:
	GlobalGerenciadorDeSinais.velocidade_do_jogador_alterada.connect(reduzir_velocidade)
	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.connect(resetar_velocidade)
	if mao_jogador_direcao != null:
		posicao_local_inicial_da_mao = mao_jogador_direcao.position

func _physics_process(delta: float) -> void:
	if not jogador.is_on_floor():
		jogador.velocity += jogador.get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and jogador.is_on_floor():
		jogador.velocity.y = Jogador.JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var reference_node: Node3D = jogador.camera_pivot if jogador.camera_pivot != null else jogador
	var basis := reference_node.global_transform.basis
	var camera_forward := basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var direction := (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
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
	atualizar_flip_do_sprite(input_dir, reference_node)
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
	if animatedSprite == null:
		return
	var nome_da_animacao: StringName = StringName(EstadoMovimento.keys()[estado])
	if animatedSprite.animation != nome_da_animacao or not animatedSprite.is_playing():
		animatedSprite.play(nome_da_animacao)


func atualizar_flip_do_sprite(input_dir: Vector2, reference_node: Node3D) -> void:
	if animatedSprite == null:
		return
	if input_dir.x > 0.05:
		animatedSprite.flip_h = true
		return
	if input_dir.x < -0.05:
		animatedSprite.flip_h = false
		return
	var velocidade_local: Vector3 = reference_node.global_transform.basis.inverse() * jogador.velocity
	if velocidade_local.x > 0.05:
		animatedSprite.flip_h = true
		return
	if velocidade_local.x < -0.05:
		animatedSprite.flip_h = false


func atualizar_velocidade_da_animacao(estado: EstadoMovimento) -> void:
	if animatedSprite == null:
		return
	if estado == EstadoMovimento.RUN or estado == EstadoMovimento.ANDA_COM_ITEM:
		animatedSprite.speed_scale = jogador.velocidade_atual / jogador.VELOCIDADE_PADRAO
		return
	animatedSprite.speed_scale = 1.0


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

	if estado_atual != EstadoMovimento.IDLE_COM_ITEM:
		item_visual_na_mao.position = Vector3.ZERO
		return

	if mao_jogador_direcao == null:
		return

	var referencia_de_camera: Node3D = jogador.camera_pivot if jogador != null and jogador.camera_pivot != null else reference_node
	if referencia_de_camera == null:
		item_visual_na_mao.position = Vector3.ZERO
		return

	var direcao_para_camera: Vector3 = referencia_de_camera.global_position - mao_jogador_direcao.global_position
	if direcao_para_camera.length_squared() <= 0.0001:
		item_visual_na_mao.position = Vector3.ZERO
		return

	item_visual_na_mao.global_position = mao_jogador_direcao.global_position + direcao_para_camera.normalized() * deslocamento_item_na_frente_no_idle_com_item


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