extends Node
class_name PauseNode 
# All menus
var AllowFocusSound = false
var FocusDelay := 0.05

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

signal SkillTreeClosed  

func _ready():
	# Temporarily disable sound during initial setup
	AllowFocusSound = false
	
	await safe_grab_focus(ResumeButton)
	
	# Connect button focus_entered signals
	for button in [ResumeButton, ControlsButton, OptionsButton, SkillTreeButton, MainButton, ControlsBackButton]:
		button.focus_entered.connect(_on_button_focus_entered)
	
	# Connect signals
	OptionsScene.OptionsClosed.connect(_on_options_closed)
	SkillTree.SkillTreeClosed.connect(_on_skill_tree_closed)
	
	OptionsScene.visible = false
	SkillTree.visible = false
	
	# Re-enable sound after a small delay
	await get_tree().create_timer(0.1).timeout
	AllowFocusSound = true

func _input(event:InputEvent) -> void:
	if Input.is_action_just_pressed("MenuExit"):
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
	
	await safe_grab_focus(ResumeButton)

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
	OptionsScene.visible = false
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
	
	await safe_grab_focus(ControlsBackButton)

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
	GlobalAudioController.ButtonBackSound()
	
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
	
	await safe_grab_focus(ResumeButton)

func _on_menu_button_pressed() -> void:
	GlobalAudioController.ButtonBackSound()
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
	GlobalPlayer.set_current_level_scene("res://Scenes/MenuScene.tscn")
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
	GlobalPlayer.allow_restart()

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
	
	# Proper focus based on points spent
	SkillTree.set_skill_tree_focus()

func _on_options_closed():
	# Play sound on button press
	GlobalAudioController.ButtonBackSound()
	
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
	
	await safe_grab_focus(OptionsButton)

func _on_controls_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ButtonBackSound()
	
	# Removing the controls menu and displaying pause menu
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true
	ControlsMenu.visible = false
	SkillTree.visible = false
	
	await safe_grab_focus(ControlsButton)

func _on_skill_tree_closed():
	GlobalAudioController.ButtonBackSound()

	SkillTree.visible = false
	ResumeButton.visible = true
	ControlsButton.visible = true
	OptionsButton.visible = true
	SkillTreeButton.visible = true
	Title.visible = true
	MainButton.visible = true

	await safe_grab_focus(SkillTreeButton)

	# THIS EMITS THE SIGNAL 
	emit_signal("SkillTreeClosed")

func _on_button_focus_entered() -> void:
	if AllowFocusSound:
		GlobalAudioController.ButtonCycleSound()

func safe_grab_focus(button: Control) -> void:
	# Temporarily disable focus sound before grabbing focus manually
	AllowFocusSound = false
	button.grab_focus()
	await get_tree().create_timer(FocusDelay).timeout
	AllowFocusSound = true
