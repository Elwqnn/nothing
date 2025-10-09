extends Control

const PLAYGROUND_SCENE: String = "res://scenes/world/playground/playground.tscn"
const GAME_HUD_SCENE: String = "res://scenes/ui/game_hud.tscn"

@onready var new_game_button: Button = %NewGame
@onready var continue_button: Button = %Continue
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	await Global.transition_manager.fade_out()

	Global.game_manager.change_ui_scene(GAME_HUD_SCENE)
	await Global.game_manager.change_world_scene(PLAYGROUND_SCENE, true, true, false, false)

	await Global.transition_manager.fade_in()


func _on_quit_pressed() -> void:
	get_tree().quit()
