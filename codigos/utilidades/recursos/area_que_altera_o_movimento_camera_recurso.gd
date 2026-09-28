class_name AreaQueAlteraOMovimentoCameraRecurso
extends Resource

@export var tempo_de_transicao: float = 1.0

## Escolha o estilo do movimento da câmera
@export_enum(
	"Linear: Movimento direto sem aceleração (robótico):0",
	"Suave / Senoidal: Movimento fluido e natural (Recomendado):1",
	"Quadrática: Aceleração e desaceleração leve:2",
	"Cúbica: Aceleração moderada:3",
	"Quártica: Início e fim bem lentos",
	"Quíntica: Aceleração muito forte:5",
	"Exponencial: Arrancada ou travagem muito brusca:6",
	"Circular: Movimento rápido quase no final:7",
	"Elástico: Efeito mola (passa do ponto e balança):8",
	"Quique / Bola: Quica ao chegar no destino:9",
	"Recuo / Back: Recua um pouco antes de ir para a frente:10"
) var tipo_transicao: int = Tween.TRANS_SINE

## Escolha onde o movimento deve acelerar ou frear
@export_enum(
	"Acelerar no início (In):0",
	"Frear no final (Out - Recomendado):1",
	"Acelerar no início e frear no final (InOut):2",
	"Rápido nas pontas e lento no meio (OutIn):3"
) var tipo_easing: int = Tween.EASE_OUT