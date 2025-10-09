class_name PlayerController extends CharacterBody3D

@export var debug: bool = false
@export_category("References")
@export var camera: CameraController
@export var camera_effects: CameraEffects
@export var state_chart: StateChart
@export var interaction_raycast: RayCast3D
@export_category("Movement Settings")
@export_range(1, 30, 0.5) var acceleration: float = 15.0
@export_range(1, 30, 0.5) var deceleration: float = 15.0
@export_range(0, 20, 0.1) var speed: float = 3.0
@export_range(0, 20, 0.1) var sprint_speed: float = 5.0

var _input_dir: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0


func _ready() -> void:
	_current_speed = speed

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * _current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * _current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	
	move_and_slide()

func sprint() -> void:
	_current_speed = sprint_speed

func walk() -> void:
	_current_speed = speed
