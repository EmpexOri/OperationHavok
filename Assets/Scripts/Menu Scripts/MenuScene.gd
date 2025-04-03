extends Node2D

func OnPlayButtonPressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.LevelOneMusic()
	get_tree().change_scene_to_file("res:///Scenes/PlaygroundScene.tscn")


func OnOptionsButtonPressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res:///Scenes/OptionsScene.tscn")


func OnQuitButtonPressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().quit()
