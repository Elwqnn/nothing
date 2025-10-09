class_name MouseCaptureComponent extends Node

@export var debug: bool = false
@export_category("Mouse Capture Settings")
@export var current_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
@export var mouse_sensitivity: float = 0.002

var _mouse_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = current_mouse_mode

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta.x -= event.screen_relative.x * mouse_sensitivity
		_mouse_delta.y -= event.screen_relative.y * mouse_sensitivity
		
		if debug:
			print("Mouse delta: ", _mouse_delta)

func get_mouse_delta() -> Vector2:
	var delta := _mouse_delta
	_mouse_delta = Vector2.ZERO
	return delta
