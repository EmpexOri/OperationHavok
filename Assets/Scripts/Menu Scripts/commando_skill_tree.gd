extends CanvasLayer

var Options = true

@onready var WeaponTree = $WeaponSwapTitle
@onready var GrenadeTree = $GrenadeTitle
@onready var MinigunTree = $MinigunTitle

@onready var BackButton = $BackButton

func _ready():
	$BackButton.grab_focus()
	update_perk_points_label()
	update_skill_trees_shown()
	connect_skill_buttons(self)       
	restore_unlocked_skills(self)      

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
			if not child.is_connected("perk_point_used", Callable(self, "_on_skill_button_used")):
				child.connect("perk_point_used", Callable(self, "_on_skill_button_used").bind(child))
		connect_skill_buttons(child)

func _on_skill_button_used(button: SkillButton):
	# Tells us when a skill has been bought and what the name is and updates the label
	var class_data = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]
	var unlocked = class_data["UnlockedAbilities"]

	# Prevent spending points on skills already unlocked
	if unlocked.has(button.name):
		return

	print("Skill bought:", button.name)
	update_perk_points_label()

	unlocked.append(button.name)

	# Changes the ability being used
	match button.name:
		"Akimbo":
			GlobalPlayer.upgrade_weapon("AkimboSmg", 1)
		"M60":
			GlobalPlayer.upgrade_weapon("M60", 1)
		"DragonsBreath":
			GlobalPlayer.upgrade_weapon("DragonShotgun", 2)
		"SniperRifle":
			GlobalPlayer.upgrade_weapon("Sniper", 2)
		"LightningLauncher":
			upgrade_minigun_ability("LightningLauncher")
		"RocketLauncher":
			upgrade_minigun_ability("RocketLauncher")
		"RocketMinigun":
			upgrade_minigun_ability("RocketMinigun")

func restore_unlocked_skills(node):
	# Restores the unlocked state of skills from saved data
	for child in node.get_children():
		if child is SkillButton:
			var skill_name = child.name
			var is_unlocked = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["UnlockedAbilities"].has(skill_name)
			child.set_unlocked_state(is_unlocked)
		restore_unlocked_skills(child)

func _check_back_button() -> void:
	if Options == true:
		BackButton.visible = false
	else:
		BackButton.visible = true

func _on_back_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")

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
	# Fetching the player current level
	var Level = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["Level"]
	
	# Displaying the respective skill tree/s
	if Level == 1:
		WeaponTree.visible = true
		GrenadeTree.visible = false
		MinigunTree.visible = false
	elif Level == 2:
		WeaponTree.visible = false
		GrenadeTree.visible = true
		MinigunTree.visible = false
	elif Level == 3:
		WeaponTree.visible = false
		GrenadeTree.visible = false
		MinigunTree.visible = true
	else:
		WeaponTree.visible = true
		GrenadeTree.visible = true
		MinigunTree.visible = true
