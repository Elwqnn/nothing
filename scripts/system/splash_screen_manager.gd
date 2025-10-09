extends Control
## manages the splash screen sequence

@export var in_time: float = 0.3
@export var fade_in_time: float = 0.5
@export var pause_time: float = 0.8
@export var fade_out_time: float = 0.5
@export var out_time: float = 0.3
@export var splash_screen_container: Control
@export var skip_cooldown: float = 0.3

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

var splash_screens: Array[Control]
var is_transitioning: bool = false
var current_screen_index: int = 0
var current_tween: Tween
var skip_requested: bool = false
var can_skip: bool = true


func _ready() -> void:
	_get_screens()
	_fade()

func _input(event: InputEvent) -> void:
	if not is_transitioning and can_skip and event.is_pressed():
		_skip_to_next()
		get_viewport().set_input_as_handled()


func _get_screens() -> void:
	splash_screens.assign(splash_screen_container.get_children())
	for screen in splash_screens:
		if screen is Control:
			screen.modulate.a = 0.0


func _fade() -> void:
	while current_screen_index < splash_screens.size():
		skip_requested = false
		var screen = splash_screens[current_screen_index]
		
		current_tween = create_tween()
		current_tween.tween_interval(in_time)
		current_tween.tween_property(screen, "modulate:a", 1.0, fade_in_time)
		current_tween.tween_interval(pause_time)
		current_tween.tween_property(screen, "modulate:a", 0.0, fade_out_time)
		current_tween.tween_interval(out_time)
		
		while current_tween.is_running() and not skip_requested:
			await get_tree().process_frame
		
		if skip_requested and current_tween.is_running():
			current_tween.kill()
			screen.modulate.a = 0.0
		
		current_screen_index += 1
	
	_change_scene()


func _skip_to_next() -> void:
	if not can_skip:
		return
	
	skip_requested = true
	can_skip = false
	
	await get_tree().create_timer(skip_cooldown).timeout
	can_skip = true


func _change_scene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	Global.game_manager.change_ui_scene(MAIN_MENU_SCENE)
