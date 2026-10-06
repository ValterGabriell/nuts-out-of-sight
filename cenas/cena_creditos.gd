extends Control


@export var texto_label: RichTextLabel
@export var tempo_por_caractere: float = 0.05
@export var tempo_pausa_entre_frases: float = 1.5
@export var audioVento: AudioStreamPlayer
@export var opening_fade_duration: float = 0.8

const MAIN_SCENE_PATH: String = "res://cenas/principal.tscn"
const CREDITOS_FILE_PATH: String = "res://creditos.txt"

var opening_fade_overlay: ColorRect
var botao_tentar_novamente: Button
var is_transitioning: bool = false

func _ready() -> void:
	setup_opening_fade_overlay()
	_setup_botao_tentar_novamente()
	_configurar_loop_do_audio_de_vento()

	await play_opening_fade()

	if texto_label == null:
		return

	texto_label.bbcode_enabled = true
	var texto_final: String = _montar_texto_final_dos_creditos()
	await _animar_texto(texto_final)

	if GlobalGerenciadorDeSinais.deve_exibir_botao_tentar_novamente_nos_creditos():
		botao_tentar_novamente.visible = true
		botao_tentar_novamente.grab_focus()

func _configurar_loop_do_audio_de_vento() -> void:
	if audioVento == null:
		return

	if not audioVento.finished.is_connected(_on_audio_vento_finished):
		audioVento.finished.connect(_on_audio_vento_finished)
	audioVento.play()

func _setup_botao_tentar_novamente() -> void:
	botao_tentar_novamente = Button.new()
	botao_tentar_novamente.name = "BotaoTentarNovamente"
	botao_tentar_novamente.text = "TENTAR NOVAMENTE"
	botao_tentar_novamente.visible = false
	botao_tentar_novamente.focus_mode = Control.FOCUS_ALL
	botao_tentar_novamente.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao_tentar_novamente.size_flags_vertical = Control.SIZE_SHRINK_END
	botao_tentar_novamente.custom_minimum_size = Vector2(320.0, 56.0)
	botao_tentar_novamente.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	botao_tentar_novamente.offset_left = -160.0
	botao_tentar_novamente.offset_right = 160.0
	botao_tentar_novamente.offset_top = -110.0
	botao_tentar_novamente.offset_bottom = -40.0
	add_child(botao_tentar_novamente)

	if not botao_tentar_novamente.pressed.is_connected(_on_botao_tentar_novamente_pressionado):
		botao_tentar_novamente.pressed.connect(_on_botao_tentar_novamente_pressionado)

func _on_botao_tentar_novamente_pressionado() -> void:
	if GlobalGerenciadorDeSalvamento != null and GlobalGerenciadorDeSalvamento.has_method("apagar_save_e_reiniciar_progresso"):
		GlobalGerenciadorDeSalvamento.apagar_save_e_reiniciar_progresso()
	go_to_main_scene_with_fade()

func setup_opening_fade_overlay() -> void:
	opening_fade_overlay = ColorRect.new()
	opening_fade_overlay.name = "OpeningFadeOverlay"
	opening_fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	opening_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	opening_fade_overlay.offset_left = 0.0
	opening_fade_overlay.offset_top = 0.0
	opening_fade_overlay.offset_right = 0.0
	opening_fade_overlay.offset_bottom = 0.0
	add_child(opening_fade_overlay)
	move_child(opening_fade_overlay, get_child_count() - 1)

func play_opening_fade() -> void:
	if opening_fade_overlay == null:
		return

	if opening_fade_duration <= 0.0:
		opening_fade_overlay.queue_free()
		opening_fade_overlay = null
		return

	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(opening_fade_overlay, "color:a", 0.0, opening_fade_duration)
	await fade_tween.finished

	opening_fade_overlay.queue_free()
	opening_fade_overlay = null

