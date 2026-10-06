class_name Caverna
extends StaticBody3D

const LIMITE_DE_BARULHO :float = 100.0
const CAMINHO_AUDIO_ALERTA_CAVERNA: String = "res://arte/audio/sfx/urso_gritando.mp3"
const CENA_CREDITOS: PackedScene = preload("res://cenas/cena_creditos.tscn")
const MENSAGEM_DE_GAME_OVER: String = "The bear woke up.\n\nTRY AGAIN"
const EXPOENTE_DA_CURVA_DE_TREMOR: float = 1.5

enum EstadoDaSequenciaDeRugido {
	OCIOSO,
	EXECUTANDO
}

@export var audio_alerta_caverna: AudioStreamPlayer
@export var olhos_luminosos: Node3D
@export var distancia_do_arremesso_em_metros: float = 3.8
@export var duracao_do_arremesso_em_segundos: float = 2.5
@export var atraso_antes_da_transicao_em_segundos: float = 3.35
@export var nome_da_area_de_spawn_na_cabana: String = "CABANA"
@export var distancia_minima_do_drop_em_metros: float = 1.0
@export var distancia_maxima_do_drop_em_metros: float = 1.8
@export var taxa_de_reducao_de_barulho_por_segundo: float = 0.0
@export var limiar_minimo_para_inquietacao_visual: float = 1.0
@export var intensidade_maxima_do_tremor_local: float = 0.12
@export var frequencia_do_tremor_local: float = 5.0
@export var camera_shake_max_amplitude: float = 0.1
@export var camera_shake_cap_stress_level: float = 20.0

var percentual_de_barulho_atual: float = 0.0
var estado_da_sequencia_de_rugido: EstadoDaSequenciaDeRugido = EstadoDaSequenciaDeRugido.OCIOSO
var _posicao_local_inicial_da_caverna: Vector3 = Vector3.ZERO
var _escala_inicial_olhos: Vector3 = Vector3.ONE
var _intensidade_visual_inercial: float = 0.0
var _tempo_feedback_inquietacao: float = 0.0


func _ready() -> void:
	add_to_group("persistencia_da_caverna")
	_inicializar_audio_alerta_caverna()
	if olhos_luminosos != null:
		olhos_luminosos.visible = false
		_escala_inicial_olhos = olhos_luminosos.scale
	_posicao_local_inicial_da_caverna = position
	_restaurar_snapshot_da_caverna_da_cena_atual()

func _process(delta: float) -> void:
	_tempo_feedback_inquietacao += delta

	if estado_da_sequencia_de_rugido == EstadoDaSequenciaDeRugido.EXECUTANDO:
		# Durante o rugido final, mantem a caverna no pico de inquietacao visual.
		percentual_de_barulho_atual = LIMITE_DE_BARULHO
		_intensidade_visual_inercial = 1.0
		_atualizar_feedback_visual_da_inquietacao(delta)
		return

	_reduzir_percentual_de_barulho_ao_longo_do_tempo(delta)
	_atualizar_feedback_visual_da_inquietacao(delta)

func obter_snapshot_para_salvamento() -> Dictionary:
	return {
		"percentual_de_barulho_atual": percentual_de_barulho_atual
	}

func aplicar_snapshot_do_salvamento(snapshot: Dictionary) -> void:
	if snapshot == null or snapshot.is_empty():
		return

	percentual_de_barulho_atual = clampf(float(snapshot.get("percentual_de_barulho_atual", 0.0)), 0.0, LIMITE_DE_BARULHO)
	_intensidade_visual_inercial = clampf(percentual_de_barulho_atual / LIMITE_DE_BARULHO, 0.0, 1.0)

func _restaurar_snapshot_da_caverna_da_cena_atual() -> void:
	if GlobalGerenciadorDeSalvamento == null:
		return

	var snapshot: Dictionary = GlobalGerenciadorDeSalvamento.obter_snapshot_da_caverna_da_cena_atual_para(self)
	if snapshot.is_empty():
		return

	aplicar_snapshot_do_salvamento(snapshot)

func registrar_disparo_de_barulho_detectado(barulho: float) -> void:
	_definir_percentual_de_barulho_atual(barulho)

func _definir_percentual_de_barulho_atual(percentual: float) -> void:
	var percentual_anterior = percentual_de_barulho_atual
	percentual_de_barulho_atual = clampf(percentual_de_barulho_atual + clampf(percentual, 0.0, LIMITE_DE_BARULHO), 0.0, LIMITE_DE_BARULHO)
	_intensidade_visual_inercial = max(_intensidade_visual_inercial, percentual_de_barulho_atual / LIMITE_DE_BARULHO)
	if percentual_anterior < LIMITE_DE_BARULHO and percentual_de_barulho_atual >= LIMITE_DE_BARULHO:
		_iniciar_sequencia_de_rugido_da_caverna()

