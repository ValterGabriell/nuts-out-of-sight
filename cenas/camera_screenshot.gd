extends Camera3D

enum NoClipState {
	OFF,
	ON,
}

const TOGGLE_KEY: Key = KEY_C
const MOUSE_SENSITIVITY: float = 0.003
const SPEED_WHEEL_FACTOR: float = 1.2
const MAX_PITCH: float = PI / 2.0 - 0.01

@export var move_speed: float = 8.0
@export var fast_speed_multiplier: float = 3.0

var _state: NoClipState = NoClipState.OFF
var _previous_camera: Camera3D
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		_toggle_no_clip()
		get_viewport().set_input_as_handled()
		return

	if _state == NoClipState.OFF:
		return

	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		rotation.x = clampf(rotation.x - event.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH)
		return

	if event is InputEventMouseButton and event.pressed:
		_adjust_speed_with_wheel(event.button_index)

func _process(delta: float) -> void:
	var horizontal: Vector3 = Vector3(_key_axis(KEY_A, KEY_D), 0.0, _key_axis(KEY_W, KEY_S))
	var vertical: float = _key_axis(KEY_Q, KEY_E)
	var direction: Vector3 = global_transform.basis * horizontal + Vector3.UP * vertical
	var speed: float = move_speed * (fast_speed_multiplier if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	global_position += direction.limit_length(1.0) * speed * delta

func _key_axis(negative_key: Key, positive_key: Key) -> float:
	return float(Input.is_physical_key_pressed(positive_key)) - float(Input.is_physical_key_pressed(negative_key))

func _adjust_speed_with_wheel(button_index: MouseButton) -> void:
	match button_index:
		MOUSE_BUTTON_WHEEL_UP:
			move_speed *= SPEED_WHEEL_FACTOR
		MOUSE_BUTTON_WHEEL_DOWN:
			move_speed /= SPEED_WHEEL_FACTOR

func _toggle_no_clip() -> void:
	match _state:
		NoClipState.OFF:
			_enter_no_clip()
		NoClipState.ON:
			_exit_no_clip()

func _enter_no_clip() -> void:
	_previous_camera = get_viewport().get_camera_3d()
	if _previous_camera != null:
		global_transform = _previous_camera.global_transform
	rotation.z = 0.0

	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_player_movement_enabled(false)
	make_current()
	_state = NoClipState.ON
	set_process(true)

func _exit_no_clip() -> void:
	_state = NoClipState.OFF
	set_process(false)
	Input.mouse_mode = _previous_mouse_mode
	_set_player_movement_enabled(true)
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()

func _set_player_movement_enabled(enabled: bool) -> void:
	var player: Node = get_tree().get_first_node_in_group("Jogador")
	if player == null:
		return

	var movement: Node = player.get_node_or_null("Codigos/Movimentos")
	if movement != null:
		movement.set_process(enabled)
		movement.set_physics_process(enabled)
		movement.set_process_input(enabled)
		movement.set_process_unhandled_input(enabled)

	if not enabled and player is CharacterBody3D:
		player.velocity = Vector3.ZERO
