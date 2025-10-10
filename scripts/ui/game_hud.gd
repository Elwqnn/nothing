extends Control
## Game HUD - displays gameplay information and prompts

@onready var interaction_prompt: Label = %InteractionPrompt


func _ready() -> void:
	# Find the player's interaction raycast and connect to its signals
	await get_tree().process_frame  # Wait for scene to be fully loaded
	_connect_to_player()


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


func _on_interactable_detected() -> void:
	interaction_prompt.visible = true


func _on_interactable_lost() -> void:
	interaction_prompt.visible = false

