class_name MovimentoQueModificaOItemQueFazBarulho
extends Node3D

@export var area_aparecimento_das_folhas:AreasDeAparecimentoDasFolhas
@export var intervalo_entre_rajadas_em_segundos: float = 10.0
@export var pre_aviso_minimo_em_segundos: float = 3.0
@export var pre_aviso_maximo_em_segundos: float = 6.0

enum EstadoDoCicloDoVento {
	AGUARDANDO_PRE_AVISO,
	AGUARDANDO_RAJADA
}

enum DirecaoDoVento {
	NORTE,
	SUL,
	LESTE,
	OESTE
}

var timer_que_representa_o_tempo_que_fica_sem_ventar: Timer
var timer_que_representa_o_tempo_ate_rajada: Timer
var direcao_atual_do_vento: DirecaoDoVento
var estado_atual_do_ciclo: EstadoDoCicloDoVento = EstadoDoCicloDoVento.AGUARDANDO_PRE_AVISO
var duracao_pre_aviso_atual: float = 0.0

func _ready() -> void:
	timer_que_representa_o_tempo_que_fica_sem_ventar = Timer.new()
	timer_que_representa_o_tempo_que_fica_sem_ventar.one_shot = true
	add_child(timer_que_representa_o_tempo_que_fica_sem_ventar)
	timer_que_representa_o_tempo_que_fica_sem_ventar.timeout.connect(_on_timer_timeout)

	timer_que_representa_o_tempo_ate_rajada = Timer.new()
	timer_que_representa_o_tempo_ate_rajada.one_shot = true
	add_child(timer_que_representa_o_tempo_ate_rajada)
	timer_que_representa_o_tempo_ate_rajada.timeout.connect(_on_timer_ate_rajada_timeout)

	iniciar_ciclo_do_vento()
	_emitir_debug_de_vento()

func _process(_delta: float) -> void:
	_emitir_debug_de_vento()

func iniciar_ciclo_do_vento() -> void:
	duracao_pre_aviso_atual = 0.0
	var pre_aviso_sorteado = _sortear_duracao_de_pre_aviso()
	var tempo_ate_pre_aviso = max(intervalo_entre_rajadas_em_segundos - pre_aviso_sorteado, 0.1)
	state_aguardando_pre_aviso(tempo_ate_pre_aviso)

func state_aguardando_pre_aviso(tempo_espera: float) -> void:
	estado_atual_do_ciclo = EstadoDoCicloDoVento.AGUARDANDO_PRE_AVISO
	timer_que_representa_o_tempo_que_fica_sem_ventar.wait_time = tempo_espera
	timer_que_representa_o_tempo_que_fica_sem_ventar.start()

func state_aguardando_rajada(tempo_espera: float) -> void:
	estado_atual_do_ciclo = EstadoDoCicloDoVento.AGUARDANDO_RAJADA
	timer_que_representa_o_tempo_ate_rajada.wait_time = tempo_espera
	timer_que_representa_o_tempo_ate_rajada.start()

func _sortear_duracao_de_pre_aviso() -> float:
	if pre_aviso_maximo_em_segundos < pre_aviso_minimo_em_segundos:
		return pre_aviso_minimo_em_segundos
	return randf_range(pre_aviso_minimo_em_segundos, pre_aviso_maximo_em_segundos)

func _on_timer_timeout() -> void:
	area_aparecimento_das_folhas.registrar_posicoes_base_das_folhas_ativas()
	direcao_atual_do_vento = DirecaoDoVento.values()[randi() % DirecaoDoVento.values().size()]
	duracao_pre_aviso_atual = _sortear_duracao_de_pre_aviso()
	area_aparecimento_das_folhas.aplicar_pre_aviso_de_vento(direcao_atual_do_vento, duracao_pre_aviso_atual)
	state_aguardando_rajada(duracao_pre_aviso_atual)
	_emitir_debug_de_vento()

func _on_timer_ate_rajada_timeout() -> void:
	area_aparecimento_das_folhas.aplicar_vento(direcao_atual_do_vento)
	iniciar_ciclo_do_vento()
	_emitir_debug_de_vento()

func _emitir_debug_de_vento() -> void:
	GlobalGerenciadorDeSinais.debug_vento_atualizado.emit(_obter_dados_debug_vento())

func _obter_dados_debug_vento() -> Dictionary:
	return {
		"estado": _obter_nome_do_estado(),
		"direcao_atual": _obter_nome_da_direcao_atual(),
		"tempo_ate_pre_aviso": _obter_tempo_restante_do_pre_aviso(),
		"tempo_ate_rajada": _obter_tempo_restante_da_rajada(),
		"intervalo_entre_rajadas_em_segundos": intervalo_entre_rajadas_em_segundos,
		"pre_aviso_minimo_em_segundos": pre_aviso_minimo_em_segundos,
		"pre_aviso_maximo_em_segundos": pre_aviso_maximo_em_segundos,
		"duracao_pre_aviso_atual": duracao_pre_aviso_atual
	}

func _obter_nome_do_estado() -> String:
	match estado_atual_do_ciclo:
		EstadoDoCicloDoVento.AGUARDANDO_PRE_AVISO:
			return "AGUARDANDO_PRE_AVISO"
		EstadoDoCicloDoVento.AGUARDANDO_RAJADA:
			return "AGUARDANDO_RAJADA"
		_:
			return "DESCONHECIDO"

func _obter_nome_da_direcao_atual() -> String:
	match direcao_atual_do_vento:
		DirecaoDoVento.NORTE:
			return "NORTE"
		DirecaoDoVento.SUL:
			return "SUL"
		DirecaoDoVento.LESTE:
			return "LESTE"
		DirecaoDoVento.OESTE:
			return "OESTE"
		_:
			return "N/A"

func _obter_tempo_restante_do_pre_aviso() -> float:
	if not timer_que_representa_o_tempo_que_fica_sem_ventar:
		return 0.0
	return max(timer_que_representa_o_tempo_que_fica_sem_ventar.time_left, 0.0)

func _obter_tempo_restante_da_rajada() -> float:
	if not timer_que_representa_o_tempo_ate_rajada:
		return 0.0
	return max(timer_que_representa_o_tempo_ate_rajada.time_left, 0.0)
	
