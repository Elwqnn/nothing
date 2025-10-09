class_name AnimationComponent extends Node
## a modular animation component for UI elements with state-based tweening

signal animation_started(state_name: String)
signal animation_finished(state_name: String)

#region Exports
@export_group("General")
@export var from_center: bool = true
@export var enabled: bool = true

@export_group("Animation States")
@export var hover_state: AnimationState
@export var enter_state: AnimationState

@export_group("Dependencies")
@export var wait_for: AnimationComponent
#endregion

#region Variables
var target: Control
var default_state: AnimationState
var current_tween: Tween
var animation_priority: int = 0  # higher priority = cannot be interrupted

const PRIORITY_NONE = 0
const PRIORITY_ENTER = 10
const PRIORITY_HOVER = 1
#endregion

#region Lifecycle
func _ready() -> void:
	target = get_parent() as Control
	if not _validate_setup():
		return
	call_deferred("_initialize")

func _exit_tree() -> void:
	_cleanup_tween()
#endregion

#region Setup
func _validate_setup() -> bool:
	if not target:
		push_error("AnimationComponent must be a child of a Control node")
		queue_free()
		return false
	return true

func _initialize() -> void:
	_capture_default_state()
	_connect_signals()
	
	if enter_state and enter_state.enabled:
		await _play_enter_animation()
	
	animation_finished.emit("ready")

func _capture_default_state() -> void:
	default_state = AnimationState.new()
	default_state.enabled = true
	default_state.scale = target.scale
	default_state.position = target.position
	default_state.rotation = target.rotation
	default_state.size = target.size
	default_state.modulate = target.self_modulate
	
	if from_center:
		target.pivot_offset = target.size / 2

func _connect_signals() -> void:
	if hover_state and hover_state.enabled:
		target.mouse_entered.connect(_on_mouse_entered)
		target.mouse_exited.connect(_on_mouse_exited)
	
	if wait_for:
		wait_for.animation_finished.connect(_on_dependency_finished)
#endregion

#region Signal Handlers
func _on_mouse_entered() -> void:
	if not enabled:
		return
	play_state(hover_state, PRIORITY_HOVER)

func _on_mouse_exited() -> void:
	if not enabled:
		return
	var return_state = _create_return_to_default_state(hover_state)
	play_state(return_state, PRIORITY_HOVER)

func _on_dependency_finished(state_name: String) -> void:
	if state_name == "enter" and enter_state:
		var return_state = _create_return_to_default_state(enter_state)
		play_state(return_state, PRIORITY_ENTER)
#endregion

#region Animation Control
func play_state(state: AnimationState, priority: int = PRIORITY_NONE) -> void:
	if not state or not enabled:
		return
	
	if current_tween and current_tween.is_valid() and animation_priority > priority:
		await current_tween.finished
	elif current_tween and current_tween.is_valid():
		current_tween.kill()
	
	animation_priority = priority
	_create_tween(state)

func _create_return_to_default_state(from_state: AnimationState) -> AnimationState:
	var return_state = AnimationState.new()
	return_state.enabled = true
	
	return_state.animate_scale = from_state.animate_scale
	return_state.animate_position = from_state.animate_position
	return_state.animate_rotation = from_state.animate_rotation
	return_state.animate_size = from_state.animate_size
	return_state.animate_modulate = from_state.animate_modulate
	
	return_state.scale = default_state.scale
	return_state.position = default_state.position
	return_state.rotation = default_state.rotation
	return_state.size = default_state.size
	return_state.modulate = default_state.modulate
	
	return_state.duration = from_state.duration
	return_state.delay = 0.0
	return_state.parallel = from_state.parallel
	return_state.transition = from_state.transition
	return_state.easing = from_state.easing
	
	return return_state

func _play_enter_animation() -> void:
	if not enter_state:
		return
	
	_apply_state_immediately(enter_state)
	
	if not wait_for:
		var return_state = _create_return_to_default_state(enter_state)
		play_state(return_state, PRIORITY_ENTER)
		await animation_finished
	else:
		animation_priority = PRIORITY_ENTER

func _create_tween(state: AnimationState) -> void:
	if not is_inside_tree():
		return
	
	current_tween = get_tree().create_tween()
	current_tween.set_parallel(state.parallel)
	
	animation_started.emit(state.resource_name if state.resource_name else "unnamed")
	
	if state.delay > 0:
		current_tween.tween_interval(state.delay)
	
	var chain = current_tween.chain() if state.delay > 0 else current_tween
	
	if state.animate_scale:
		chain.tween_property(target, "scale", state.scale, state.duration) \
			.set_trans(state.transition).set_ease(state.easing)
	
	if state.animate_position:
		var target_pos = default_state.position + state.position
		chain.tween_property(target, "position", target_pos, state.duration) \
			.set_trans(state.transition).set_ease(state.easing)
	
	if state.animate_rotation:
		var target_rot = default_state.rotation + deg_to_rad(state.rotation)
		chain.tween_property(target, "rotation", target_rot, state.duration) \
			.set_trans(state.transition).set_ease(state.easing)
	
	if state.animate_size:
		var target_size = default_state.size + state.size
		chain.tween_property(target, "size", target_size, state.duration) \
			.set_trans(state.transition).set_ease(state.easing)
	
	if state.animate_modulate:
		chain.tween_property(target, "self_modulate", state.modulate, state.duration) \
			.set_trans(state.transition).set_ease(state.easing)
	
	await chain.finished
	animation_priority = PRIORITY_NONE
	animation_finished.emit(state.resource_name if state.resource_name else "unnamed")

func _apply_state_immediately(state: AnimationState) -> void:
	if state.animate_scale:
		target.scale = state.scale
	if state.animate_position:
		target.position = default_state.position + state.position
	if state.animate_rotation:
		target.rotation = default_state.rotation + deg_to_rad(state.rotation)
	if state.animate_size:
		target.size = default_state.size + state.size
	if state.animate_modulate:
		target.self_modulate = state.modulate

func _cleanup_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
#endregion

#region Public API
func stop_animations() -> void:
	_cleanup_tween()
	animation_priority = PRIORITY_NONE

func reset_to_default() -> void:
	stop_animations()
	if default_state:
		_apply_state_immediately(default_state)

func animate_to_default(from_state: AnimationState, priority: int = PRIORITY_NONE) -> void:
	var return_state = _create_return_to_default_state(from_state)
	play_state(return_state, priority)
#endregion
