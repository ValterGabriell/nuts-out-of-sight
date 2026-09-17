class_name Jogador extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var camera_pivot: Node3D

func _ready() -> void:
	if camera_pivot == null:
		camera_pivot = get_node_or_null("Camera")
