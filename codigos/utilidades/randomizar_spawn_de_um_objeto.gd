class_name RandomizarSpawnDeUmObjeto
extends Node3D


enum TipoDeObjeto {
	NODE,
	AREA_3D
}

@export var tipo_de_objeto: TipoDeObjeto = TipoDeObjeto.NODE
@export var lista_de_objetos: Array[Node3D] = []
@export var lista_de_areas_para_randomizar_o_spawn: Array[Area3D] = []
@export var distancia_minima_entre_objetos: float = 0.7
@export var tentativas_por_objeto: int = 10

var gerador_aleatorio: RandomNumberGenerator = RandomNumberGenerator.new()
var contador_de_randomizacao: int = -1

func _ready() -> void:
	gerador_aleatorio.randomize()
	GlobalGerenciadorDeSinais.jogador_entrou_no_estoque.connect(_on_jogador_entrou_no_estoque)

func _on_jogador_entrou_no_estoque() -> void:
	contador_de_randomizacao += 1
	if contador_de_randomizacao == 0:
		return

	reordenar_objetos_no_spawn()

func reordenar_objetos_no_spawn() -> void:
	print("Reordenando objetos no spawn...")
	if lista_de_objetos.is_empty() or lista_de_areas_para_randomizar_o_spawn.is_empty():
		return

	var areas_validas: Array[Area3D] = []
	for area in lista_de_areas_para_randomizar_o_spawn:
		if area != null:
			areas_validas.append(area)

	if areas_validas.is_empty():
		return

	var objetos_do_tipo_configurado: Array[Node3D] = _obter_objetos_do_tipo_configurado()
	if objetos_do_tipo_configurado.is_empty():
		return

	objetos_do_tipo_configurado.shuffle()
	areas_validas.shuffle()

	var posicoes_ocupadas: Array[Vector3] = []
	var indice_area_atual: int = 0

	for objeto in objetos_do_tipo_configurado:
		if objeto == null:
			continue

		if indice_area_atual >= areas_validas.size():
			indice_area_atual = 0
			areas_validas.shuffle()

		var area_sorteada: Area3D = areas_validas[indice_area_atual]
		indice_area_atual += 1

		var posicao_aleatoria: Vector3 = _obter_posicao_aleatoria_valida_na_area(area_sorteada, objeto.global_position.y, posicoes_ocupadas)
		objeto.global_position = posicao_aleatoria
		objeto.visible = true
		posicoes_ocupadas.append(posicao_aleatoria)

	lista_de_objetos = objetos_do_tipo_configurado

func _obter_posicao_aleatoria_dentro_da_area(area: Area3D) -> Vector3:
	var collision_shape: CollisionShape3D = _obter_collision_shape_da_area(area)
	if collision_shape == null or collision_shape.shape == null:
		return area.global_position

	var shape: Shape3D = collision_shape.shape
	var ponto_local_aleatorio: Vector3 = Vector3.ZERO

	if shape is BoxShape3D:
		var box_shape: BoxShape3D = shape as BoxShape3D
		var metade_size: Vector3 = box_shape.size * 0.5
		ponto_local_aleatorio = Vector3(
			gerador_aleatorio.randf_range(-metade_size.x, metade_size.x),
			gerador_aleatorio.randf_range(-metade_size.y, metade_size.y),
			gerador_aleatorio.randf_range(-metade_size.z, metade_size.z)
		)
	elif shape is SphereShape3D:
		var sphere_shape: SphereShape3D = shape as SphereShape3D
		ponto_local_aleatorio = _obter_ponto_aleatorio_na_esfera(sphere_shape.radius)
	elif shape is CylinderShape3D:
		var cylinder_shape: CylinderShape3D = shape as CylinderShape3D
		ponto_local_aleatorio = _obter_ponto_aleatorio_no_cilindro(cylinder_shape.radius, cylinder_shape.height)
	else:
		return area.global_position

	return collision_shape.global_transform * ponto_local_aleatorio

func _obter_posicao_aleatoria_valida_na_area(area: Area3D, altura_y_fixa: float, posicoes_ocupadas: Array[Vector3]) -> Vector3:
	var quantidade_tentativas: int = maxi(tentativas_por_objeto, 1)
	var distancia_minima_ao_quadrado: float = maxf(distancia_minima_entre_objetos, 0.0)
	distancia_minima_ao_quadrado *= distancia_minima_ao_quadrado

	var melhor_posicao: Vector3 = area.global_position
	melhor_posicao.y = altura_y_fixa

	for tentativa in range(quantidade_tentativas):
		var posicao_teste: Vector3 = _obter_posicao_aleatoria_dentro_da_area(area)
		posicao_teste.y = altura_y_fixa

		if distancia_minima_ao_quadrado <= 0.0:
			return posicao_teste

		if _posicao_respeita_distancia_minima(posicao_teste, posicoes_ocupadas, distancia_minima_ao_quadrado):
			return posicao_teste

		if tentativa == 0:
			melhor_posicao = posicao_teste

	return melhor_posicao

func _posicao_respeita_distancia_minima(posicao: Vector3, posicoes_ocupadas: Array[Vector3], distancia_minima_ao_quadrado: float) -> bool:
	for posicao_ocupada in posicoes_ocupadas:
		var delta: Vector3 = posicao - posicao_ocupada
		delta.y = 0.0
		if delta.length_squared() < distancia_minima_ao_quadrado:
			return false

	return true

func _obter_collision_shape_da_area(area: Area3D) -> CollisionShape3D:
	for filho in area.get_children():
		if filho is CollisionShape3D:
			var collision_shape: CollisionShape3D = filho as CollisionShape3D
			if collision_shape.disabled:
				continue
			return collision_shape

	return null

func _obter_ponto_aleatorio_na_esfera(raio: float) -> Vector3:
	while true:
		var ponto: Vector3 = Vector3(
			gerador_aleatorio.randf_range(-raio, raio),
			gerador_aleatorio.randf_range(-raio, raio),
			gerador_aleatorio.randf_range(-raio, raio)
		)
		if ponto.length_squared() <= raio * raio:
			return ponto

	return Vector3.ZERO

func _obter_ponto_aleatorio_no_cilindro(raio: float, altura: float) -> Vector3:
	var angulo: float = gerador_aleatorio.randf_range(0.0, TAU)
	var distancia: float = sqrt(gerador_aleatorio.randf()) * raio
	var y: float = gerador_aleatorio.randf_range(-altura * 0.5, altura * 0.5)
	return Vector3(cos(angulo) * distancia, y, sin(angulo) * distancia)

func _obter_objetos_do_tipo_configurado() -> Array[Node3D]:
	var resultado: Array[Node3D] = []
	for objeto in lista_de_objetos:
		if objeto == null:
			continue

		match tipo_de_objeto:
			TipoDeObjeto.NODE:
				if not (objeto is Area3D):
					resultado.append(objeto)
			TipoDeObjeto.AREA_3D:
				if objeto is Area3D:
					resultado.append(objeto)

	return resultado