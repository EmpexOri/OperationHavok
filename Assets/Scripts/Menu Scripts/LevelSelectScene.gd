extends Node2D

# Level Select screen variables
@onready var Level1Button = $LevelSelect/Level1Button
@onready var Level2Button = $LevelSelect/Level2Button

# Class Select screen variables
@onready var CommandoButton = $ClassSelect/CommandoButton
@onready var TechnomancerButton = $ClassSelect/TechnomancerButton
@onready var CommandoImage = $ClassSelect/Commando
@onready var TechnomancerImage = $ClassSelect/Technomancer


func _on_back_button_pressed() -> void:
	# Go to menu when back button is pressed
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")


func _on_level_1_button_pressed() -> void:
	# Go to level one when level one button is pressed
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/PlaygroundScene.tscn"	)


func _on_class_select_button_pressed() -> void:
	# Remove the level select screen and display the class select screen 
	Level1Button.visible = false
	Level2Button.visible = false
	CommandoButton.visible = true
	TechnomancerButton.visible = true
	CommandoImage.visible = true
	TechnomancerImage.visible = true


func _on_level_select_button_pressed() -> void:
	# Remove the class select screen and display the level select screen 
	Level1Button.visible = true
	Level2Button.visible = true
	CommandoButton.visible = false
	TechnomancerButton.visible = false
	CommandoImage.visible = false
	TechnomancerImage.visible = false


func _on_commando_button_pressed() -> void:
	# Changes class to Commando
	GlobalPlayer.CurrentClass = "Commando"

	# Changes class to Technomancer
func _on_technomancer_button_pressed() -> void:
	GlobalPlayer.CurrentClass = "Technomancer"
