extends Control
## Game HUD - displays gameplay information and prompts

@onready var interaction_prompt: Label = %InteractionPrompt
@onready var paranoia_bar: ProgressBar = %ParanoiaBar
@onready var paranoia_label: Label = %ParanoiaLabel
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

	# Find and connect to paranoia meter
	var paranoia_meter = player.get_node_or_null("Components/ParanoiaMeter")
	if paranoia_meter:
		paranoia_meter.paranoia_changed.connect(_on_paranoia_changed)
		paranoia_meter.critical_threshold_reached.connect(_on_paranoia_critical)
		paranoia_meter.critical_threshold_cleared.connect(_on_paranoia_cleared)
		# Initialize paranoia display
		_on_paranoia_changed(paranoia_meter.paranoia_level)
	else:
		push_warning("GameHUD: ParanoiaMeter not found on player")


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


func _on_paranoia_changed(level: float) -> void:
	# Update paranoia bar (inverted: 100% = safe, 0% = insane)
	paranoia_bar.value = (1.0 - level) * 100.0

	# Change color based on paranoia level
	if level >= 0.85:
		# Critical - red and flashing
		paranoia_bar.modulate = Color.RED
		paranoia_label.modulate = Color.RED
	elif level >= 0.6:
		# High - orange
		paranoia_bar.modulate = Color.ORANGE
		paranoia_label.modulate = Color.ORANGE
	elif level >= 0.3:
		# Medium - yellow
		paranoia_bar.modulate = Color.YELLOW
		paranoia_label.modulate = Color.WHITE
	else:
		# Low - normal
		paranoia_bar.modulate = Color.WHITE
		paranoia_label.modulate = Color.WHITE


func _on_paranoia_critical() -> void:
	# Make label flash when critical
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(paranoia_label, "modulate:a", 0.3, 0.5)
	tween.tween_property(paranoia_label, "modulate:a", 1.0, 0.5)


func _on_paranoia_cleared() -> void:
	# Stop flashing
	var tween = create_tween()
	tween.tween_property(paranoia_label, "modulate:a", 1.0, 0.2)


func _on_time_updated(game_hour: int, time_string: String, seconds_remaining: float) -> void:
	time_label.text = time_string

	# Flash red when under 60 seconds remaining
	if seconds_remaining <= 60.0 and seconds_remaining > 0.0:
		time_label.modulate = Color.RED
	else:
		time_label.modulate = Color.WHITE
