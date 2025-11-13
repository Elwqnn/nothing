extends Control
## Game Over - Lose Screen

@onready var reason_label: Label = %ReasonLabel


func _ready() -> void:
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Connect to game manager to get lose reason
	if Global.game_manager:
		Global.game_manager.game_lost.connect(_on_game_lost)


func _on_game_lost(reason: String) -> void:
	# Update reason label based on reason
	match reason:
		"Lost all sanity":
			reason_label.text = "You lost your mind."
		"caught by entity":
			reason_label.text = "You were caught."
		_:
			reason_label.text = reason


func _on_restart_button_pressed() -> void:
	# Reset game and restart
	Global.game_manager.reset_game()
	Global.game_manager.change_world_scene("res://scenes/world/maze/maze_generator_3d.tscn", true, true)
	Global.game_manager.change_ui_scene("res://scenes/ui/game_hud.tscn", true)
	# Start game after scenes are loaded
	await get_tree().process_frame
	Global.game_manager.start_game()


func _on_menu_button_pressed() -> void:
	# Return to main menu
	Global.game_manager.reset_game()
	Global.game_manager.change_world_scene("res://scenes/world/playground/playground.tscn", false, true)
	Global.game_manager.change_ui_scene("res://scenes/ui/main_menu.tscn", true)
	Global.audio_manager.play_music("neon_light_buzz", 1.5)
