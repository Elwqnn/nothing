extends Node3D

## Script to handle maze generation and player spawning
## Attached to the maze generator scene

@onready var dungeon_generator: DungeonGenerator3D = $MazeGenerator

func _ready() -> void:
	# Connect to the dungeon generator's done_generating signal
	if dungeon_generator:
		dungeon_generator.done_generating.connect(_on_dungeon_done_generating)
		dungeon_generator.generating_failed.connect(_on_dungeon_generating_failed)
		
		# If generation is already complete (shouldn't happen, but just in case)
		if dungeon_generator.stage == DungeonGenerator3D.BuildStage.DONE:
			_on_dungeon_done_generating()


func _on_dungeon_done_generating() -> void:
	# Find a player spawn point in the generated dungeon
	var spawn_point = _find_player_spawn_point()
	
	if spawn_point:
		# Spawn the player at the spawn point
		if Global.game_manager:
			Global.game_manager.spawn_player_in_world(spawn_point.global_position)
	else:
		# Fallback: spawn at origin if no spawn point found
		push_warning("No player spawn point found in dungeon, spawning at origin")
		if Global.game_manager:
			Global.game_manager.spawn_player_in_world(Vector3(0, 1, 0))


func _on_dungeon_generating_failed() -> void:
	push_error("Dungeon generation failed!")
	# Still try to spawn player at origin as fallback
	if Global.game_manager:
		Global.game_manager.spawn_player_in_world(Vector3(0, 1, 0))


func _find_player_spawn_point() -> Node3D:
	# Look for nodes in the "player_spawn_point" group
	var spawn_points = get_tree().get_nodes_in_group("player_spawn_point")
	
	if spawn_points.size() > 0:
		# Return the first spawn point found
		return spawn_points[0] as Node3D
	
	return null
