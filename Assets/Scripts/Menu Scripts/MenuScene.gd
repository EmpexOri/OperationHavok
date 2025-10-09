extends Node2D

@onready var LoadingSprite = $LoadingScreenSprite
@onready var LoadingFinished = $LoadingFinished

var SkipLoading = false

func _ready():	
	$PlayButton.grab_focus()
	
	if not GlobalAudioController.is_main_menu_music_playing():
		GlobalAudioController.StopAllMusic()
		GlobalAudioController.PlayMainMenuMusic()

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
	GlobalPlayer.set_current_level_scene("res://Scenes/BetaLevel.tscn")
	get_tree().change_scene_to_file("res://Scenes/BetaLevel.tscn")

func _on_quit_button_pressed() -> void:
	GlobalAudioController.ButtonBackSound()
	var quitTimer = 0.15
	await get_tree().create_timer(quitTimer).timeout
	get_tree().quit()
