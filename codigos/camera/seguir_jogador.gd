extends Node3D

@export var jogador: Node3D
@export var camera_pivot: Node3D
@export var velocidade: float = 5.0

var _initial_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	if camera_pivot == null:
		camera_pivot = get_parent_node_3d()

	if jogador != null and camera_pivot != null:
		_initial_offset = camera_pivot.global_position - jogador.global_position

func _physics_process(delta: float) -> void:
	if jogador == null or camera_pivot == null:
		return

	var target_position := jogador.global_position + _initial_offset
	camera_pivot.global_position = camera_pivot.global_position.lerp(target_position, velocidade * delta)