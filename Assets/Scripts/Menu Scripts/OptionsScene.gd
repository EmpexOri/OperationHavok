extends Node2D


func OnBackButtonPressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
