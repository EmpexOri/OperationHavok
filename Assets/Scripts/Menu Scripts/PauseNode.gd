extends Node

# Main pause menu
@onready var ResumeButton: Button = $"ResumeButton"
@onready var ControlsButton: Button = $"ControlsButton"
@onready var OptionsButton: Button = $"OptionsButton"
@onready var QuitButton: Button = $"QuitButton"
@onready var BackButton: Button = $"BackButton"
@onready var Title: Label = $"Title"

# Controls Menu
@onready var ControlsTitle: Label = $"ControlsMenu/ControlsTitle"
@onready var ScrollBox: ScrollContainer = $"ControlsMenu/ControlsContainer"

# Options Menu
@onready var OptionsScene = $OptionsScene

func _ready():
	OptionsScene.visible = false

func show_pause_menu() -> void:
	# Bringing up the pause menu 
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	QuitButton.visible = true
	Title.visible = true
	ControlsTitle.visible = false
	ScrollBox.visible = false
	BackButton.visible = false
	

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
	OptionsScene.Options = true
	OptionsScene._check_back_button()
	OptionsScene.visible = true
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	QuitButton.visible = false
	Title.visible = false
	BackButton.visible = true


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
	OptionsScene.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	QuitButton.visible = true
	Title.visible = true
	ControlsTitle.visible = false
	ScrollBox.visible = false
	BackButton.visible = false
	
	ResumeButton.grab_focus()
