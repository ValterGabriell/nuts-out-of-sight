extends CanvasLayer

enum EstadoDaTransicao {
	OCIOSO,
	FADE_OUT,
	TROCANDO_CENA,
	CONFIGURANDO_ENTRADA,
	FADE_IN
}

const CENA_DO_JOGADOR: PackedScene = preload("res://cenas/jogador/jogador.tscn")

@export var duracao_fade_out: float = 0.35
@export var duracao_fade_in: float = 0.35

var estado_da_transicao: EstadoDaTransicao = EstadoDaTransicao.OCIOSO
var _proxima_cena: PackedScene
var _nome_da_area_de_spawn: String = ""
var _filtro_preto: ColorRect

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_filtro_preto = ColorRect.new()
	_filtro_preto.name = "FiltroPreto"
	_filtro_preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filtro_preto.offset_left = 0.0
	_filtro_preto.offset_top = 0.0
	_filtro_preto.offset_right = 0.0
	_filtro_preto.offset_bottom = 0.0
	_filtro_preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_filtro_preto.color = Color(0, 0, 0, 0)
	add_child(_filtro_preto)
	get_tree().scene_changed.connect(_ao_trocar_de_cena)

func trocar_cena_com_fade(cena: PackedScene, nome_da_area_para_spawnar: String) -> void:
	if cena == null:
		return

	if estado_da_transicao != EstadoDaTransicao.OCIOSO:
		return

	_proxima_cena = cena
	_nome_da_area_de_spawn = nome_da_area_para_spawnar
	await _executar_fade_out()
	_iniciar_troca_de_cena()

func _iniciar_troca_de_cena() -> void:
	estado_da_transicao = EstadoDaTransicao.TROCANDO_CENA
	var resultado_da_troca: Error = get_tree().change_scene_to_packed(_proxima_cena)
	if resultado_da_troca != OK:
		await _executar_fade_in()
		estado_da_transicao = EstadoDaTransicao.OCIOSO

func _ao_trocar_de_cena() -> void:
	if estado_da_transicao != EstadoDaTransicao.TROCANDO_CENA:
		return

	await get_tree().process_frame
	await get_tree().process_frame
	await _configurar_entrada_da_cena_atual()
	await _executar_fade_in()
	estado_da_transicao = EstadoDaTransicao.OCIOSO

func _executar_fade_out() -> void:
	estado_da_transicao = EstadoDaTransicao.FADE_OUT
	var tween_fade_out: Tween = create_tween()
	tween_fade_out.tween_property(_filtro_preto, "color:a", 1.0, duracao_fade_out)
	await tween_fade_out.finished

func _executar_fade_in() -> void:
	estado_da_transicao = EstadoDaTransicao.FADE_IN
	var tween_fade_in: Tween = create_tween()
	tween_fade_in.tween_property(_filtro_preto, "color:a", 0.0, duracao_fade_in)
	await tween_fade_in.finished

func _configurar_entrada_da_cena_atual() -> void:
	estado_da_transicao = EstadoDaTransicao.CONFIGURANDO_ENTRADA
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	var jogador_da_cena: Node3D = _obter_ou_criar_jogador(cena_atual)
	if jogador_da_cena == null:
		return

	_posicionar_jogador_no_spawn(cena_atual, jogador_da_cena)
	_configurar_camera_para_seguir_jogador(cena_atual, jogador_da_cena)

func _obter_ou_criar_jogador(cena_atual: Node) -> Node3D:
	var jogador_existente: Node3D = cena_atual.get_node_or_null("Jogador") as Node3D
	if jogador_existente != null:
		return jogador_existente

	var jogador_instanciado: Node3D = CENA_DO_JOGADOR.instantiate() as Node3D
	if jogador_instanciado == null:
		return null

	jogador_instanciado.name = "Jogador"
	cena_atual.add_child(jogador_instanciado)
	return jogador_instanciado

func _posicionar_jogador_no_spawn(cena_atual: Node, jogador_da_cena: Node3D) -> void:
	if _nome_da_area_de_spawn == "":
		return

	var pontos_de_spawn: Node = cena_atual.get_node_or_null("PontosDeSpawn")
	if pontos_de_spawn == null:
		return

	var spawn_da_area: Node3D = pontos_de_spawn.get_node_or_null(_nome_da_area_de_spawn) as Node3D
	if spawn_da_area == null:
		return

	jogador_da_cena.global_position = spawn_da_area.global_position
	jogador_da_cena.global_rotation = spawn_da_area.global_rotation

func _configurar_camera_para_seguir_jogador(cena_atual: Node, jogador_da_cena: Node3D) -> void:
	var camera_pivot: Node3D = _buscar_camera(cena_atual)
	if camera_pivot == null:
		return

	if jogador_da_cena is Jogador:
		var jogador_tipado: Jogador = jogador_da_cena as Jogador
		jogador_tipado.camera_pivot = camera_pivot

	var seguir_jogador: Node = camera_pivot.get_node_or_null("SeguirJogador")
	if seguir_jogador == null:
		return

	if seguir_jogador.has_method("configurar_para_jogador"):
		seguir_jogador.call("configurar_para_jogador", jogador_da_cena, camera_pivot)

func _buscar_camera(cena_atual: Node) -> Node3D:
	var camera_direta: Node3D = cena_atual.get_node_or_null("Camera") as Node3D
	if camera_direta != null:
		return camera_direta

	return cena_atual.find_child("Camera", true, false) as Node3D
