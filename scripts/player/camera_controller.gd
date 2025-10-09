class_name CameraController extends Node3D

@export var debug: bool = false
@export_category("References")
@export var player_controller: PlayerController
@export var component_mouse_capture: MouseCaptureComponent
@export_category("Camera Settings")
@export_group("Camera Tilt")
@export_range(-90, -60) var tilt_lower_limit: int = -90
@export_range(60, 90) var tilt_upper_limit: int = 90

var _rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	# initialize rotation from player's current rotation
	if player_controller:
		_rotation.y = player_controller.rotation.y
		_rotation.x = rotation.x

func _process(_delta: float) -> void:
	var mouse_delta := component_mouse_capture.get_mouse_delta()
	
	# only update if there's actual mouse input
	if mouse_delta != Vector2.ZERO:
		_rotation.x += mouse_delta.y
		_rotation.y += mouse_delta.x
		_rotation.x = clamp(_rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))
		
		# update camera tilt (pitch)
		rotation.x = _rotation.x
		
		# update player rotation (yaw)
		player_controller.rotation.y = _rotation.y
