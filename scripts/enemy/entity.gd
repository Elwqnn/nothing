extends CharacterBody3D
## Invisible entity that hunts the player based on paranoia level

@export var base_speed: float = 2.0  # Slower than player walk speed (3.0)
@export var chase_speed: float = 3.5  # Still slower than player sprint (5.0)
@export var catch_distance: float = 1.5  # Must be very close to catch

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var catch_area: Area3D = $CatchArea
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var wander_timer: Timer = $WanderTimer
@onready var sound_timer: Timer = $SoundTimer

var player: Node3D = null
var paranoia_meter: Node = null
var current_paranoia: float = 0.0
var target_position: Vector3
var is_active: bool = false


func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Entity: Player not found")
		return

	# Find paranoia meter
	paranoia_meter = player.get_node_or_null("Components/ParanoiaMeter")
	if paranoia_meter:
		paranoia_meter.paranoia_changed.connect(_on_paranoia_changed)
		current_paranoia = paranoia_meter.paranoia_level
	else:
		push_warning("Entity: ParanoiaMeter not found on player")

	# Wait for navigation to be ready
	await get_tree().physics_frame
	is_active = true

	# Start with random wander
	_set_random_target()


func _physics_process(delta: float) -> void:
	if not is_active or not player:
		return

	# Check if we've reached the current target
	if nav_agent.is_navigation_finished():
		_on_target_reached()
		return

	# Get next position from navigation
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Calculate speed based on paranoia
	var current_speed = lerp(base_speed, chase_speed, current_paranoia)

	# Move toward target
	velocity = direction * current_speed
	move_and_slide()


func _on_target_reached() -> void:
	# Choose new target based on paranoia level
	if current_paranoia >= 0.85:
		# Critical paranoia - always chase player
		_set_player_target()
	elif current_paranoia >= 0.5:
		# Medium paranoia - mix of chasing and wandering
		if randf() < current_paranoia:
			_set_player_target()
		else:
			_set_biased_random_target()
	else:
		# Low paranoia - mostly random wander
		if randf() < current_paranoia * 0.5:
			_set_biased_random_target()
		else:
			_set_random_target()


func _set_player_target() -> void:
	# Chase the player directly
	if player:
		target_position = player.global_position
		nav_agent.target_position = target_position


func _set_biased_random_target() -> void:
	# Random position biased toward player
	if not player:
		_set_random_target()
		return

	var player_direction = (player.global_position - global_position).normalized()
	var random_offset = Vector3(
		randf_range(-5.0, 5.0),
		0,
		randf_range(-5.0, 5.0)
	)

	# Bias toward player
	var bias_strength = current_paranoia * 0.7
	var biased_direction = player_direction.lerp(random_offset.normalized(), 1.0 - bias_strength)

	target_position = global_position + biased_direction * randf_range(8.0, 15.0)
	target_position.y = 0  # Keep on ground level
	nav_agent.target_position = target_position


func _set_random_target() -> void:
	# Completely random wander
	var random_offset = Vector3(
		randf_range(-10.0, 10.0),
		0,
		randf_range(-10.0, 10.0)
	)

	target_position = global_position + random_offset
	target_position.y = 0
	nav_agent.target_position = target_position


func _on_wander_timer_timeout() -> void:
	# Periodically update target based on paranoia
	_on_target_reached()

	# Vary timer based on paranoia (more frequent updates when paranoid)
	wander_timer.wait_time = lerp(5.0, 2.0, current_paranoia)


func _on_sound_timer_timeout() -> void:
	# Play sound cue
	_play_growl_sound()

	# Vary sound frequency based on paranoia (more frequent when chasing)
	sound_timer.wait_time = lerp(12.0, 5.0, current_paranoia)


func _play_growl_sound() -> void:
	# TODO: Load actual growl/breath sound asset
	# For now, this will be silent but the 3D positioning is set up
	# When you add sound files, use:
	# audio_player.stream = load("res://assets/audio/sounds/entity_growl.wav")
	# audio_player.pitch_scale = randf_range(0.8, 1.2)
	# audio_player.play()
	pass


func _on_paranoia_changed(level: float) -> void:
	current_paranoia = level


func _on_catch_area_body_entered(body: Node3D) -> void:
	# Check if we caught the player
	if body == player:
		# Check actual distance to ensure we're close enough
		var distance = global_position.distance_to(player.global_position)
		if distance <= catch_distance:
			_catch_player()


func _catch_player() -> void:
	print("Entity: Caught player!")

	# Disable entity
	is_active = false

	# Trigger lose condition
	if Global.game_manager:
		Global.game_manager.trigger_lose("caught by entity")


## Public API
func set_spawn_position(pos: Vector3) -> void:
	global_position = pos


func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return INF
