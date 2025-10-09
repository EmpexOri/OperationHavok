extends CanvasLayer

var Options = true

signal SkillTreeClosed

@onready var WeaponTree = $WeaponSwapTitle
@onready var GrenadeTree = $GrenadeTitle
@onready var MinigunTree = $MinigunTitle

@onready var BackButton = $BackButton

# Focus for controller
@onready var SMGFocus = $WeaponSwapTitle/SMG
@onready var GrenadeFocus = $GrenadeTitle/Grenade
@onready var MinigunFocus = $MinigunTitle/Minigun

# Abilitiy Info boxes
@onready var WeaponSwapBox = $BoxBack/WeaponSwap
@onready var AkimboBox = $BoxBack/Akimbo
@onready var DragonShotgunBox = $BoxBack/DragonShotgun
@onready var M60Box = $BoxBack/M60
@onready var RaygunBox = $BoxBack/Raygun
@onready var FlamethrowerBox = $BoxBack/Flamethrower
@onready var GrenadeBox = $BoxBack/Grenade
@onready var BaseballBox = $BoxBack/BaseballGrenade
@onready var HomerunBox = $BoxBack/HomerunGrenade
@onready var PlasmaBox = $BoxBack/Plasmacaster
@onready var NovaBox = $BoxBack/Novacaster
@onready var RocketLauncherBox = $BoxBack/RocketLauncher
@onready var MinigunBox = $BoxBack/Minigun
@onready var RocketMinigunBox = $BoxBack/RocketMinigun
@onready var LightningGunBox = $BoxBack/LightningGun
@onready var TyphoonCannonBox = $BoxBack/TyphoonCannon

@onready var LockedBox = $BoxBack/Locked

func _ready():
	$BackButton.grab_focus()
	update_perk_points_label()
	update_skill_trees_shown()
	connect_skill_buttons(self)       
	
	# Restore the states of each skill tree   
	restore_unlocked_skills(WeaponTree)   
	restore_unlocked_skills(GrenadeTree)  
	restore_unlocked_skills(MinigunTree)  

func _process(_delta):
	# Making sure the perk points label stays updated
	update_perk_points_label()

func update_perk_points_label():
	# Updates the perk points counter
	$PerkPointsLabel.text = "Perk points: %d" % GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"]

func connect_skill_buttons(node):
	# This connects the skill buttons to the skill tree
	for child in node.get_children():
		if child is SkillButton:
			# Connect perk_point_used
			if not child.is_connected("perk_point_used", Callable(self, "_on_skill_button_used")):
				child.connect("perk_point_used", Callable(self, "_on_skill_button_used").bind(child))
			
			# Connect focus_entered
			if not child.is_connected("focus_entered", Callable(self, "_on_focus_entered")):
				child.connect("focus_entered", Callable(self, "_on_focus_entered").bind(child))
			
			# Connect mouse_entered
			if not child.is_connected("mouse_entered", Callable(self, "_on_mouse_entered")):
				child.connect("mouse_entered", Callable(self, "_on_mouse_entered").bind(child))
		connect_skill_buttons(child)


func _on_skill_button_used(button: SkillButton):
	var class_data = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]
	var unlocked = class_data["UnlockedAbilities"]
	
	if unlocked.has(button.name):
		return
		
	print("Skill bought:", button.name)
	update_perk_points_label()
	
	unlocked.append(button.name)
	GlobalAudioController.ClickSound()
	
	# Increment spent perk points
	GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerPointsSpent"] += 1
	update_skill_trees_shown()

	# Changes the ability being used
	match button.name:
		"SMG":
			GlobalPlayer.upgrade_weapon("SMG", 1)
			GlobalPlayer.upgrade_weapon("Shotgun", 2)
		"Akimbo":
			GlobalPlayer.upgrade_weapon("AkimboSmg", 1)
		"M60":
			GlobalPlayer.upgrade_weapon("M60", 1)
		"DragonsBreath":
			GlobalPlayer.upgrade_weapon("DragonShotgun", 2)
		"Flamethrower":
			GlobalPlayer.upgrade_weapon("FlameThrower", 2)
		"RaygunRifle":
			GlobalPlayer.upgrade_weapon("Raygun", 2)
		"LightningLauncher":
			upgrade_minigun_ability("LightningLauncher")
		"Minigun1":
			upgrade_minigun_ability("Minigun")
		"RocketMinigun":
			upgrade_minigun_ability("RocketMinigun")
		"TyphoonCannon":
			upgrade_minigun_ability("TyphoonCannon")
		"BaseballGrenade":
			upgrade_grenade_ability("BaseballGrenade")
		"HomeRunGrenade":
			upgrade_grenade_ability("HomerunGrenade")
		"Novacaster":
			upgrade_grenade_ability("NovacasterGrenade")
		"PlasmaCaster":
			upgrade_grenade_ability("PlasmaCaster")

