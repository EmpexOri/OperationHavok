extends Node

# Main pause menu
@onready var PauseMenu = $"."
@onready var ResumeButton: TextureButton = $"ResumeButton"
@onready var ControlsButton: TextureButton = $"ControlsButton"
@onready var OptionsButton: TextureButton = $"OptionsButton"
@onready var SkillTreeButton: TextureButton = $SkillTreeButton
@onready var Title: Label = $"Title"
@onready var MainButton: TextureButton = $MenuButton
@onready var BackPanel = $PauseMenuBg

# Controls Menu
@onready var ControlsMenu: CanvasLayer = $ControlsMenu
@onready var ControlsBackButton = $ControlsMenu/BackButton

# Options Menu
@onready var OptionsScene = $OptionsScene

# Commando Skill Tree
@onready var SkillTree = $CommandoSkillTree

func _ready():
	ResumeButton.grab_focus()
	
	# Connecting options menu and skill tree signal
	OptionsScene.OptionsClosed.connect(_on_options_closed)
	SkillTree.SkillTreeClosed.connect(_on_skill_tree_closed)
	
	OptionsScene.visible = false
	SkillTree.visible = false

func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed("InGameOptions"):
		_on_resume_button_pressed()

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
	SkillTree.visible = false
	
	ResumeButton.grab_focus()

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
	SkillTree.visible = false
	
	if get_tree().paused:
		# A timer to ensure the pause menu doesn't open up again immediately
		await get_tree().create_timer(0.2).timeout
		get_tree().paused = false
	
	PauseMenu.visible = false


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
	SkillTree.visible = false
	
	ControlsBackButton.grab_focus()


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
	SkillTree.visible = false
	
	ResumeButton.grab_focus()


func _on_menu_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	SmearCanvas.reset()

	GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax

	if get_tree().paused:
		get_tree().paused = false

	# Clear any runtime objects if the current scene has the method
	var level_root = get_tree().current_scene
	if level_root and level_root.has_method("clear_runtime_objects"):
		level_root.clear_runtime_objects()
		print("Cleared runtime objects.")

	# Free the current level scene
	if level_root:
		level_root.queue_free()

	# Load Main Menu scene
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")

func _on_skill_tree_button_pressed() -> void:
	GlobalAudioController.ClickSound()

	SkillTree.visible = true
	ResumeButton.visible = false
	ControlsButton.visible = false
	OptionsButton.visible = false
	SkillTreeButton.visible = false
	Title.visible = false
	MainButton.visible = false
	SkillTree.update_skill_trees_shown()
	SkillTree.restore_unlocked_skills(self)   
	
	SkillTree.SMGFocus.grab_focus()

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
	SkillTree.visible = false
	
	OptionsButton.grab_focus()

func _on_controls_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the controls menu and displaying pause menu
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true
	ControlsMenu.visible = false
	SkillTree.visible = false
	
	ControlsButton.grab_focus()

func _on_skill_tree_closed():
	# Play sound on button press
	GlobalAudioController.ClickSound()

	SkillTree.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true

	SkillTreeButton.grab_focus()
