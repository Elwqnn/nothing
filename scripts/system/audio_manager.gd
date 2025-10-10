class_name AudioManager extends Node
## manages audio playback for music and sound effects with smooth transitions

signal music_changed(track_name: String)
signal music_finished

@export_group("Audio Players")
@export var music_player_1: AudioStreamPlayer
@export var music_player_2: AudioStreamPlayer
@export var sfx_player: AudioStreamPlayer

@export_group("Settings")
@export_range(0.0, 2.0, 0.1) var default_fade_duration: float = 1.0
@export_range(0.0, 1.0, 0.05) var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

@export_range(0.0, 1.0, 0.05) var music_volume: float = 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

@export_range(0.0, 1.0, 0.05) var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_update_volumes()

@export_group("Transition Easing")
@export var fade_transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var fade_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

# audio library - maps names to file paths
var audio_library: Dictionary = {
	"feldup_findings": "res://assets/audio/musics/feldup-findings.mp3",
	"neon_light_buzz": "res://assets/audio/sounds/neon-light-buzz.mp3",
	"neon_light_flickering": "res://assets/audio/sounds/neon-light-flickering2.wav",
}

var current_music_player: AudioStreamPlayer
var next_music_player: AudioStreamPlayer
var current_track_name: String = ""
var is_transitioning: bool = false


func _ready() -> void:
	# initialize players
	if not music_player_1:
		music_player_1 = AudioStreamPlayer.new()
		music_player_1.name = "MusicPlayer1"
		music_player_1.bus = "Music"
		add_child(music_player_1)
	
	if not music_player_2:
		music_player_2 = AudioStreamPlayer.new()
		music_player_2.name = "MusicPlayer2"
		music_player_2.bus = "Music"
		add_child(music_player_2)
	
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		sfx_player.bus = "SFX"
		add_child(sfx_player)
	
	# set up initial state
	current_music_player = music_player_1
	next_music_player = music_player_2
	
	music_player_1.volume_db = linear_to_db(0.0)
	music_player_2.volume_db = linear_to_db(0.0)
	
	music_player_1.finished.connect(_on_music_finished)
	music_player_2.finished.connect(_on_music_finished)
	
	if SettingsManager:
		master_volume = SettingsManager.get_master_volume()
		music_volume = SettingsManager.get_music_volume()
		sfx_volume = SettingsManager.get_sfx_volume()
	
	_update_volumes()


## plays music by name with optional fade in and loop
func play_music(track_name: String, fade_duration: float = -1.0, loop: bool = true) -> void:
	if not current_music_player or not next_music_player:
		push_warning("AudioManager not ready yet, cannot play music")
		return
	
	if fade_duration < 0:
		fade_duration = default_fade_duration
	
	if not audio_library.has(track_name):
		push_error("audio track not found in library: " + track_name)
		return
	
	if current_track_name == track_name and current_music_player.playing:
		return
	
	var audio_path = audio_library[track_name]
	var audio_stream = load(audio_path) as AudioStream
	
	if not audio_stream:
		push_error("failed to load audio: " + audio_path)
		return
	
	next_music_player.stream = audio_stream
	
	if audio_stream is AudioStreamMP3:
		audio_stream.loop = loop
	elif audio_stream is AudioStreamWAV:
		if loop:
			audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			audio_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	is_transitioning = true
	
	if current_music_player.playing:
		await _crossfade_music(fade_duration)
	else:
		await _fade_in_music(next_music_player, fade_duration)
	
	# swap players
	var temp = current_music_player
	current_music_player = next_music_player
	next_music_player = temp
	
	current_track_name = track_name
	is_transitioning = false
	music_changed.emit(track_name)


## stops the current music with optional fade out
func stop_music(fade_duration: float = -1.0) -> void:
	if not current_music_player:
		return
	
	if fade_duration < 0:
		fade_duration = default_fade_duration
	
	if current_music_player.playing:
		await _fade_out_music(current_music_player, fade_duration)
		current_music_player.stop()
		current_track_name = ""


## plays a sound effect by name
func play_sfx(sound_name: String, volume_modifier: float = 1.0) -> void:
	if not sfx_player:
		push_warning("AudioManager not ready yet, cannot play SFX")
		return
	
	if not audio_library.has(sound_name):
		push_error("sound effect not found in library: " + sound_name)
		return
	
	var audio_path = audio_library[sound_name]
	var audio_stream = load(audio_path) as AudioStream
	
	if not audio_stream:
		push_error("failed to load audio: " + audio_path)
		return
	
	if audio_stream is AudioStreamMP3:
		audio_stream.loop = false
	elif audio_stream is AudioStreamWAV:
		audio_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	sfx_player.stream = audio_stream
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume * volume_modifier)
	sfx_player.play()


## stops the current sound effect
func stop_sfx(fade_duration: float = 0.0) -> void:
	if not sfx_player or not sfx_player.playing:
		return
	
	if fade_duration > 0.0:
		var start_volume = db_to_linear(sfx_player.volume_db)
		var tween = create_tween()
		tween.tween_method(_set_player_volume.bind(sfx_player), 
			start_volume, 0.0, fade_duration) \
			.set_trans(fade_transition_type).set_ease(fade_ease_type)
		await tween.finished
	
	sfx_player.stop()


## pauses the current music
func pause_music() -> void:
	if current_music_player and current_music_player.playing:
		current_music_player.stream_paused = true


## resumes the paused music
func resume_music() -> void:
	if current_music_player and current_music_player.stream_paused:
		current_music_player.stream_paused = false


## adds a new audio track to the library dynamically
func register_audio(track_name: String, file_path: String) -> void:
	audio_library[track_name] = file_path


## crossfades between the current and next music player
func _crossfade_music(duration: float) -> void:
	next_music_player.volume_db = linear_to_db(0.0)
	next_music_player.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_method(_set_player_volume.bind(current_music_player), 
		db_to_linear(current_music_player.volume_db), 0.0, duration) \
		.set_trans(fade_transition_type).set_ease(fade_ease_type)
	tween.tween_method(_set_player_volume.bind(next_music_player), 
		0.0, music_volume * master_volume, duration) \
		.set_trans(fade_transition_type).set_ease(fade_ease_type)
	
	await tween.finished
	current_music_player.stop()


## fades in a music player
func _fade_in_music(player: AudioStreamPlayer, duration: float) -> void:
	player.volume_db = linear_to_db(0.0)
	player.play()
	
	var tween = create_tween()
	tween.tween_method(_set_player_volume.bind(player), 
		0.0, music_volume * master_volume, duration) \
		.set_trans(fade_transition_type).set_ease(fade_ease_type)
	
	await tween.finished


## fades out a music player
func _fade_out_music(player: AudioStreamPlayer, duration: float) -> void:
	var start_volume = db_to_linear(player.volume_db)
	
	var tween = create_tween()
	tween.tween_method(_set_player_volume.bind(player), 
		start_volume, 0.0, duration) \
		.set_trans(fade_transition_type).set_ease(fade_ease_type)
	
	await tween.finished


## sets the volume of a specific player (for tween callbacks)
func _set_player_volume(volume: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(max(volume, 0.00001))  # avoid -inf


## updates all player volumes based on current settings
func _update_volumes() -> void:
	if not is_inside_tree():
		return
	
	if current_music_player and current_music_player.playing:
		var current_linear = db_to_linear(current_music_player.volume_db)
		if current_linear > 0.001:  # only update if not silent
			current_music_player.volume_db = linear_to_db(music_volume * master_volume)
	
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)


## called when music finishes playing
func _on_music_finished() -> void:
	if current_music_player and not current_music_player.playing:
		music_finished.emit()
