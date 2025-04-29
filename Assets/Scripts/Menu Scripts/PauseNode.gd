extends Node

@onready var ResumeButton: Button = $"../ResumeButton"
@onready var ControlsButton: Button = $"../ControlsButton"
@onready var OptionsButton: Button = $"../OptionsButton"
@onready var QuitButton: Button = $"../QuitButton"
@onready var BackButton: Button = $"../BackButton"
@onready var Title: Label = $"../Title"

# Controls Menu
@onready var ControlsTitle: Label = $"../ControlsMenu/ControlsTitle"
@onready var ScrollBox: ScrollContainer = $"../ControlsMenu/ControlsContainer"

# Options Menu
@onready var MasterLabel: Label = $"../OptionsMenu/VBoxContainer/MasterLabel"
@onready var MasterSlider: HSlider = $"../OptionsMenu/VBoxContainer/MasterSlider"
@onready var MusicLabel: Label =$"../OptionsMenu/VBoxContainer/MusicLabel"
@onready var MusicSlider: HSlider = $"../OptionsMenu/VBoxContainer/MusicSlider"
@onready var SFXLabel: Label =$"../OptionsMenu/VBoxContainer/SFXLabel"
@onready var SFXSlider: HSlider = $"../OptionsMenu/VBoxContainer/SFXSlider"
@onready var BrightnessLabel: Label = $"../OptionsMenu/VBoxContainer/BrightnessLabel"
@onready var BrightnessSlider: HSlider = $"../OptionsMenu/VBoxContainer/BrightnessSlider"


func _on_resume_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	
		# Removing all objects and bringing up the pause menu 
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	QuitButton.visible = false
	Title.visible = false
	ControlsTitle.visible = false
	ScrollBox.visible = false
	BackButton.visible = false
	MasterLabel.visible = false
	MasterSlider.visible = false
	MusicLabel.visible = false
	MusicSlider.visible = false
	SFXLabel.visible = false
	SFXSlider.visible = false
	BrightnessLabel.visible = false
	BrightnessSlider.visible = false
	
	if get_tree().paused:
		get_tree().paused = false


func _on_controls_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the options menu and displaying controls menu
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	QuitButton.visible = false
	Title.visible = false
	ControlsTitle.visible = true
	ScrollBox.visible = true
	BackButton.visible = true
	
	BackButton.grab_focus()


func _on_options_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	
	# Removing the pause menu and displaying options menu
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	QuitButton.visible = false
	Title.visible = false
	MasterLabel.visible = true
	MasterSlider.visible = true
	MusicLabel.visible = true
	MusicSlider.visible = true
	SFXLabel.visible = true
	SFXSlider.visible = true
	BrightnessLabel.visible = true
	BrightnessSlider.visible = true
	BackButton.visible = true
	
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	# Play sound on button press and a timer so sound plays before game quits
	GlobalAudioController.ClickSound()
	var quitTimer = 0.15
	await get_tree().create_timer(quitTimer).timeout
	get_tree().quit()


func _on_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing all objects and bringing up the pause menu 
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	QuitButton.visible = true
	Title.visible = true
	ControlsTitle.visible = false
	ScrollBox.visible = false
	BackButton.visible = false
	MasterLabel.visible = false
	MasterSlider.visible = false
	MusicLabel.visible = false
	MusicSlider.visible = false
	SFXLabel.visible = false
	SFXSlider.visible = false
	BrightnessLabel.visible = false
	BrightnessSlider.visible = false
	
	ResumeButton.grab_focus()
