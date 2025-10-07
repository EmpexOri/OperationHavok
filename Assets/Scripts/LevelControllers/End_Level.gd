extends Control
signal end_screen_finished

@export var typing_sfx: AudioStream = preload("res://Assets/Sound/SFX/ClickSound.wav")
@export var typing_speed: float = 0.1  # Seconds per character
@export var fade_time: float = 1.5   
@export var auto_return_time: float = 16.0  

@onready var enemies_killed_label: Label = $Panel/VBoxContainer/EnemiesKilledLabel
@onready var player_level_label: Label = $Panel/VBoxContainer/PlayerLevelLabel
@onready var total_score_label: Label = $Panel/VBoxContainer/TotalScoreLabel
@onready var return_button: TextureButton = $Panel/ReturnButton
@onready var fade_rect: ColorRect = $FadeRect  
@onready var music_player: AudioStreamPlayer = $MusicAudioPlayer  

var has_returned: bool = false 

func _ready() -> void:
	fade_rect.color.a = 1.0  
	fade_rect.visible = true
	await fade_in()
	
	enemies_killed_label.text = ""
	player_level_label.text = ""
	total_score_label.text = ""
	
	return_button.pressed.connect(_on_return_pressed)
	return_button.disabled = true  
	
	# Start the typewriter display
	await start_display_stats()
	return_button.disabled = false
	
	auto_return_to_menu()

# Typewriter display
func start_display_stats() -> void:
	var gp = GlobalPlayer
	
	var stats_texts = [
		["Enemies Killed: %d" % gp.total_enemies_killed, enemies_killed_label],
		["Player Level: %d" % gp.ClassData[gp.CurrentClass]["Level"], player_level_label],
		["Total Score: %d" % gp.HelpXP, total_score_label]
	]
	
	for stat in stats_texts:
		var text = stat[0]
		var label = stat[1]
		await type_text(label, text)
	
	await get_tree().create_timer(1.0).timeout
	emit_signal("end_screen_finished")

func type_text(label: Label, text: String) -> void:
	label.text = ""
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = typing_sfx
	audio_player.volume_db = 0 
	add_child(audio_player)
	
	for c in text:
		label.text += c
		audio_player.play()
		await get_tree().create_timer(typing_speed).timeout
		
	audio_player.queue_free()

# Fade in
func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	fade_rect.visible = false
	
# Fade out
func fade_out() -> void:
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	
# Return button pressed
func _on_return_pressed() -> void:
	_return_to_menu()
	
# Auto-return coroutine
func auto_return_to_menu() -> void:
	# Run in background without blocking _ready
	_delayed_auto_return()
	
# Dlayed coroutine
func _delayed_auto_return() -> void:
	await get_tree().create_timer(auto_return_time).timeout
	if not has_returned:
		await _return_to_menu()
		
# Handles fading both screen and audio before switching scene
func _return_to_menu() -> void:
	if has_returned:
		return
	has_returned = true
	
	# Fade out music if it exists
	if music_player:
		var audio_tween = create_tween()
		audio_tween.tween_property(music_player, "volume_db", -80, 2.5)
		audio_tween.play()
		
	# Fade screen
	await fade_out()
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	SmearCanvas.reset()
	GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax
	if get_tree().paused:
		get_tree().paused = false
	# Clear any runtime objects if the current scene has the method
	var level_root = get_tree().current_scene
	if level_root and level_root.has_method("clear_runtime_objects"):
		level_root.clear_runtime_objects()
		print("Cleared runtime objects.")
	# Free the current level scene
	if level_root:
		level_root.queue_free()
	# Load Main Menu scene
	GlobalPlayer.set_current_level_scene("res://Scenes/MenuScene.tscn")
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
