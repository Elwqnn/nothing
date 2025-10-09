class_name TransitionManager extends CanvasLayer
## handles screen transitions between scenes

signal transition_started
signal fade_out_finished
signal fade_in_finished
signal transition_finished

@export var fade_duration: float = 0.5
@export var fade_color: Color = Color.BLACK

var _overlay: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	_overlay = ColorRect.new()
	_overlay.color = fade_color
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	add_child(_overlay)
	
	layer = 100


func transition(duration: float = -1.0) -> void:
	if _is_transitioning:
		return
	
	var fade_time = duration if duration > 0 else fade_duration
	_is_transitioning = true
	transition_started.emit()
	
	await fade_out(fade_time)
	await fade_in(fade_time)
	
	_is_transitioning = false
	transition_finished.emit()


func fade_out(duration: float = -1.0) -> void:
	var fade_time = duration if duration > 0 else fade_duration
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, fade_time)
	await tween.finished
	
	fade_out_finished.emit()


func fade_in(duration: float = -1.0) -> void:
	var fade_time = duration if duration > 0 else fade_duration
	
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, fade_time)
	await tween.finished
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_in_finished.emit()


func show_overlay() -> void:
	_overlay.modulate.a = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func hide_overlay() -> void:
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
