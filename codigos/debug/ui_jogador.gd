extends CanvasLayer


@export var jogador: Jogador
@export var label_velocidade: Label
@export var label_barulho_total_jogador: Label

func _process(_delta: float) -> void:
	if jogador and label_velocidade:
		label_velocidade.text = "Velocidade: " + str(jogador.velocidade_atual)
	if jogador and label_barulho_total_jogador:
		label_barulho_total_jogador.text = "Barulho Total: " + str(GlobalGerenciadorDeBarulho.atual_quantidade_de_barulho_em_pixels_em_area_anelar)
