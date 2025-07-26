extends Node2D

@onready var LoadingSprite = $LoadingScreenSprite
@onready var LoadingFinished = $LoadingFinished

var SkipLoading = false

func _ready():
	$PlayButton.grab_focus()
	
	if not GlobalAudioController.is_main_menu_music_playing():
		GlobalAudioController.StopAllMusic()
		GlobalAudioController.PlayMainMenuMusic()

# Causes problems, will sort out after demo
#func _input(Event):
#	if Input.is_action_just_pressed("SkipLoad"):
#		LoadingSprite.queue_free()
#		LoadingFinished.queue_free()

func _on_play_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.StopMainMenuMusic()
	
	# DEMO LOADING SCREEN
	LoadingSprite.visible = true
	LoadingSprite.play("Loading")
	var TimeInSeconds = 3.0
	await get_tree().create_timer(TimeInSeconds).timeout
	LoadingSprite.queue_free()
	
	LoadingFinished.visible = true
	var TimeInSeconds2 = 0.8
	await get_tree().create_timer(TimeInSeconds2).timeout
	LoadingFinished.queue_free()
	
	get_tree().change_scene_to_file("res://Scenes/AlphaLevel1.tscn")

func _on_quit_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	var quitTimer = 0.15
	await get_tree().create_timer(quitTimer).timeout
	get_tree().quit()


func _on_skill_tree_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/Options/CommandoSkillTree.tscn")


func _on_options_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res:///Scenes/Options/OptionsScene.tscn")
