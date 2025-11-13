extends Control
## Game Over - Win Screen

func _ready() -> void:
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
