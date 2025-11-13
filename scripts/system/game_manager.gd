class_name GameManager extends Node
## manages game scene transitions and state

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER_WIN,
	GAME_OVER_LOSE
}

signal scene_changed(scene_type: String, new_scene: Node)
signal scene_load_failed(scene_path: String)
signal game_state_changed(new_state: GameState)
signal time_updated(game_hour: int, time_string: String, seconds_remaining: float)
signal game_won()
signal game_lost(reason: String)

@export var world: Node3D
@export var ui: Node
@export var player_scene: PackedScene

var current_world_scene: Node3D
var current_ui_scene: Node
var current_player: Node3D

var _is_loading: bool = false

## Game state management
var current_state: GameState = GameState.MENU

## Night timer settings (11:00 PM to 6:00 AM = 7 hours)
const GAME_DURATION_SECONDS: float = 525.0  # 8 min 45 sec (7 hours * 75 sec/hour)
const SECONDS_PER_GAME_HOUR: float = 75.0  # 1 minute 15 seconds per game hour
const START_HOUR: int = 23  # 11:00 PM
const END_HOUR: int = 6  # 6:00 AM

var game_timer: Timer
var time_elapsed: float = 0.0
var time_remaining: float = GAME_DURATION_SECONDS


func _ready() -> void:
	Global.game_manager = self
	Global.transition_manager = %TransitionManager
	Global.audio_manager = %AudioManager
	Global.vhs_post_process = %VHSPostProcess
	current_ui_scene = %SplashScreenManager

	# Initialize game timer
	game_timer = Timer.new()
	game_timer.wait_time = 0.1  # Update every 0.1 seconds
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)


func _on_game_timer_timeout() -> void:
	if current_state != GameState.PLAYING:
		return

	time_elapsed += game_timer.wait_time
	time_remaining = GAME_DURATION_SECONDS - time_elapsed

	# Calculate current in-game hour
	var hours_passed = time_elapsed / SECONDS_PER_GAME_HOUR
	var current_hour = START_HOUR + int(hours_passed)

	# Handle hour wrap around midnight
	if current_hour >= 24:
		current_hour -= 24

	# Calculate minutes within the current hour
	var minutes_in_hour = fmod(hours_passed, 1.0) * 60.0

	# Format time string (e.g., "11:00 PM")
	var time_string = _format_time(current_hour, int(minutes_in_hour))

	# Emit update signal
	time_updated.emit(current_hour, time_string, time_remaining)

	# Check if night is over (survived!)
	if time_remaining <= 0.0:
		trigger_win()


func _format_time(hour: int, minutes: int) -> String:
	var display_hour = hour
	var period = "AM"

	if hour >= 12:
		period = "PM"
		if hour > 12:
			display_hour = hour - 12
	elif hour == 0:
		display_hour = 12

	return "%d:%02d %s" % [display_hour, minutes, period]


## Game flow control
func start_game() -> void:
	if current_state == GameState.PLAYING:
		push_warning("Game already started")
		return

	# Reset timer
	time_elapsed = 0.0
	time_remaining = GAME_DURATION_SECONDS

	# Change state
	current_state = GameState.PLAYING
	game_state_changed.emit(current_state)

	# Start timer
	game_timer.start()

	# Emit initial time update
	var time_string = _format_time(START_HOUR, 0)
	time_updated.emit(START_HOUR, time_string, time_remaining)


func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return

	current_state = GameState.PAUSED
	game_state_changed.emit(current_state)
	game_timer.stop()


func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return

	current_state = GameState.PLAYING
	game_state_changed.emit(current_state)
	game_timer.start()


func trigger_win() -> void:
	if current_state != GameState.PLAYING:
		return

	current_state = GameState.GAME_OVER_WIN
	game_state_changed.emit(current_state)
	game_timer.stop()

	# Disable player input
	if current_player:
		current_player.set_process_mode(Node.PROCESS_MODE_DISABLED)

	game_won.emit()

	# Show win screen
	await get_tree().create_timer(1.0).timeout  # Brief delay
	change_ui_scene("res://scenes/ui/game_over_win.tscn", true)


