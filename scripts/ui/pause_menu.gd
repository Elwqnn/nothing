extends Control
## Pause menu - shown when player pauses the game with ESC

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton

var is_paused: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	is_paused = !is_paused
	
	if is_paused:
		pause_game()
	else:
		resume_game()


func pause_game() -> void:
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Focus the resume button
	if resume_button:
		resume_button.grab_focus()


func resume_game() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	resume_game()


func _on_quit_pressed() -> void:
	# Unpause and cleanup
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Transition to main menu
	if Global.transition_manager:
		await Global.transition_manager.fade_out()
	
	# Stop current music
	if Global.audio_manager:
		await Global.audio_manager.stop_music(0.5)
	
	# Clear world scene
	if Global.game_manager and Global.game_manager.current_world_scene:
		Global.game_manager.current_world_scene.queue_free()
		Global.game_manager.current_world_scene = null
	
	# Clear player
	if Global.game_manager and Global.game_manager.current_player:
		Global.game_manager.current_player.queue_free()
		Global.game_manager.current_player = null
	
	# Change to main menu (this will destroy the current UI including this pause menu)
	if Global.game_manager:
		await Global.game_manager.change_ui_scene(MAIN_MENU_SCENE)
	
	# Start main menu music and fade in
	if Global.audio_manager:
		Global.audio_manager.play_music("neon_light_buzz", 1.5, true)
	
	if Global.transition_manager:
		await Global.transition_manager.fade_in()