func restore_unlocked_skills(node):
	# Restores the unlocked state of skills from saved data
	for child in node.get_children():
		if child is SkillButton:
			var skill_name = child.name
			var is_unlocked = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["UnlockedAbilities"].has(skill_name)
			child.set_unlocked_state(is_unlocked)
		restore_unlocked_skills(child)

func _on_back_button_pressed() -> void:
	if Options == false:
		GlobalAudioController.ClickSound()
		get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
	else:
		GlobalAudioController.ClickSound()
		SkillTreeClosed.emit() 

func upgrade_minigun_ability(NewAbility):
	# Find the current abilities, get the minigun index and then swap in the new skill
	var Abilities = GlobalPlayer.ClassData["Commando"]["Abilities"]
	Abilities[2] = NewAbility
	print("Skills updated to ", Abilities)

func upgrade_grenade_ability(NewAbility):
	# Find the current abilities, get the grenade index and then swap in the new skill
	var Abilities = GlobalPlayer.ClassData["Commando"]["Abilities"]
	Abilities[1] = NewAbility
	print("Skills updated to ", Abilities)

func update_skill_trees_shown():
	# Fetch how many perk points the player has spent
	var points_spent = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerPointsSpent"]
	
	# Display the respective skill tree/s based on points spent
	if points_spent <= 0:
		WeaponTree.visible = true
		GrenadeTree.visible = false
		MinigunTree.visible = false
		SMGFocus.grab_focus()
	elif points_spent == 1:
		WeaponTree.visible = false
		GrenadeTree.visible = true
		MinigunTree.visible = false
		GrenadeFocus.grab_focus()
	elif points_spent == 2:
		WeaponTree.visible = false
		GrenadeTree.visible = false
		MinigunTree.visible = true
		MinigunFocus.grab_focus()
	else:
		WeaponTree.visible = true
		GrenadeTree.visible = true
		MinigunTree.visible = true
		SMGFocus.grab_focus()


func _on_focus_entered(button: SkillButton) -> void:
	var class_data = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]
	var unlocked = class_data["UnlockedAbilities"]
	var parent_skill = button.get_parent()
	
	WeaponSwapBox.visible = false
	AkimboBox.visible = false
	DragonShotgunBox.visible = false
	M60Box.visible = false
	RaygunBox.visible = false
	FlamethrowerBox.visible = false
	GrenadeBox.visible = false
	BaseballBox.visible = false
	HomerunBox.visible = false
	PlasmaBox.visible = false
	NovaBox.visible = false
	RocketLauncherBox.visible = false
	MinigunBox.visible = false
	RocketMinigunBox.visible = false
	LightningGunBox.visible = false
	TyphoonCannonBox.visible = false
	LockedBox.visible = false
	
	if unlocked.has(button.name) or parent_skill is SkillButton and parent_skill.unlocked:
		match button.name:
			"SMG":
				WeaponSwapBox.visible = true
			"Akimbo":
				AkimboBox.visible = true
			"DragonsBreath":
				DragonShotgunBox.visible = true
			"M60":
				M60Box.visible = true
			"RaygunRifle":
				RaygunBox.visible = true
			"Flamethrower":
				FlamethrowerBox.visible = true
			"Grenade":
				GrenadeBox.visible = true
			"BaseballGrenade":
				BaseballBox.visible = true
			"HomeRunGrenade":
				HomerunBox.visible = true
			"PlasmaCaster":
				NovaBox.visible = true
			"Novacaster":
				PlasmaBox.visible = true
			"Minigun":
				RocketLauncherBox.visible = true
			"Minigun1":
				MinigunBox.visible = true
			"RocketMinigun":
				RocketMinigunBox.visible = true
			"LightningLauncher":
				LightningGunBox.visible = true
			"TyphoonCannon":
				TyphoonCannonBox.visible = true
				
	else:
		LockedBox.visible = true


func _on_mouse_entered(button: SkillButton) -> void:
	_on_focus_entered(button)
	
