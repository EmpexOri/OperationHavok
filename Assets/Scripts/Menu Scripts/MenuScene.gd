extends Node2D

func _ready():
	$PlayButton.grab_focus()
	

func _on_play_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.LevelOneMusic()
	get_tree().change_scene_to_file("res:///Scenes/LevelSelectScene.tscn")


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
