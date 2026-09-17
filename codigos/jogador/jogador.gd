class_name Jogador extends CharacterBody3D

var velocidade_atual: float = 3
const VELOCIDADE_PADRAO: float = 3
const JUMP_VELOCITY = 4.5

@export var camera_pivot: Node3D



func _ready() -> void:
	if camera_pivot == null:
		camera_pivot = get_node_or_null("Camera")
