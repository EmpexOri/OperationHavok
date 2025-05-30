extends Node

# Main pause menu
@onready var ResumeButton: Button = $"ResumeButton"
@onready var ControlsButton: Button = $"ControlsButton"
@onready var OptionsButton: TextureButton = $"OptionsButton"
@onready var BackButton: Button = $"BackButton"
@onready var Title: Label = $"Title"
@onready var MainButton: Button = $MenuButton
@onready var BackPanel: ColorRect = $Background
@onready var BackPanel2: ColorRect = $Background2

# Controls Menu
@onready var ControlsMenu: CanvasLayer = $ControlsMenu

# Options Menu
@onready var OptionsScene = $OptionsScene

func _ready():
	OptionsScene.visible = false


func show_pause_menu() -> void:
	# Bringing up the pause menu 
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	Title.visible = true
	MainButton.visible = true
	BackPanel.visible = true
	BackPanel2.visible = true
	ControlsMenu.visible = false
	BackButton.visible = false
	

func _on_resume_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	
	# Removing all objects
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	Title.visible = false
	MainButton.visible = false
	BackPanel.visible = false
	BackPanel2.visible = false
	ControlsMenu.visible = false
	BackButton.visible = false
	
	if get_tree().paused:
		get_tree().paused = false


func _on_controls_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the options menu and displaying controls menu
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	Title.visible = false
	MainButton.visible = false
	ControlsMenu.visible = true
	BackButton.visible = true
	
	BackButton.grab_focus()


func _on_options_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	
	# Removing the pause menu and displaying options menu
	OptionsScene.Options = true
	OptionsScene._check_back_button()
	OptionsScene.visible = true
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	Title.visible = false
	MainButton.visible = false
	BackButton.visible = true


func _on_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing all objects and bringing up the pause menu 
	OptionsScene.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	Title.visible = true
	MainButton.visible = true
	ControlsMenu.visible = false
	BackButton.visible = false
	
	ResumeButton.grab_focus()


func _on_menu_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	
	# Removing all objects
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	Title.visible = false
	MainButton.visible = false
	ControlsMenu.visible = false
	BackButton.visible = false
	
	if get_tree().paused:
		get_tree().paused = false
	
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
