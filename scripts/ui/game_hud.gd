extends Control
## Game HUD - displays gameplay information and prompts

@onready var interaction_prompt: Label = %InteractionPrompt
@onready var sanity_bar: ProgressBar = %SanityBar
@onready var sanity_label: Label = %SanityLabel
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	# Find the player's interaction raycast and connect to its signals
	await get_tree().process_frame  # Wait for scene to be fully loaded
	_connect_to_player()
	_connect_to_game_manager()


func _connect_to_player() -> void:
	# Find the player in the scene tree
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("GameHUD: Player not found in scene")
		return

	# Find the interaction raycast
	var interaction_raycast = player.get_node_or_null("CameraController/Camera3D/InteractionRaycast")
	if not interaction_raycast:
		push_warning("GameHUD: InteractionRaycast not found on player")
		return

	# Connect to the signals
	interaction_raycast.interactable_detected.connect(_on_interactable_detected)
	interaction_raycast.interactable_lost.connect(_on_interactable_lost)

	# Find and connect to sanity meter
	var sanity_meter = player.get_node_or_null("Components/SanityMeter")
	if sanity_meter:
		sanity_meter.sanity_changed.connect(_on_sanity_changed)
		sanity_meter.critical_threshold_reached.connect(_on_sanity_critical)
		sanity_meter.critical_threshold_cleared.connect(_on_sanity_cleared)
		# Initialize sanity display
		_on_sanity_changed(sanity_meter.sanity_level)
	else:
		push_warning("GameHUD: SanityMeter not found on player")


func _connect_to_game_manager() -> void:
	# Connect to game manager time updates
	if Global.game_manager:
		Global.game_manager.time_updated.connect(_on_time_updated)
	else:
		push_warning("GameHUD: GameManager not found in Global")


func _on_interactable_detected() -> void:
	interaction_prompt.visible = true


func _on_interactable_lost() -> void:
	interaction_prompt.visible = false


func _on_sanity_changed(level: float) -> void:
	# Update sanity bar (100% = fully sane, 0% = insane)
	sanity_bar.value = level * 100.0

	# Change color based on sanity level
	if level <= 0.15:
		# Critical - red and flashing
		sanity_bar.modulate = Color.RED
		sanity_label.modulate = Color.RED
	elif level <= 0.4:
		# Low - orange
		sanity_bar.modulate = Color.ORANGE
		sanity_label.modulate = Color.ORANGE
	elif level <= 0.7:
		# Medium - yellow
		sanity_bar.modulate = Color.YELLOW
		sanity_label.modulate = Color.WHITE
	else:
		# High - normal
		sanity_bar.modulate = Color.WHITE
		sanity_label.modulate = Color.WHITE


func _on_sanity_critical() -> void:
	# Make label flash when critical
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sanity_label, "modulate:a", 0.3, 0.5)
	tween.tween_property(sanity_label, "modulate:a", 1.0, 0.5)


func _on_sanity_cleared() -> void:
	# Stop flashing
	var tween = create_tween()
	tween.tween_property(sanity_label, "modulate:a", 1.0, 0.2)


func _on_time_updated(_game_hour: int, time_string: String, seconds_remaining: float) -> void:
	time_label.text = time_string

	# Flash red when under 60 seconds remaining
	if seconds_remaining <= 60.0 and seconds_remaining > 0.0:
		time_label.modulate = Color.RED
	else:
		time_label.modulate = Color.WHITE
