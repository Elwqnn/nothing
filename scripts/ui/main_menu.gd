extends Control

const PLAYGROUND_SCENE: String = "res://scenes/world/playground/playground.tscn"
const LEVEL1_SCENE: String = "res://scenes/world/level1/level1.tscn"
const MAZE_SCENE: String = "res://scenes/world/maze/maze_generator_3d.tscn"
const GAME_HUD_SCENE: String = "res://scenes/ui/game_hud.tscn"
const SETTINGS_SCENE: String = "res://scenes/ui/settings_menu.tscn"

@onready var new_game_button: Button = %NewGame
@onready var continue_button: Button = %Continue
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if Global.audio_manager:
		Global.audio_manager.play_music("neon_light_buzz", 1.5, true)


func _on_new_game_pressed() -> void:
	await Global.transition_manager.fade_out()

	# Load maze level and game HUD
	Global.game_manager.change_ui_scene(GAME_HUD_SCENE)
	await Global.game_manager.change_world_scene(MAZE_SCENE, false, true, false, false)

	# Start the game timer and systems
	Global.game_manager.start_game()

	await Global.transition_manager.fade_in()


func _on_settings_pressed() -> void:
	var settings_menu_scene = load(SETTINGS_SCENE)
	if settings_menu_scene:
		var settings_menu = settings_menu_scene.instantiate()
		settings_menu.back_pressed.connect(_on_settings_back)
		get_parent().add_child(settings_menu)
		visible = false


func _on_settings_back() -> void:
	visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