func _montar_texto_final_dos_creditos() -> String:
	var linhas: PackedStringArray = _carregar_linhas_do_arquivo_de_creditos()
	var creditos_formatados: String = _formatar_creditos_com_bbcode(linhas)
	var mensagem_de_abertura: String = GlobalGerenciadorDeSinais.obter_mensagem_de_abertura_dos_creditos().strip_edges()

	if mensagem_de_abertura.is_empty():
		var contexto: int = int(GlobalGerenciadorDeSinais.obter_contexto_dos_creditos())
		if contexto == int(GlobalGerenciadorDeSinais.ContextoDosCreditos.VITORIA):
			mensagem_de_abertura = "OBRIGADO!\n\nE assim, o pequeno esquilo conseguiu a comida suficiente para o inverno..."
		else:
			mensagem_de_abertura = "O urso despertou.\n\nTENTE NOVAMENTE"

	return "[center][b]" + mensagem_de_abertura + "[/b][/center]\n\n" + creditos_formatados

func _carregar_linhas_do_arquivo_de_creditos() -> PackedStringArray:
	if not FileAccess.file_exists(CREDITOS_FILE_PATH):
		return PackedStringArray(["Créditos indisponíveis no momento."])

	var arquivo: FileAccess = FileAccess.open(CREDITOS_FILE_PATH, FileAccess.READ)
	if arquivo == null:
		return PackedStringArray(["Créditos indisponíveis no momento."])

	var conteudo: String = arquivo.get_as_text()
	return conteudo.split("\n")

func _formatar_creditos_com_bbcode(linhas: PackedStringArray) -> String:
	var blocos: Array[Array] = []
	var bloco_atual: Array[String] = []

	for linha_raw in linhas:
		var linha: String = linha_raw.strip_edges()
		if linha.is_empty():
			if not bloco_atual.is_empty():
				blocos.append(bloco_atual)
				bloco_atual = []
			continue
		bloco_atual.append(linha)

	if not bloco_atual.is_empty():
		blocos.append(bloco_atual)

	var texto_final: String = "[center][color=#ffe3a1][b]CRÉDITOS[/b][/color][/center]\n\n"
	for bloco in blocos:
		if bloco.is_empty():
			continue
		var titulo: String = bloco[0]
		texto_final += "[b][color=#ffd27a]" + titulo + "[/color][/b]\n"
		for i in range(1, bloco.size()):
			var valor: String = bloco[i]
			if valor.begins_with("http://") or valor.begins_with("https://"):
				texto_final += "[color=#9dd8ff]" + valor + "[/color]\n"
			else:
				texto_final += valor + "\n"
		texto_final += "\n"

	return texto_final.strip_edges()

func _animar_texto(texto: String) -> void:
	texto_label.text = texto
	texto_label.visible_ratio = 0.0

	var tamanho_texto: int = texto_label.get_parsed_text().length()
	var duracao_escrita: float = max(float(tamanho_texto) * tempo_por_caractere, 0.1)
	var tween := create_tween()
	tween.tween_property(texto_label, "visible_ratio", 1.0, duracao_escrita)
	await tween.finished

	if tempo_pausa_entre_frases > 0.0:
		await get_tree().create_timer(tempo_pausa_entre_frases).timeout

func go_to_main_scene_with_fade() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	var next_scene_resource: Resource = load(MAIN_SCENE_PATH)
	if not (next_scene_resource is PackedScene):
		push_warning("Could not load main scene: " + MAIN_SCENE_PATH)
		is_transitioning = false
		return

	GlobalGerenciadorDeSinais.configurar_contexto_dos_creditos(
		GlobalGerenciadorDeSinais.ContextoDosCreditos.GAME_OVER,
		"",
		true
	)

	var next_scene: PackedScene = next_scene_resource as PackedScene
	if GlobalTransicaoDeCena != null and GlobalTransicaoDeCena.has_method("trocar_cena_com_fade"):
		GlobalTransicaoDeCena.trocar_cena_com_fade(next_scene, "")
		return

	get_tree().change_scene_to_packed(next_scene)

func _on_audio_vento_finished() -> void:
	if audioVento == null:
		return

	audioVento.play()