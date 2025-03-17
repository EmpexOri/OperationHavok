extends Node2D

func OnPlayButtonPressed() -> void:
	get_tree().change_scene_to_file("res:///Scenes/PlaygroundScene.tscn")


func OnOptionsButtonPressed() -> void:
	pass # Replace with function body.


func OnQuitButtonPressed() -> void:
	get_tree().quit()
