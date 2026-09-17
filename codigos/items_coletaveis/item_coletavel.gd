class_name ItemColetavel extends Area3D

enum TipoItem {
	COLETAVEL_NOZ = 111,
	COLETAVEL_NOZ_PESADA=112
}

enum EstadoItem {
	NO_MUNDO,
	NO_INVENTARIO
}

@export var tipo_item: TipoItem = TipoItem.COLETAVEL_NOZ
@export var label_acao: Label3D
@export var percentual_reducao_velocidade: float = 0.0
@export var id_unico_do_item_no_mapa: StringName

var _jogador: Jogador = null
var _estado_item: EstadoItem = EstadoItem.NO_MUNDO
var _camada_colisao_original: int = 0
var _mascara_colisao_original: int = 0


func _ready() -> void:
	_camada_colisao_original = collision_layer
	_mascara_colisao_original = collision_mask
	if GlobalItensNaCabana.obter_estado_do_item_no_registro(id_unico_do_item_no_mapa) == GlobalItensNaCabana.EstadoDoItemNoRegistro.COLETADO:
		queue_free()
		return

func _on_body_entered(body: Node3D) -> void:
	if body is Jogador:
		_jogador = body
		label_acao.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is Jogador:
		_jogador = null
		label_acao.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _jogador and _estado_item == EstadoItem.NO_MUNDO and event.is_action_pressed("interagir"):
		GlobalItensQueOJogadorCarrega.adicionar_item_ao_inventario(self)
		GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(GlobalItensQueOJogadorCarrega.itens_coletados.size())
		if percentual_reducao_velocidade > 0.0:
			GlobalGerenciadorDeSinais.velocidade_do_jogador_alterada.emit(percentual_reducao_velocidade)
		coletar()


func coletar() -> void:
	GlobalItensNaCabana.registrar_item_coletado(id_unico_do_item_no_mapa)
	_estado_item = EstadoItem.NO_INVENTARIO
	_jogador = null
	label_acao.visible = false
	visible = false
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	set_process_unhandled_input(false)


func largar_na_posicao(posicao_global: Vector3) -> void:
	_estado_item = EstadoItem.NO_MUNDO
	global_position = posicao_global
	visible = true
	monitoring = true
	monitorable = true
	collision_layer = _camada_colisao_original
	collision_mask = _mascara_colisao_original
	set_process_unhandled_input(true)