func trigger_lose(reason: String) -> void:
	if current_state != GameState.PLAYING:
		return

	current_state = GameState.GAME_OVER_LOSE
	game_state_changed.emit(current_state)
	game_timer.stop()

	# Disable player input
	if current_player:
		current_player.set_process_mode(Node.PROCESS_MODE_DISABLED)

	game_lost.emit(reason)

	# Show lose screen with reason
	await get_tree().create_timer(1.0).timeout  # Brief delay
	change_ui_scene("res://scenes/ui/game_over_lose.tscn", true)


func reset_game() -> void:
	current_state = GameState.MENU
	game_state_changed.emit(current_state)
	time_elapsed = 0.0
	time_remaining = GAME_DURATION_SECONDS
	game_timer.stop()


func change_ui_scene(scene_path: String, delete: bool = true,
	keep_running: bool = false, async_load: bool = false) -> void:
	await _change_scene(scene_path, ui, "ui", delete, keep_running, async_load)


func change_world_scene(scene_path: String, spawn_player: bool = false, delete: bool = true,
	keep_running: bool = false, async_load: bool = false) -> void:
	await _change_scene(scene_path, world, "world", delete, keep_running, async_load)
	
	if spawn_player and player_scene:
		spawn_player_in_world()


func _change_scene(scene_path: String, parent: Node, scene_type: String,
	delete: bool, keep_running: bool, async_load: bool) -> void:
	
	if _is_loading:
		push_warning("scene change already in progress")
		return
	
	_is_loading = true
	
	var current_scene: Node
	if scene_type == "ui":
		current_scene = current_ui_scene
	else:
		current_scene = current_world_scene
	
	var new_scene = await _load_scene(scene_path, async_load)
	if new_scene == null:
		scene_load_failed.emit(scene_path)
		_is_loading = false
		return
	
	if current_scene:
		if keep_running:
			current_scene.visible = false
		elif delete:
			current_scene.queue_free()
		else:
			parent.remove_child(current_scene)
	
	parent.add_child(new_scene)
	
	if scene_type == "ui":
		current_ui_scene = new_scene
	else:
		current_world_scene = new_scene
	
	scene_changed.emit(scene_type, new_scene)
	_is_loading = false


func _load_scene(scene_path: String, is_async: bool) -> Node:
	if not ResourceLoader.exists(scene_path):
		push_error("scene does not exist: " + scene_path)
		return null
	
	var scene_resource: Resource
	
	if is_async:
		if ResourceLoader.load_threaded_request(scene_path) != OK:
			push_error("failed to start async loading: " + scene_path)
			return null
		
		while true:
			var status = ResourceLoader.load_threaded_get_status(scene_path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				scene_resource = ResourceLoader.load_threaded_get(scene_path)
				break
			elif status == ResourceLoader.THREAD_LOAD_FAILED or \
				status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("async loading failed: " + scene_path)
				return null
			await get_tree().process_frame
	else:
		scene_resource = load(scene_path)
	
	if scene_resource == null:
		push_error("failed to load scene: " + scene_path)
		return null
	
	return scene_resource.instantiate()


func spawn_player_in_world(spawn_position: Vector3 = Vector3(-3, 1, 0)) -> void:
	# remove existing player if any
	if current_player:
		current_player.queue_free()
		current_player = null
	
	if not player_scene:
		push_error("player_scene not set in GameManager")
		return
	
	if not current_world_scene:
		push_warning("no world scene loaded, cannot spawn player")
		return
	
	# disable menu camera if it exists
	var menu_camera = current_world_scene.find_child("MenuCamera", true, false)
	if menu_camera:
		menu_camera.current = false
	
	current_player = player_scene.instantiate()
	
	# set position and rotation before adding to scene tree
	# so _ready() functions see the correct values
	current_player.position = spawn_position
	current_player.rotation.y = deg_to_rad(-90)
	
	current_world_scene.add_child(current_player)
	
	# ensure player camera is active
	var player_camera = current_player.find_child("Camera3D", true, false)
	if player_camera:
		player_camera.current = true
