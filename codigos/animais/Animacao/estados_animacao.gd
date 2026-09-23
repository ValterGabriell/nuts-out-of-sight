extends Node3D

@export var urso: Urso
@export var animatedSprite: AnimatedSprite3D

var estado_animacao_atual: StringName = &""


func _ready() -> void:
	if urso == null:
		urso = get_parent().get_parent() as Urso

	if animatedSprite == null and urso != null:
		animatedSprite = urso.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D

	if urso != null:
		urso.estado_alterado.connect(_on_estado_urso_alterado)
	_sincronizar_animacao_com_estado()


func _sincronizar_animacao_com_estado() -> void:
	if urso == null or animatedSprite == null:
		return

	var nome_animacao: StringName = _obter_nome_animacao_por_estado(urso.estado_atual)
	if estado_animacao_atual == nome_animacao:
		return

	if not animatedSprite.sprite_frames.has_animation(nome_animacao):
		return

	estado_animacao_atual = nome_animacao
	animatedSprite.play(nome_animacao)


func _obter_nome_animacao_por_estado(estado: Urso.EstadoUrso) -> StringName:
	var chaves_do_enum: PackedStringArray = Urso.EstadoUrso.keys()
	return StringName(chaves_do_enum[estado])


func _on_estado_urso_alterado(_novo_estado: Urso.EstadoUrso) -> void:
	_sincronizar_animacao_com_estado()
