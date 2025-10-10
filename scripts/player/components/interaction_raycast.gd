extends RayCast3D
## Interaction raycast for detecting and interacting with objects
## Allows the player to push/kick physics objects

signal interactable_detected
signal interactable_lost

@export var interaction_force: float = 10.0
@export var interaction_range: float = 3.0

var current_object
var is_interactable: bool = false

func _ready() -> void:
	target_position = Vector3(0, 0, -interaction_range)
	enabled = true

func _process(_delta: float) -> void:
	var was_interactable = is_interactable
	
	if is_colliding():
		var object = get_collider()
		# Only consider RigidBody3D objects as interactable
		is_interactable = object is RigidBody3D
		
		if object != current_object:
			current_object = object
			
			# Emit signals based on interactable state change
			if is_interactable and not was_interactable:
				interactable_detected.emit()
			elif not is_interactable and was_interactable:
				interactable_lost.emit()
	else:
		current_object = null
		is_interactable = false
		
		if was_interactable:
			interactable_lost.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()

func interact() -> void:
	if not is_colliding():
		return
	
	var collider = get_collider()
	
	# Check if the object is a RigidBody3D (physics object)
	if collider is RigidBody3D:
		var direction = -global_transform.basis.z
		var impulse = direction * interaction_force
		
		# Apply impulse at the collision point for more realistic physics
		var collision_point = get_collision_point()
		collider.apply_impulse(impulse, collision_point - collider.global_position)
