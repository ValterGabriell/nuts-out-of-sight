extends Node3D

@export var urso: Urso
@export var animationPlayer: AnimationPlayer

var estado_animacao_atual: StringName = &""


func _ready() -> void:
	if urso == null:
		urso = get_parent().get_parent() as Urso

	if animationPlayer == null and urso != null:
		animationPlayer = urso.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animationPlayer == null and urso != null:
		animationPlayer = urso.find_child("AnimationPlayer", true, false) as AnimationPlayer

	if urso != null:
		urso.estado_alterado.connect(_on_estado_urso_alterado)
	_sincronizar_animacao_com_estado()


func _sincronizar_animacao_com_estado() -> void:
	if urso == null or animationPlayer == null:
		return

	var nome_animacao: StringName = _obter_nome_animacao_por_estado(urso.estado_atual)
	if estado_animacao_atual == nome_animacao:
		return

	if not animationPlayer.has_animation(nome_animacao):
		return

	estado_animacao_atual = nome_animacao
	animationPlayer.play(nome_animacao)


func _obter_nome_animacao_por_estado(estado: Urso.EstadoUrso) -> StringName:
	match estado:
		Urso.EstadoUrso.DORMINDO:
			return _resolver_nome_animacao(PackedStringArray(["deitando"]))
		Urso.EstadoUrso.EM_ALERTA:
			return _resolver_nome_animacao(PackedStringArray(["terminando_caçada", "terminando_cacada"]))
		Urso.EstadoUrso.PERSEGUINDO:
			return _resolver_nome_animacao(PackedStringArray(["cacando", "caçando"]))
		_:
			return _resolver_nome_animacao(PackedStringArray(["deitando"]))


func _resolver_nome_animacao(candidatos: PackedStringArray) -> StringName:
	if candidatos.is_empty():
		return &""

	if animationPlayer != null:
		for candidato in candidatos:
			var nome_candidato: StringName = StringName(candidato)
			if animationPlayer.has_animation(nome_candidato):
				return nome_candidato

	return StringName(candidatos[0])


func _on_estado_urso_alterado(_novo_estado: Urso.EstadoUrso) -> void:
	_sincronizar_animacao_com_estado()
