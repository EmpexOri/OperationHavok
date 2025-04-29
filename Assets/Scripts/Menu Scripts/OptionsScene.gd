extends CanvasLayer

func _ready():
	$BackButton.grab_focus()

func OnBackButtonPressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
