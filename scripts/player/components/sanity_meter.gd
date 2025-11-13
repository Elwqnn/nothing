extends Node
class_name SanityMeter

## Tracks player's sanity level based on sprint and mouse movement
## Low sanity affects VHS shader intensity and entity behavior

signal sanity_changed(level: float)
signal critical_threshold_reached()
signal critical_threshold_cleared()

## Current sanity level (0.0 to 1.0, where 1.0 is fully sane)
@export var sanity_level: float = 1.0

## Decrease rates (things that drain sanity)
@export var sprint_decrease_rate: float = 0.10  # 10% per second while sprinting
@export var mouse_movement_sensitivity: float = 0.15  # How much fast mouse movement affects sanity

## Increase rates (things that restore sanity)
@export var idle_increase_rate: float = 0.05  # 5% per second while standing still
@export var walking_increase_rate: float = 0.02  # 2% per second while walking

## Critical threshold settings
@export var critical_threshold: float = 0.15  # 15% sanity (very low)
@export var critical_duration_limit: float = 20.0  # Seconds before losing

## Internal state
var _is_sprinting: bool = false
var _is_moving: bool = false
var _critical_timer: float = 0.0
var _in_critical_state: bool = false
var _player_controller: CharacterBody3D = null
var _camera_controller: Node = null

## VHS shader integration
var _vhs_post_process: Node = null


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

			# Fast mouse movement decreases sanity
			if mouse_speed > 10.0:  # Threshold for "fast" movement
				var decrease = (mouse_speed / 100.0) * mouse_movement_sensitivity * delta
				_decrease_sanity(decrease)

	# Update sanity based on current state
	if _is_sprinting:
		_decrease_sanity(sprint_decrease_rate * delta)
	elif not _is_moving:
		# Standing still - increase faster
		_increase_sanity(idle_increase_rate * delta)
	else:
		# Walking - increase slower
		_increase_sanity(walking_increase_rate * delta)

	# Check critical threshold
	_check_critical_threshold(delta)

	# Update VHS shader effects
	_update_vhs_effects()


func _connect_to_player_states() -> void:
	# Find state machine and connect to states
	var state_chart = _player_controller.get_node_or_null("StateChart")
	if not state_chart:
		push_warning("SanityMeter: Could not find StateChart on player")
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


func _decrease_sanity(amount: float) -> void:
	var old_level = sanity_level
	sanity_level = clamp(sanity_level - amount, 0.0, 1.0)

	if sanity_level != old_level:
		sanity_changed.emit(sanity_level)


func _increase_sanity(amount: float) -> void:
	var old_level = sanity_level
	sanity_level = clamp(sanity_level + amount, 0.0, 1.0)

	if sanity_level != old_level:
		sanity_changed.emit(sanity_level)


func _check_critical_threshold(delta: float) -> void:
	if sanity_level <= critical_threshold:
		_critical_timer += delta

		if not _in_critical_state:
			_in_critical_state = true
			critical_threshold_reached.emit()

		# Check if we've been in critical state too long
		if _critical_timer >= critical_duration_limit:
			# Trigger lose condition via GameManager
			if Global.game_manager:
				Global.game_manager.trigger_lose("Lost all sanity")
	else:
		if _in_critical_state:
			_in_critical_state = false
			critical_threshold_cleared.emit()
		_critical_timer = 0.0


func _update_vhs_effects() -> void:
	if not _vhs_post_process:
		return

	# Map sanity level to shader intensities (inverted - low sanity = high effects)
	# Use exponential curves for more dramatic effect at low sanity
	var insanity_level = 1.0 - sanity_level  # Invert: 0 sanity = 1.0 insanity
	var insanity_squared = insanity_level * insanity_level
	var insanity_cubed = insanity_squared * insanity_level

	# Directly set shader parameters (no tween - updates every frame)
	# Aberration: 2.0 to 5.0 (exponential)
	var aberration = lerp(2.0, 5.0, insanity_squared)
	_vhs_post_process.set_aberration(aberration)

	# Noise: 0.03 to 0.25 (exponential)
	var noise = lerp(0.03, 0.25, insanity_squared)
	_vhs_post_process.set_noise(noise)

	# Distortion: 0.05 to 0.9 (cubic for extreme effect at low sanity)
	var distortion = lerp(0.05, 0.9, insanity_cubed)
	_vhs_post_process.set_distortion(distortion)

	# Flicker: 0.005 to 0.08 (exponential)
	var flicker = lerp(0.005, 0.08, insanity_squared)
	_vhs_post_process.set_flicker(flicker)

	# Ghost: 0.08 to 0.28 (exponential)
	var ghost = lerp(0.08, 0.28, insanity_squared)
	_vhs_post_process.set_ghost(ghost)

	# Vignette: subtle increase for darkness
	var vignette = lerp(0.78, 0.95, insanity_level)
	_vhs_post_process.set_vignette(vignette)


## Public API for external control
func get_sanity_level() -> float:
	return sanity_level


func is_in_critical_state() -> bool:
	return _in_critical_state


func get_critical_time_remaining() -> float:
	return max(0.0, critical_duration_limit - _critical_timer)


func reset() -> void:
	sanity_level = 1.0
	_critical_timer = 0.0
	_in_critical_state = false
	_is_sprinting = false
	_is_moving = false
	sanity_changed.emit(sanity_level)
