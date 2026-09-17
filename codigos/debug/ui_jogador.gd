extends CanvasLayer


@export var jogador: Jogador
@export var label_velocidade: Label

func _process(_delta: float) -> void:
	if jogador and label_velocidade:
		label_velocidade.text = "Velocidade: " + str(jogador.velocidade_atual)
