class_name GameManager extends Node
## manages game scene transitions and state

signal scene_changed(scene_type: String, new_scene: Node)
signal scene_load_failed(scene_path: String)

@export var world: Node3D
@export var ui: Node
@export var player_scene: PackedScene

var current_world_scene: Node3D
var current_ui_scene: Node
var current_player: Node3D

var _is_loading: bool = false


func _ready() -> void:
	Global.game_manager = self
	Global.transition_manager = %TransitionManager
	Global.audio_manager = %AudioManager
	current_ui_scene = %SplashScreenManager


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
