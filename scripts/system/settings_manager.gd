extends Node
## Manages game settings including audio, video, gameplay, and controls

signal settings_changed(category: String)
signal settings_loaded
signal settings_saved

const SETTINGS_PATH: String = "user://settings.cfg"

const DEFAULT_SETTINGS := {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 1.0
	},
	"video": {
		"window_mode": DisplayServer.WINDOW_MODE_WINDOWED,
		"resolution": Vector2i(1024, 600),
		"vsync_enabled": true,
		"fps_limit": 0,  # 0 = unlimited
		"vhs_enabled": true
	},
	"gameplay": {
		"mouse_sensitivity": 0.002,
		"invert_y_axis": false
	},
	"controls": {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"sprint": KEY_SHIFT,
		"interact": KEY_E
	}
}

var settings: Dictionary = {}


func _ready() -> void:
	_initialize_settings()
	load_settings()


func _initialize_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)


## Loads settings from config file or creates default if not found
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		push_warning("No settings file found, using defaults")
		save_settings()
		apply_settings()
		settings_loaded.emit()
		return
	
	if config.has_section("audio"):
		settings.audio.master_volume = config.get_value("audio", "master_volume", DEFAULT_SETTINGS.audio.master_volume)
		settings.audio.music_volume = config.get_value("audio", "music_volume", DEFAULT_SETTINGS.audio.music_volume)
		settings.audio.sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SETTINGS.audio.sfx_volume)
	
	if config.has_section("video"):
		settings.video.window_mode = config.get_value("video", "window_mode", DEFAULT_SETTINGS.video.window_mode)
		var res_x = config.get_value("video", "resolution_x", DEFAULT_SETTINGS.video.resolution.x)
		var res_y = config.get_value("video", "resolution_y", DEFAULT_SETTINGS.video.resolution.y)
		settings.video.resolution = Vector2i(res_x, res_y)
		settings.video.vsync_enabled = config.get_value("video", "vsync_enabled", DEFAULT_SETTINGS.video.vsync_enabled)
		settings.video.fps_limit = config.get_value("video", "fps_limit", DEFAULT_SETTINGS.video.fps_limit)
		settings.video.vhs_enabled = config.get_value("video", "vhs_enabled", DEFAULT_SETTINGS.video.vhs_enabled)
	
	if config.has_section("gameplay"):
		settings.gameplay.mouse_sensitivity = config.get_value("gameplay", "mouse_sensitivity", DEFAULT_SETTINGS.gameplay.mouse_sensitivity)
		settings.gameplay.invert_y_axis = config.get_value("gameplay", "invert_y_axis", DEFAULT_SETTINGS.gameplay.invert_y_axis)
	
	if config.has_section("controls"):
		for action in settings.controls.keys():
			var key_code = config.get_value("controls", action, DEFAULT_SETTINGS.controls[action])
			settings.controls[action] = key_code
	
	apply_settings()
	settings_loaded.emit()


## Saves current settings to config file
func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", settings.audio.master_volume)
	config.set_value("audio", "music_volume", settings.audio.music_volume)
	config.set_value("audio", "sfx_volume", settings.audio.sfx_volume)
	
	config.set_value("video", "window_mode", settings.video.window_mode)
	config.set_value("video", "resolution_x", settings.video.resolution.x)
	config.set_value("video", "resolution_y", settings.video.resolution.y)
	config.set_value("video", "vsync_enabled", settings.video.vsync_enabled)
	config.set_value("video", "fps_limit", settings.video.fps_limit)
	config.set_value("video", "vhs_enabled", settings.video.vhs_enabled)
	
	config.set_value("gameplay", "mouse_sensitivity", settings.gameplay.mouse_sensitivity)
	config.set_value("gameplay", "invert_y_axis", settings.gameplay.invert_y_axis)
	
	for action in settings.controls.keys():
		config.set_value("controls", action, settings.controls[action])
	
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings: " + str(err))
	else:
		settings_saved.emit()


