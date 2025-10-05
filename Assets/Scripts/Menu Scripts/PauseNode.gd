extends Node

# Main pause menu
@onready var ResumeButton: TextureButton = $"ResumeButton"
@onready var ControlsButton: TextureButton = $"ControlsButton"
@onready var OptionsButton: TextureButton = $"OptionsButton"
@onready var BackButton2: TextureButton = $CommandoSkillTree/BackButton2
@onready var SkillTreeButton: TextureButton = $SkillTreeButton
@onready var Title: Label = $"Title"
@onready var MainButton: TextureButton = $MenuButton
@onready var BackPanel = $PauseMenuBg

# Controls Menu
@onready var ControlsMenu: CanvasLayer = $ControlsMenu

# Options Menu
@onready var OptionsScene = $OptionsScene

# Commando Skill Tree
@onready var SkillTree = $CommandoSkillTree

func _ready():
	$ResumeButton.grab_focus()
	
	# Connecting options menu signal
	OptionsScene.OptionsClosed.connect(_on_options_closed)
	
	OptionsScene.visible = false
	SkillTree.visible = false


func show_pause_menu() -> void:	
	# Bringing up the pause menu 
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true
	BackPanel.visible = true
	ControlsMenu.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	$ResumeButton.grab_focus()

func _on_resume_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	
	# Removing all objects
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	BackPanel.visible = false
	ControlsMenu.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	if get_tree().paused:
		get_tree().paused = false


func _on_controls_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the options menu and displaying controls menu
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	ControlsMenu.visible = true
	BackButton2.visible = false
	SkillTree.visible = false


func _on_options_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	
	# Removing the pause menu and displaying options menu
	OptionsScene.Options = true
	OptionsScene.visible = true
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	OptionsScene.MasterSlider.grab_focus()


func _on_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing all objects and bringing up the pause menu 
	OptionsScene.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true
	ControlsMenu.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	ResumeButton.grab_focus()


func _on_menu_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	SmearCanvas.reset()
	
	GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax
	
	# Removing all objects
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	ControlsMenu.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	if get_tree().paused:
		get_tree().paused = false
	
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")


func _on_skill_tree_button_pressed() -> void:
	SkillTree._check_back_button()
	BackButton2.visible = true
	SkillTree.visible = true
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	BackButton2.visible = true
	SkillTree.update_skill_trees_shown()
	SkillTree.restore_unlocked_skills(self)   
	GlobalAudioController.ClickSound()

func _on_options_closed():
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing all objects and bringing up the pause menu 
	OptionsScene.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true
	ControlsMenu.visible = false
	BackButton2.visible = false
	SkillTree.visible = false
	
	$ResumeButton.grab_focus()
