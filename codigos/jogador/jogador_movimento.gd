class_name JogadorMovimento extends Node3D

@export var jogador: Jogador

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not jogador.is_on_floor():
		jogador.velocity += jogador.get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and jogador.is_on_floor():
		jogador.velocity.y = Jogador.JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var reference_node: Node3D = jogador.camera_pivot if jogador.camera_pivot != null else jogador
	var basis := reference_node.global_transform.basis
	var camera_forward := basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var direction := (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
	if direction:
		jogador.velocity.x = direction.x * Jogador.SPEED
		jogador.velocity.z = direction.z * Jogador.SPEED
	else:
		jogador.velocity.x = move_toward(jogador.velocity.x, 0, Jogador.SPEED)
		jogador.velocity.z = move_toward(jogador.velocity.z, 0, Jogador.SPEED)

	jogador.move_and_slide()
