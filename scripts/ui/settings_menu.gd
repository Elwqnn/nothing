extends Control
## Settings menu UI - handles all game settings

signal back_pressed

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

# Audio controls
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_label: Label = %MasterVolumeLabel
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_label: Label = %MusicVolumeLabel
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var sfx_volume_label: Label = %SFXVolumeLabel

# Video controls
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_check: CheckBox = %VsyncCheck
@onready var fps_limit_option: OptionButton = %FPSLimitOption
@onready var vhs_check: CheckBox = %VHSCheck

# Gameplay controls
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_label: Label = %SensitivityLabel
@onready var invert_y_check: CheckBox = %InvertYCheck

# Control binding buttons
@onready var move_forward_button: Button = %MoveForwardButton
@onready var move_backward_button: Button = %MoveBackwardButton
@onready var move_left_button: Button = %MoveLeftButton
@onready var move_right_button: Button = %MoveRightButton
@onready var sprint_button: Button = %SprintButton
@onready var interact_button: Button = %InteractButton

# Action buttons
@onready var apply_button: Button = %ApplyButton
@onready var reset_button: Button = %ResetButton
@onready var back_button: Button = %BackButton

# Key rebinding popup
@onready var rebind_popup: Panel = %RebindPopup
@onready var rebind_label: Label = %RebindLabel

# Available resolutions
const RESOLUTIONS := [
	Vector2i(640, 360),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var is_rebinding: bool = false
var rebinding_action: String = ""


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_load_current_settings()
	rebind_popup.visible = false


func _setup_ui() -> void:
	# Setup window mode options
	window_mode_option.clear()
	window_mode_option.add_item("Windowed", DisplayServer.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("Fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
	window_mode_option.add_item("Borderless", DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Setup resolution options
	resolution_option.clear()
	for i in range(RESOLUTIONS.size()):
		var res = RESOLUTIONS[i]
		resolution_option.add_item(str(res.x) + "x" + str(res.y), i)
	
	# Setup FPS limit options
	fps_limit_option.clear()
	fps_limit_option.add_item("30 FPS", 30)
	fps_limit_option.add_item("60 FPS", 60)
	fps_limit_option.add_item("120 FPS", 120)
	fps_limit_option.add_item("Unlimited", 0)
	
	# Setup sliders
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.01
	
	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.01
	
	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 1.0
	sfx_volume_slider.step = 0.01
	
	sensitivity_slider.min_value = 0.0001
	sensitivity_slider.max_value = 0.01
	sensitivity_slider.step = 0.0001


func _connect_signals() -> void:
	# Audio sliders
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Video controls
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_limit_option.item_selected.connect(_on_fps_limit_selected)
	vhs_check.toggled.connect(_on_vhs_toggled)
	
	# Gameplay controls
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)
	
	# Control binding buttons
	move_forward_button.pressed.connect(_on_rebind_pressed.bind("move_forward"))
	move_backward_button.pressed.connect(_on_rebind_pressed.bind("move_backward"))
	move_left_button.pressed.connect(_on_rebind_pressed.bind("move_left"))
	move_right_button.pressed.connect(_on_rebind_pressed.bind("move_right"))
	sprint_button.pressed.connect(_on_rebind_pressed.bind("sprint"))
	interact_button.pressed.connect(_on_rebind_pressed.bind("interact"))
	
	# Action buttons
	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _load_current_settings() -> void:
	# Audio settings
	master_volume_slider.value = SettingsManager.get_master_volume()
	music_volume_slider.value = SettingsManager.get_music_volume()
	sfx_volume_slider.value = SettingsManager.get_sfx_volume()
	_update_volume_labels()
	
	# Video settings
	var window_mode = SettingsManager.get_window_mode()
	for i in range(window_mode_option.item_count):
		if window_mode_option.get_item_id(i) == window_mode:
			window_mode_option.selected = i
			break
	
	var current_res = SettingsManager.get_resolution()
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i] == current_res:
			resolution_option.selected = i
			break
	
	vsync_check.button_pressed = SettingsManager.get_vsync_enabled()
	
	var fps_limit = SettingsManager.get_fps_limit()
	for i in range(fps_limit_option.item_count):
		if fps_limit_option.get_item_id(i) == fps_limit:
			fps_limit_option.selected = i
			break
	
	vhs_check.button_pressed = SettingsManager.get_vhs_enabled()
	
	# Gameplay settings
	sensitivity_slider.value = SettingsManager.get_mouse_sensitivity()
	_update_sensitivity_label()
	invert_y_check.button_pressed = SettingsManager.get_invert_y_axis()
	
	# Control bindings
	_update_control_buttons()


func _update_volume_labels() -> void:
	master_volume_label.text = str(int(master_volume_slider.value * 100)) + "%"
	music_volume_label.text = str(int(music_volume_slider.value * 100)) + "%"
	sfx_volume_label.text = str(int(sfx_volume_slider.value * 100)) + "%"


func _update_sensitivity_label() -> void:
	sensitivity_label.text = str(snapped(sensitivity_slider.value * 1000, 0.1))


func _update_control_buttons() -> void:
	move_forward_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("move_forward"))
	move_backward_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("move_backward"))
	move_left_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("move_left"))
	move_right_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("move_right"))
	sprint_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("sprint"))
	interact_button.text = SettingsManager.get_key_name(SettingsManager.get_action_keycode("interact"))


func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_update_volume_labels()


func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	_update_volume_labels()


func _on_window_mode_selected(index: int) -> void:
	var mode = window_mode_option.get_item_id(index)
	SettingsManager.set_window_mode(mode)


func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution(RESOLUTIONS[index])


func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.set_vsync_enabled(enabled)


func _on_fps_limit_selected(index: int) -> void:
	var limit = fps_limit_option.get_item_id(index)
	SettingsManager.set_fps_limit(limit)


func _on_vhs_toggled(enabled: bool) -> void:
	SettingsManager.set_vhs_enabled(enabled)


func _on_sensitivity_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)
	_update_sensitivity_label()


func _on_invert_y_toggled(enabled: bool) -> void:
	SettingsManager.set_invert_y_axis(enabled)


func _on_rebind_pressed(action: String) -> void:
	is_rebinding = true
	rebinding_action = action
	rebind_popup.visible = true
	rebind_label.text = "Press any key for " + action.replace("_", " ").capitalize() + "..."


func _input(event: InputEvent) -> void:
	if is_rebinding and event is InputEventKey and event.pressed:
		# Rebind the action
		SettingsManager.rebind_action(rebinding_action, event.physical_keycode)
		_update_control_buttons()
		
		# Close popup
		is_rebinding = false
		rebinding_action = ""
		rebind_popup.visible = false
		get_viewport().set_input_as_handled()


func _on_apply_pressed() -> void:
	SettingsManager.save_settings()


func _on_reset_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_load_current_settings()


func _on_back_pressed() -> void:
	back_pressed.emit()
	queue_free()
