extends Control

@export var texto_label: RichTextLabel
@export var tempo_por_caractere: float = 0.05
@export var tempo_pausa_entre_frases: float = 1.5
@export var audioVento: AudioStreamPlayer
@export var opening_fade_duration: float = 0.8


const MAIN_SCENE_PATH: String = "res://cenas/principal.tscn"

var opening_fade_overlay: ColorRect
var skip_dialog: ConfirmationDialog
var is_skip_dialog_open: bool = false
var is_transitioning: bool = false
var frases: Array[String] = [

"Winter is coming",

"This time, I'm all alone",

"But I'm not afraid",

"My elders taught me how to gather nuts to survive the winter",

"I just need to collect them with [b][wave][color=#ffb379]A/E[/color][/wave][/b] and store them in my burrow",

"I just need to be careful not to wake the big bear in the cave",

"[wave]Otherwise, he'll attack me![wave]",

"I'll be fine..."
]
func _ready() -> void:
	setup_opening_fade_overlay()
	setup_skip_dialog()

	if audioVento != null:
		if not audioVento.finished.is_connected(_on_audio_vento_finished):
			audioVento.finished.connect(_on_audio_vento_finished)
		audioVento.play()

	await play_opening_fade()

	if texto_label != null:
		texto_label.bbcode_enabled = true
		exibir_frases_sequenciais()

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return

	if event.is_action_pressed("ui_accept"):
		show_skip_dialog()
		get_viewport().set_input_as_handled()

func setup_skip_dialog() -> void:
	skip_dialog = ConfirmationDialog.new()
	skip_dialog.name = "SkipDialog"
	skip_dialog.title = "Pular introducao"
	skip_dialog.dialog_text = "Deseja pular esta cena e ir para a gameplay?"
	skip_dialog.get_ok_button().text = "Sim"
	skip_dialog.get_cancel_button().text = "Nao"
	skip_dialog.unresizable = true
	skip_dialog.exclusive = true
	skip_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(skip_dialog)

	if not skip_dialog.confirmed.is_connected(_on_skip_dialog_confirmed):
		skip_dialog.confirmed.connect(_on_skip_dialog_confirmed)
	if not skip_dialog.canceled.is_connected(_on_skip_dialog_closed):
		skip_dialog.canceled.connect(_on_skip_dialog_closed)
	if not skip_dialog.close_requested.is_connected(_on_skip_dialog_closed):
		skip_dialog.close_requested.connect(_on_skip_dialog_closed)

func show_skip_dialog() -> void:
	if skip_dialog == null or is_skip_dialog_open:
		return

	is_skip_dialog_open = true
	get_tree().paused = true
	skip_dialog.popup_centered()

func _on_skip_dialog_confirmed() -> void:
	is_skip_dialog_open = false
	get_tree().paused = false
	go_to_main_scene_with_fade()

func _on_skip_dialog_closed() -> void:
	is_skip_dialog_open = false
	get_tree().paused = false

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

func exibir_frases_sequenciais() -> void:
	for frase in frases:
		texto_label.text = frase
		texto_label.visible_ratio = 0.0
		
		# Calcula a duração da animação baseada na quantidade de caracteres do texto limpo (sem tags BBCode)
		var tamanho_texto: int = texto_label.get_parsed_text().length()
		var duracao_escrita: float = tamanho_texto * tempo_por_caractere
		
		# Anima o texto aparecendo da esquerda para a direita
		var tween := create_tween()
		tween.tween_property(texto_label, "visible_ratio", 1.0, duracao_escrita)
		await tween.finished
		
		# Pausa para o jogador conseguir ler a frase antes de passar para a próxima
		await get_tree().create_timer(tempo_pausa_entre_frases).timeout
	
	await go_to_main_scene_with_fade()

func go_to_main_scene_with_fade() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	var next_scene_resource: Resource = load(MAIN_SCENE_PATH)
	if not (next_scene_resource is PackedScene):
		push_warning("Could not load main scene: " + MAIN_SCENE_PATH)
		is_transitioning = false
		return

	var next_scene: PackedScene = next_scene_resource as PackedScene
	var global_transition: Node = get_node_or_null("/root/GlobalTransicaoDeCena")
	if global_transition != null and global_transition.has_method("trocar_cena_com_fade"):
		global_transition.call("trocar_cena_com_fade", next_scene, "")
		return

	get_tree().change_scene_to_packed(next_scene)

func _on_audio_vento_finished() -> void:
	if audioVento == null:
		return

	audioVento.play()

func _exit_tree() -> void:
	# Avoid leaving the project paused if this scene gets replaced while dialog is open.
	get_tree().paused = false