## Applies current settings to the game
func apply_settings() -> void:
	apply_audio_settings()
	apply_video_settings()


## Applies audio settings to AudioManager
func apply_audio_settings() -> void:
	if Global.audio_manager:
		Global.audio_manager.master_volume = settings.audio.master_volume
		Global.audio_manager.music_volume = settings.audio.music_volume
		Global.audio_manager.sfx_volume = settings.audio.sfx_volume
	settings_changed.emit("audio")


## Applies video settings to display
func apply_video_settings() -> void:
	DisplayServer.window_set_mode(settings.video.window_mode)
	
	if settings.video.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		get_window().size = settings.video.resolution
	
	if settings.video.vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	Engine.max_fps = settings.video.fps_limit
	
	_toggle_vhs_effect(settings.video.vhs_enabled)
	
	settings_changed.emit("video")


## Toggles the VHS post-processing effect
func _toggle_vhs_effect(enabled: bool) -> void:
	var vhs_node = get_tree().get_first_node_in_group("vhs_effect")
	if vhs_node:
		vhs_node.visible = enabled


## Resets all settings to defaults
func reset_to_defaults() -> void:
	_initialize_settings()
	apply_settings()


## Rebinds a control action to a new key
func rebind_action(action_name: String, new_key_code: int) -> void:
	if not settings.controls.has(action_name):
		push_error("Unknown action: " + action_name)
		return
	
	settings.controls[action_name] = new_key_code
	
	InputMap.action_erase_events(action_name)
	var new_event = InputEventKey.new()
	new_event.physical_keycode = new_key_code
	InputMap.action_add_event(action_name, new_event)
	
	settings_changed.emit("controls")


## Gets the key code for an action
func get_action_keycode(action_name: String) -> int:
	if settings.controls.has(action_name):
		return settings.controls[action_name]
	return 0


## Gets the display name for a key code
func get_key_name(keycode: int) -> String:
	return OS.get_keycode_string(keycode)


## Getters for specific settings
func get_master_volume() -> float:
	return settings.audio.master_volume

func get_music_volume() -> float:
	return settings.audio.music_volume

func get_sfx_volume() -> float:
	return settings.audio.sfx_volume

func get_mouse_sensitivity() -> float:
	return settings.gameplay.mouse_sensitivity

func get_invert_y_axis() -> bool:
	return settings.gameplay.invert_y_axis

func get_window_mode() -> int:
	return settings.video.window_mode

func get_resolution() -> Vector2i:
	return settings.video.resolution

func get_vsync_enabled() -> bool:
	return settings.video.vsync_enabled

func get_fps_limit() -> int:
	return settings.video.fps_limit

func get_vhs_enabled() -> bool:
	return settings.video.vhs_enabled


## Setters for specific settings
func set_master_volume(value: float) -> void:
	settings.audio.master_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()

func set_music_volume(value: float) -> void:
	settings.audio.music_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()

func set_sfx_volume(value: float) -> void:
	settings.audio.sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()

func set_mouse_sensitivity(value: float) -> void:
	settings.gameplay.mouse_sensitivity = clampf(value, 0.0001, 0.01)
	settings_changed.emit("gameplay")

func set_invert_y_axis(value: bool) -> void:
	settings.gameplay.invert_y_axis = value
	settings_changed.emit("gameplay")

func set_window_mode(mode: int) -> void:
	settings.video.window_mode = mode
	apply_video_settings()

func set_resolution(res: Vector2i) -> void:
	settings.video.resolution = res
	apply_video_settings()

func set_vsync_enabled(value: bool) -> void:
	settings.video.vsync_enabled = value
	apply_video_settings()

func set_fps_limit(value: int) -> void:
	settings.video.fps_limit = value
	apply_video_settings()

func set_vhs_enabled(value: bool) -> void:
	settings.video.vhs_enabled = value
	apply_video_settings()