func _iniciar_sequencia_de_rugido_da_caverna() -> void:
	if estado_da_sequencia_de_rugido == EstadoDaSequenciaDeRugido.EXECUTANDO:
		return

	estado_da_sequencia_de_rugido = EstadoDaSequenciaDeRugido.EXECUTANDO
	_tocar_audio_alerta_caverna()
	_ativar_efeitos_visuais_da_caverna()
	GlobalGerenciadorDeSinais.configurar_contexto_dos_creditos(
		GlobalGerenciadorDeSinais.ContextoDosCreditos.GAME_OVER,
		MENSAGEM_DE_GAME_OVER,
		true
	)
	GlobalGerenciadorDeSinais.tentativa_na_caverna_encerrada.emit()

	if GlobalTransicaoDeCena != null and CENA_CREDITOS != null:
		GlobalTransicaoDeCena.trocar_cena_com_fade(CENA_CREDITOS, "")


func _ativar_efeitos_visuais_da_caverna() -> void:
	if olhos_luminosos != null:
		olhos_luminosos.visible = true


func _apply_camera_shake(intensity: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var capped_intensity: float = minf(intensity, camera_shake_cap_stress_level / LIMITE_DE_BARULHO)
	var amplitude: float = camera_shake_max_amplitude * pow(capped_intensity, EXPOENTE_DA_CURVA_DE_TREMOR)
	camera.h_offset = randf_range(-amplitude, amplitude)
	camera.v_offset = randf_range(-amplitude, amplitude)

func _obter_jogador_da_cena() -> Jogador:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return null

	var jogador_direto: Jogador = cena_atual.get_node_or_null("TUDO/Jogador") as Jogador
	if jogador_direto != null:
		return jogador_direto

	return cena_atual.find_child("Jogador", true, false) as Jogador

func _setar_controle_de_movimento_do_jogador(jogador: Jogador, ativo: bool) -> void:
	if jogador == null:
		return

	var no_movimento: Node = jogador.get_node_or_null("Codigos/Movimentos")
	if no_movimento != null:
		no_movimento.set_process(ativo)
		no_movimento.set_physics_process(ativo)
		no_movimento.set_process_input(ativo)
		no_movimento.set_process_unhandled_input(ativo)

	if not ativo:
		jogador.velocity = Vector3.ZERO

func _arremessar_jogador_para_longe(jogador: Jogador) -> void:
	if jogador == null:
		return

	var direcao_para_fora: Vector3 = jogador.global_position - global_position
	direcao_para_fora.y = 0.0
	if direcao_para_fora.length() <= 0.001:
		direcao_para_fora = Vector3.BACK
	else:
		direcao_para_fora = direcao_para_fora.normalized()

	var distancia_arremesso: float = max(distancia_do_arremesso_em_metros, 0.5)
	var destino: Vector3 = jogador.global_position + (direcao_para_fora * distancia_arremesso)
	destino.y = jogador.global_position.y

	var tween_arremesso: Tween = create_tween()
	tween_arremesso.set_parallel(true)
	tween_arremesso.tween_property(jogador, "global_position", destino, max(duracao_do_arremesso_em_segundos, 0.1))\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
	tween_arremesso.tween_property(jogador, "rotation_degrees:z", -22.0, max(duracao_do_arremesso_em_segundos * 0.5, 0.05))\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween_arremesso.chain().tween_property(jogador, "rotation_degrees:z", 0.0, max(duracao_do_arremesso_em_segundos * 0.5, 0.05))\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	await tween_arremesso.finished

func _disparar_rajada_de_folhas_no_mapa() -> void:
	var cena_atual: Node = get_tree().current_scene
	if cena_atual == null:
		return

	var areas_de_folhas: AreasDeAparecimentoDasFolhas = cena_atual.find_child("AreasDeAparecimentoDasFolhas", true, false) as AreasDeAparecimentoDasFolhas
	if areas_de_folhas == null:
		return

	areas_de_folhas.registrar_posicoes_base_das_folhas_ativas()
	var direcao_sorteada: int = randi_range(0, 3)
	areas_de_folhas.aplicar_vento(direcao_sorteada)

func _derrubar_itens_do_jogador(jogador: Jogador) -> void:
	if jogador == null:
		return

	if GlobalItensQueOJogadorCarrega == null:
		return

	if GlobalItensQueOJogadorCarrega.itens_coletados.is_empty():
		return

	var itens_para_largar: Array[int] = GlobalItensQueOJogadorCarrega.itens_coletados.duplicate()
	var ids_dos_itens_para_largar: Array[StringName] = GlobalItensQueOJogadorCarrega.ids_dos_itens_no_inventario.duplicate()
	GlobalItensQueOJogadorCarrega.itens_coletados.clear()
	GlobalItensQueOJogadorCarrega.ids_dos_itens_no_inventario.clear()
	GlobalGerenciadorDeSinais.item_adicionado_ao_inventario.emit(0)

	var quantidade_de_itens: int = itens_para_largar.size()
	for i in quantidade_de_itens:
		var tipo_item: int = itens_para_largar[i]
		var id_do_item_no_mapa: StringName = StringName()
		if i < ids_dos_itens_para_largar.size():
			id_do_item_no_mapa = ids_dos_itens_para_largar[i]
		var item_instanciado: ItemColetavel = GlobalItensQueOJogadorCarrega.criar_item_por_tipo(tipo_item)
		if item_instanciado == null:
			continue

		item_instanciado.id_unico_do_item_no_mapa = id_do_item_no_mapa
		item_instanciado.set_meta("item_spawnado_via_drop_persistido", true)

		var angulo: float = (TAU * float(i)) / max(float(quantidade_de_itens), 1.0)
		var distancia_do_drop: float = randf_range(distancia_minima_do_drop_em_metros, distancia_maxima_do_drop_em_metros)
		var deslocamento: Vector3 = Vector3(cos(angulo), 0.0, sin(angulo)) * distancia_do_drop
		var posicao_drop: Vector3 = jogador.global_position + deslocamento
		var id_item_dropado_no_mundo: StringName = StringName()
		if GlobalGerenciadorDeSalvamento != null:
			id_item_dropado_no_mundo = GlobalGerenciadorDeSalvamento.registrar_item_dropado_na_cena_atual(tipo_item, id_do_item_no_mapa, posicao_drop)

		get_tree().current_scene.add_child(item_instanciado)
		item_instanciado.set_meta("id_item_dropado_no_mundo", id_item_dropado_no_mundo)
		item_instanciado.largar_na_posicao(posicao_drop)

	GlobalGerenciadorDeSinais.velocidade_do_jogador_resetada.emit()


func _inicializar_audio_alerta_caverna() -> void:
	if audio_alerta_caverna == null:
		audio_alerta_caverna = AudioStreamPlayer.new()
		audio_alerta_caverna.name = "AudioAlertaCaverna"
		add_child(audio_alerta_caverna)

	if audio_alerta_caverna.stream == null:
		audio_alerta_caverna.stream = load(CAMINHO_AUDIO_ALERTA_CAVERNA) as AudioStream


func _tocar_audio_alerta_caverna() -> void:
	if audio_alerta_caverna == null:
		return

	if audio_alerta_caverna.stream == null:
		return

	if audio_alerta_caverna.playing:
		audio_alerta_caverna.stop()

	audio_alerta_caverna.play()

func _reduzir_percentual_de_barulho_ao_longo_do_tempo(delta: float) -> void:
	if percentual_de_barulho_atual <= 0.0:
		percentual_de_barulho_atual = 0.0
		return

	var reducao: float = max(taxa_de_reducao_de_barulho_por_segundo, 0.0) * delta
	percentual_de_barulho_atual = max(percentual_de_barulho_atual - reducao, 0.0)

func _atualizar_feedback_visual_da_inquietacao(delta: float) -> void:
	var intensidade_alvo: float = clampf(percentual_de_barulho_atual / LIMITE_DE_BARULHO, 0.0, 1.0)
	# A intensidade visual so sobe: depois que comeca a tremer, nunca para ate reiniciar o jogo.
	if intensidade_alvo > _intensidade_visual_inercial:
		_intensidade_visual_inercial = move_toward(_intensidade_visual_inercial, intensidade_alvo, 9.5 * delta)

	var intensidade_normalizada: float = clampf(_intensidade_visual_inercial, 0.0, 1.0)
	if intensidade_normalizada <= 0.001 and percentual_de_barulho_atual <= limiar_minimo_para_inquietacao_visual:
		_resetar_feedback_visual_da_inquietacao()
		return

	_aplicar_tremor_local_da_caverna(intensidade_normalizada)
	_atualizar_olhos_luminosos(intensidade_normalizada)
	_apply_camera_shake(intensidade_alvo)

func _aplicar_tremor_local_da_caverna(intensidade_normalizada: float) -> void:
	var amplitude: float = intensidade_maxima_do_tremor_local * pow(intensidade_normalizada, EXPOENTE_DA_CURVA_DE_TREMOR)
	# Pulsos lentos simulam o rosnado; o jitter aleatorio rapido evita o balanco suave que desloca a caverna.
	var pulso_de_rosnado: float = 0.5 + 0.5 * sin(_tempo_feedback_inquietacao * max(frequencia_do_tremor_local, 0.1) * 0.35)
	var amplitude_com_rosnado: float = amplitude * lerpf(0.4, 1.0, pulso_de_rosnado * pulso_de_rosnado)
	var deslocamento: Vector3 = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0) * 0.4,
		randf_range(-1.0, 1.0)
	) * amplitude_com_rosnado
	position = _posicao_local_inicial_da_caverna + deslocamento

func _atualizar_olhos_luminosos(intensidade_normalizada: float) -> void:
	if olhos_luminosos == null:
		return

	olhos_luminosos.visible = true
	var pulsacao: float = 1.0 + (0.32 * intensidade_normalizada * (0.5 + 0.5 * sin(_tempo_feedback_inquietacao * 11.0)))
	olhos_luminosos.scale = _escala_inicial_olhos * pulsacao


func _resetar_feedback_visual_da_inquietacao() -> void:
	position = _posicao_local_inicial_da_caverna
	_intensidade_visual_inercial = 0.0
	_apply_camera_shake(0.0)

	if olhos_luminosos != null:
		olhos_luminosos.visible = false
		olhos_luminosos.scale = _escala_inicial_olhos

