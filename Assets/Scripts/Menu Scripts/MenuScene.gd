extends Node2D

@onready var LoadingSprite = $LoadingScreenSprite
@onready var LoadingFinished = $LoadingFinished
@onready var LeaderboardLabel: Label = $LeaderboardLabel  

var SkipLoading = false

func _ready():	
	$PlayButton.grab_focus()
	
	if not GlobalAudioController.is_main_menu_music_playing():
		GlobalAudioController.StopAllMusic()
		GlobalAudioController.PlayMainMenuMusic()
		
	show_leaderboard()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Start"):
		_on_play_button_pressed()

func _on_play_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.StopMainMenuMusic()
	
	# DEMO LOADING SCREEN
	#LoadingSprite.visible = true
	#LoadingSprite.play("Loading")
	#var TimeInSeconds = 3.0
	#await get_tree().create_timer(TimeInSeconds).timeout
	#LoadingSprite.queue_free()
	
	#LoadingFinished.visible = true
	#var TimeInSeconds2 = 0.8
	#await get_tree().create_timer(TimeInSeconds2).timeout
	#LoadingFinished.queue_free()
	GlobalPlayer.set_current_level_scene("res://Scenes/LevelSelectScene.tscn")
	get_tree().change_scene_to_file("res://Scenes/LevelSelectScene.tscn")

func _on_quit_button_pressed() -> void:
	GlobalAudioController.ButtonBackSound()
	var quitTimer = 0.15
	await get_tree().create_timer(quitTimer).timeout
	get_tree().quit()

func show_leaderboard():
	#if not GlobalPlayer:
	#	print("GlobalPlayer not found, cannot load leaderboard.")
	#	return
	#	
	#var text := GlobalPlayer.get_leaderboard_text()
	#LeaderboardLabel.text = text
	pass
