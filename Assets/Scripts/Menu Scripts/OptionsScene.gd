extends CanvasLayer

var Options = true

signal OptionsClosed

@onready var BackButton = $BackButton

@onready var OptionsScene = $OptionsScene
@onready var PauseMenu = $PauseMenu

func _ready():
	$BackButton.grab_focus()

func _on_back_button_pressed() -> void:
	if Options == false:
		# Go to main menu
		GlobalAudioController.ClickSound()
		get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
	if Options == true:
		# Emit signal to pause menu to close options menu
		OptionsClosed.emit()
