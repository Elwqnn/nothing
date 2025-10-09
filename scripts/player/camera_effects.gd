class_name CameraEffects extends Camera3D

@export var debug: bool = false

@export_category("References")
@export var player: PlayerController

@export_category("Effects")
@export var enable_tilt: bool = true
@export var enable_screen_shake: bool = true
@export var enable_headbob: bool = true
@export var enable_dynamic_fov: bool = true

@export_category("Effects Settings")
@export_group("Tilt")
@export var run_pitch: float = 0.1
@export var run_roll: float = 0.1
@export var max_pitch: float = 0.75
@export var max_roll: float = 2
@export_group("Headbob")
@export_range(0.0, 0.1, 0.001) var bob_pitch: float = 0.05
@export_range(0.0, 0.1, 0.001) var bob_roll: float = 0.025
@export_range(0.0, 0.4, 0.001) var bob_up: float = 0.005
@export_range(3.0, 8.0, 0.1) var bob_frequency: float = 6.0
@export_range(0.1, 1.0, 0.01) var movement_speed_threshold: float = 0.1
@export_group("Dynamic FOV")
@export var fov_multiplier: float = 1.15
@export var fov_lerp_speed: float = 8.0

# screen shake
var _screen_shake_tween: Tween
const MIN_SCREEN_SHAKE: float = 0.05
const MAX_SCREEN_SHAKE: float = 0.5

# headbob
var _step_timer: float = 0.0

# dynamic FOV
var _initial_fov: float = 0.0
var _target_fov: float = 0.0

func _ready() -> void:
	_initial_fov = fov
	_target_fov = fov

func _process(delta: float) -> void:
	calculate_view_offset(delta)

func calculate_view_offset(delta: float) -> void:
	if not player:
		return
	
	var velocity := player.velocity
	var speed := Vector2(velocity.x, velocity.z).length()
	
	# headbob timing
	if speed > movement_speed_threshold and player.is_on_floor():
		_step_timer += delta * (speed / bob_frequency)
		_step_timer = fmod(_step_timer, 1.0)
	else:
		_step_timer = 1.0
	
	var bob_sin := sin(_step_timer * TAU) * 0.5
	var angles := Vector3.ZERO
	var offset := Vector3.ZERO
	
	# camera tilt
	if enable_tilt:
		var forward := global_transform.basis.z
		var right := global_transform.basis.x
		
		var forward_dot := velocity.dot(forward)
		var forward_tilt := clampf(forward_dot * deg_to_rad(run_pitch), deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
		angles.x += forward_tilt
		
		var right_dot := velocity.dot(right)
		var side_tilt := clampf(right_dot * deg_to_rad(run_roll), deg_to_rad(-max_roll), deg_to_rad(max_roll))
		angles.z -= side_tilt
	
	# headbob
	if enable_headbob:
		var pitch_delta := bob_sin * deg_to_rad(bob_pitch) * speed
		angles.x -= pitch_delta
		
		var roll_delta := bob_sin * deg_to_rad(bob_roll) * speed
		angles.z -= roll_delta
		
		var bob_height := bob_sin * speed * bob_up
		offset.y += bob_height
	
	# dynamic FOV based on movement speed
	if enable_dynamic_fov:
		var speed_ratio := clampf(speed / player.sprint_speed, 0.0, 1.0)
		_target_fov = lerpf(_initial_fov, _initial_fov * fov_multiplier, speed_ratio)
		fov = lerpf(fov, _target_fov, fov_lerp_speed * delta)
	
	position = offset
	rotation = angles

func add_screen_shake(amount: float, seconds: float) -> void:
	if not enable_screen_shake:
		return
	
	if _screen_shake_tween:
		_screen_shake_tween.kill()
	
	var clamped_amount := clampf(amount, MIN_SCREEN_SHAKE, MAX_SCREEN_SHAKE)
	_screen_shake_tween = create_tween()
	_screen_shake_tween.tween_method(_apply_screen_shake.bind(clamped_amount), 1.0, 0.0, seconds).set_ease(Tween.EASE_OUT)

func _apply_screen_shake(intensity: float, max_amount: float) -> void:
	var current_shake := max_amount * intensity
	h_offset = randf_range(-current_shake, current_shake)
	v_offset = randf_range(-current_shake, current_shake)
