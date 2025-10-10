extends RigidBody3D
## Physics ball with reduced friction and gravity
## Bouncy sphere that behaves with custom physics properties

func _ready() -> void:
	# Create physics material with low friction
	var physics_mat = PhysicsMaterial.new()
	physics_mat.friction = 0.1  # Very low friction
	physics_mat.bounce = 0.7    # Bouncy
	physics_material_override = physics_mat
	
	# Gravity is already reduced via gravity_scale in the scene (0.3)
	# You can adjust it here if needed:
	# gravity_scale = 0.3

func _process(_delta: float) -> void:
	# Optional: Add visual feedback or effects here
	pass

## Apply an impulse to the ball
func kick(impulse: Vector3) -> void:
	apply_central_impulse(impulse)

## Reset the ball's position and velocity
func reset_position(new_pos: Vector3) -> void:
	global_position = new_pos
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

