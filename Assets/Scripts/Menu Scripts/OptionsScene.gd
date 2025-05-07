extends CanvasLayer

var Options = true

@onready var BackButton = $BackButton

func _ready():
	$BackButton.grab_focus()

func _check_back_button() -> void:
	if Options == true:
		print("Options is true")
		BackButton.visible = false
	else:
		BackButton.visible = true


func _on_back_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
