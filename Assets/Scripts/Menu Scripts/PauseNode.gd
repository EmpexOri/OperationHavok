extends Node

@onready var ResumeButton: Button = $"../PausedLayer/ResumeButton"
@onready var ControlsButton: Button = $"../PausedLayer/ControlsButton"
@onready var OptionsButton: Button = $"../PausedLayer/OptionsButton"
@onready var QuitButton: Button = $"../PausedLayer/QuitButton"
@onready var BackButton: Button = $"../PausedLayer/BackButton"
@onready var Title: Label = $"../PausedLayer/Title"

# Controls Menu
@onready var ControlsTitle: Label = $"../PausedLayer/ControlsMenu/ControlsTitle"
@onready var ScrollBox: ScrollContainer = $"../PausedLayer/ControlsMenu/ControlsContainer"

# Options Menu
@onready var MasterLabel: Label = $"../PausedLayer/OptionsMenu/VBoxContainer/MasterLabel"
@onready var MasterSlider: HSlider = $"../PausedLayer/OptionsMenu/VBoxContainer/MasterSlider"
@onready var MusicLabel: Label =$"../PausedLayer/OptionsMenu/VBoxContainer/MusicLabel"
@onready var MusicSlider: HSlider = $"../PausedLayer/OptionsMenu/VBoxContainer/MusicSlider"
@onready var SFXLabel: Label =$"../PausedLayer/OptionsMenu/VBoxContainer/SFXLabel"
@onready var SFXSlider: HSlider = $"../PausedLayer/OptionsMenu/VBoxContainer/SFXSlider"
@onready var BrightnessLabel: Label = $"../PausedLayer/OptionsMenu/VBoxContainer/BrightnessLabel"
@onready var BrightnessSlider: HSlider = $"../PausedLayer/OptionsMenu/VBoxContainer/BrightnessSlider"


func _on_resume_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	
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
	
	# Removing the controls menu and bringing up options menu
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
	
