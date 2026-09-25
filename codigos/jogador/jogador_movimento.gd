class_name JogadorMovimento extends Node3D

enum EstadoMovimento {
	ANDA_COM_ITEM,
	IDLE,
	RUN,
	IDLE_COM_ITEM
}

@export var jogador: Jogador
@export var animatedSprite: AnimatedSprite3D

var estado_atual: EstadoMovimento = EstadoMovimento.IDLE

func _ready() -> void:
	GlobalGerenciadorDeSinais.velocidade_do_jogador_alterada.connect(reduzir_velocidade)
	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.connect(resetar_velocidade)

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
	atualizar_flip_do_sprite(input_dir, reference_node)
	atualizar_estado_e_animacao(esta_se_movendo, esta_com_item)


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


func reduzir_velocidade(percentual: float) -> void:
	jogador.velocidade_atual *= (1.0 - percentual / 100.0)

func resetar_velocidade() -> void:
	jogador.velocidade_atual = jogador.VELOCIDADE_PADRAO