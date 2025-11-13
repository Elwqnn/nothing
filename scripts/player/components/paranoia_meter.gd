extends Node
class_name ParanoiaMeter

## Tracks player's paranoia level based on sprint and mouse movement
## Paranoia affects VHS shader intensity and entity behavior

signal paranoia_changed(level: float)
signal critical_threshold_reached()
signal critical_threshold_cleared()

## Current paranoia level (0.0 to 1.0)
@export var paranoia_level: float = 0.0

## Increase rates
@export var sprint_increase_rate: float = 0.10  # 10% per second while sprinting
@export var mouse_movement_sensitivity: float = 0.15  # How much fast mouse movement affects paranoia

## Decrease rates
@export var idle_decrease_rate: float = 0.05  # 5% per second while standing still
@export var walking_decrease_rate: float = 0.02  # 2% per second while walking

## Critical threshold settings
@export var critical_threshold: float = 0.85  # 85% paranoia
@export var critical_duration_limit: float = 20.0  # Seconds before losing

## Internal state
var _is_sprinting: bool = false
var _is_moving: bool = false
var _critical_timer: float = 0.0
var _in_critical_state: bool = false
var _player_controller: CharacterBody3D = null
var _camera_controller: Node = null
var _last_mouse_delta: Vector2 = Vector2.ZERO

## VHS shader integration
var _vhs_post_process: Node = null
var _shader_tween: Tween = null


func _ready() -> void:
	# Get references to player components
	_player_controller = get_node("../..")
	_camera_controller = _player_controller.get_node_or_null("CameraController")

	# Get VHS post-process from Global
	if Global.vhs_post_process:
		_vhs_post_process = Global.vhs_post_process

	# Connect to player state changes
	_connect_to_player_states()


func _process(delta: float) -> void:
	# Track mouse movement speed
	if _camera_controller:
		var mouse_capture = _camera_controller.get_node_or_null("MouseCaptureComponent")
		if mouse_capture and mouse_capture.has_method("get_mouse_delta"):
			var mouse_delta = mouse_capture.get_mouse_delta()
			var mouse_speed = mouse_delta.length()

			# Fast mouse movement increases paranoia
			if mouse_speed > 10.0:  # Threshold for "fast" movement
				var increase = (mouse_speed / 100.0) * mouse_movement_sensitivity * delta
				_increase_paranoia(increase)

	# Update paranoia based on current state
	if _is_sprinting:
		_increase_paranoia(sprint_increase_rate * delta)
	elif not _is_moving:
		# Standing still - decrease faster
		_decrease_paranoia(idle_decrease_rate * delta)
	else:
		# Walking - decrease slower
		_decrease_paranoia(walking_decrease_rate * delta)

	# Check critical threshold
	_check_critical_threshold(delta)

	# Update VHS shader effects
	_update_vhs_effects()


func _connect_to_player_states() -> void:
	# Find state machine and connect to states
	var state_chart = _player_controller.get_node_or_null("StateChart")
	if not state_chart:
		push_warning("ParanoiaMeter: Could not find StateChart on player")
		return

	# Connect to sprinting state
	var sprinting_state = state_chart.get_node_or_null("Root/Movement/Moving/Sprinting")
	if sprinting_state:
		sprinting_state.state_entered.connect(_on_sprinting_entered)
		sprinting_state.state_exited.connect(_on_sprinting_exited)

	# Connect to idle state
	var idle_state = state_chart.get_node_or_null("Root/Movement/Idle")
	if idle_state:
		idle_state.state_entered.connect(_on_idle_entered)
		idle_state.state_exited.connect(_on_idle_exited)

	# Connect to moving states
	var walking_state = state_chart.get_node_or_null("Root/Movement/Moving/Walking")
	if walking_state:
		walking_state.state_entered.connect(_on_walking_entered)


func _on_sprinting_entered() -> void:
	_is_sprinting = true
	_is_moving = true


func _on_sprinting_exited() -> void:
	_is_sprinting = false


func _on_idle_entered() -> void:
	_is_moving = false


func _on_idle_exited() -> void:
	_is_moving = true


func _on_walking_entered() -> void:
	_is_moving = true
	_is_sprinting = false


func _increase_paranoia(amount: float) -> void:
	var old_level = paranoia_level
	paranoia_level = clamp(paranoia_level + amount, 0.0, 1.0)

	if paranoia_level != old_level:
		paranoia_changed.emit(paranoia_level)


func _decrease_paranoia(amount: float) -> void:
	var old_level = paranoia_level
	paranoia_level = clamp(paranoia_level - amount, 0.0, 1.0)

	if paranoia_level != old_level:
		paranoia_changed.emit(paranoia_level)


func _check_critical_threshold(delta: float) -> void:
	if paranoia_level >= critical_threshold:
		_critical_timer += delta

		if not _in_critical_state:
			_in_critical_state = true
			critical_threshold_reached.emit()

		# Check if we've been in critical state too long
		if _critical_timer >= critical_duration_limit:
			# Trigger lose condition via GameManager
			if Global.game_manager:
				Global.game_manager.trigger_lose("Succumbed to paranoia")
	else:
		if _in_critical_state:
			_in_critical_state = false
			critical_threshold_cleared.emit()
		_critical_timer = 0.0


func _update_vhs_effects() -> void:
	if not _vhs_post_process:
		return

	# Map paranoia level to shader intensities
	# Use exponential curves for more dramatic effect at high paranoia
	var paranoia_squared = paranoia_level * paranoia_level
	var paranoia_cubed = paranoia_squared * paranoia_level

	# Cancel existing tween if any
	if _shader_tween and _shader_tween.is_running():
		_shader_tween.kill()

	# Create smooth transitions for shader parameters
	_shader_tween = create_tween()
	_shader_tween.set_parallel(true)
	_shader_tween.set_trans(Tween.TRANS_CUBIC)
	_shader_tween.set_ease(Tween.EASE_OUT)

	# Aberration: 2.0 to 5.0 (exponential)
	var aberration = lerp(2.0, 5.0, paranoia_squared)
	_vhs_post_process.set_aberration(aberration)

	# Noise: 0.03 to 0.25 (exponential)
	var noise = lerp(0.03, 0.25, paranoia_squared)
	_vhs_post_process.set_noise(noise)

	# Distortion: 0.05 to 0.9 (cubic for extreme effect at high paranoia)
	var distortion = lerp(0.05, 0.9, paranoia_cubed)
	_vhs_post_process.set_distortion(distortion)

	# Flicker: 0.005 to 0.08 (exponential)
	var flicker = lerp(0.005, 0.08, paranoia_squared)
	_vhs_post_process.set_flicker(flicker)

	# Ghost: 0.08 to 0.28 (exponential)
	var ghost = lerp(0.08, 0.28, paranoia_squared)
	_vhs_post_process.set_ghost(ghost)

	# Vignette: subtle increase for darkness
	var vignette = lerp(0.78, 0.95, paranoia_level)
	_vhs_post_process.set_vignette(vignette)


## Public API for external control
func get_paranoia_level() -> float:
	return paranoia_level


func is_in_critical_state() -> bool:
	return _in_critical_state


func get_critical_time_remaining() -> float:
	return max(0.0, critical_duration_limit - _critical_timer)


func reset() -> void:
	paranoia_level = 0.0
	_critical_timer = 0.0
	_in_critical_state = false
	_is_sprinting = false
	_is_moving = false
	paranoia_changed.emit(paranoia_level)
