extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D 
@export var duracao_animacao: float = 0.3

func _ready() -> void:
	animar_onda()

func animar_onda() -> void:
	if not mesh_instance:
		push_error("MeshInstance3D não foi encontrado!")
		queue_free()
		return

	var mat = mesh_instance.material_override as ShaderMaterial
	if not mat:
		mat = mesh_instance.get_active_material(0) as ShaderMaterial

	if not mat:
		push_error("Nenhum ShaderMaterial encontrado na Mesh!")
		queue_free()
		return

	mat = mat.duplicate() as ShaderMaterial
	mesh_instance.material_override = mat

	var tween = create_tween()
	
	tween.tween_property(mat, "shader_parameter/progresso", 1.0, duracao_animacao)\
		 .from(0.0)\
		 .set_trans(Tween.TRANS_QUAD)\
		 .set_ease(Tween.EASE_OUT)

	tween.tween_callback(queue_free)
