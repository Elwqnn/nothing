class_name MouseCaptureComponent extends Node

@export var debug: bool = false
@export_category("Mouse Capture Settings")
@export var current_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
@export var mouse_sensitivity: float = 0.002

var _mouse_delta: Vector2 = Vector2.ZERO
var _invert_y: bool = false

func _ready() -> void:
	Input.mouse_mode = current_mouse_mode
	
	# Load settings from SettingsManager if available
	if SettingsManager:
		mouse_sensitivity = SettingsManager.get_mouse_sensitivity()
		_invert_y = SettingsManager.get_invert_y_axis()
		SettingsManager.settings_changed.connect(_on_settings_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta.x -= event.screen_relative.x * mouse_sensitivity
		var y_modifier = -1.0 if _invert_y else 1.0
		_mouse_delta.y -= event.screen_relative.y * mouse_sensitivity * y_modifier
		
		if debug:
			print("Mouse delta: ", _mouse_delta)

func get_mouse_delta() -> Vector2:
	var delta := _mouse_delta
	_mouse_delta = Vector2.ZERO
	return delta

func _on_settings_changed(category: String) -> void:
	if category == "gameplay" and SettingsManager:
		mouse_sensitivity = SettingsManager.get_mouse_sensitivity()
		_invert_y = SettingsManager.get_invert_y_axis()
