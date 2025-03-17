extends Node2D


func OnBackButtonPressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
